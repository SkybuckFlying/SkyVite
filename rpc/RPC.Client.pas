unit Rpc.Client;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Net.URL,
  System.Json,
  System.Rtti,
  System.Net.HttpClient,
  Rpc.Connection,
  Rpc.Http,
  Rpc.Websocket,
  Rpc.Ipc;

type
  ERpcClient = class(Exception);

  TBatchElem = class
  public
    Method: string;
    Args: TArray<TValue>;
    Result: TValue;
    Error: Exception;
  end;

  TJsonRpcMessage = class
  public
    Version: string;
    ID: TJSONRaw;
    Method: string;
    Params: TJSONRaw;
    Error: TJsonError;
    Result: TJSONRaw;
    function IsNotification: Boolean;
    function IsResponse: Boolean;
    function HasValidID: Boolean;
    function ToString: string;
  end;

  TClientSubscription = class;

  TRequestOp = class
  public
    Ids: TArray<TJSONRaw>;
    Err: Exception;
    Resp: TChannel<TJsonRpcMessage>;
    Sub: TClientSubscription;
    function Wait(const ParaTimeout: Cardinal): TJsonRpcMessage;
  end;

  TJsonRpcClient = class
  private
    mIdCounter: Cardinal;
    mConnectFunc: TFunc<IConnection>;
    mIsHTTP: Boolean;
    mWriteConn: IConnection;
    mClose: TEvent;
    mDidQuit: TEvent;
    mReconnected: TChannel<IConnection>;
    mReadErr: TChannel<Exception>;
    mReadResp: TChannel<TArray<TJsonRpcMessage>>;
    mRequestOp: TChannel<TRequestOp>;
    mSendDone: TChannel<Exception>;
    mRespWait: TDictionary<string, TRequestOp>;
    mSubs: TDictionary<string, TClientSubscription>;
    procedure Dispatch(const ParaConn: IConnection);
    procedure CloseRequestOps(const ParaErr: Exception);
    procedure HandleNotification(const ParaMsg: TJsonRpcMessage);
    procedure HandleResponse(const ParaMsg: TJsonRpcMessage);
    procedure Read(const ParaConn: IConnection);
    function NextID: TJSONRaw;
    function NewMessage(const ParaMethod: string; const ParaParamsIn: array of TValue): TJsonRpcMessage;
    procedure Send(const ParaOp: TRequestOp; const ParaMsg: TObject);
    procedure Reconnect;
  public
    constructor Create(const ParaConnectFunc: TFunc<IConnection>);
    destructor Destroy; override;
    class function Dial(const ParaRawUrl: string): TJsonRpcClient;
    procedure Close;
    procedure Call(out ParaResult: TValue; const ParaMethod: string; const ParaArgs: array of TValue);
    procedure BatchCall(const ParaB: TArray<TBatchElem>);
    function Subscribe(const ParaNamespace: string; const ParaChannel: TValue; const ParaArgs: array of TValue): TClientSubscription;
  end;

  TClientSubscription = class
  private
    mClient: TJsonRpcClient;
    mEtype: TRttiType;
    mChannel: TValue;
    mNamespace: string;
    mSubId: string;
    mIn: TChannel<TJSONRaw>;
    mQuit: TEvent;
    mErr: TChannel<Exception>;
    procedure QuitWithError(const ParaErr: Exception; const ParaUnsubscribeServer: Boolean);
    procedure Deliver(const ParaResult: TJSONRaw);
    procedure Start;
    function Forward: Exception;
    function Unmarshal(const ParaResult: TJSONRaw): TValue;
    procedure RequestUnsubscribe;
  public
    constructor Create(const ParaClient: TJsonRpcClient; const ParaNamespace: string; const ParaChannel: TValue);
    destructor Destroy; override;
    function Err: TChannel<Exception>;
    procedure Unsubscribe;
  end;

implementation

uses
  System.Threading,
  System.IOUtils;

{ TJsonRpcMessage }

function TJsonRpcMessage.IsNotification: Boolean;
begin
  Result := (ID = nil) and (Method <> '');
end;

function TJsonRpcMessage.IsResponse: Boolean;
begin
  Result := HasValidID and (Method = '') and (Length(Params) = 0);
end;

function TJsonRpcMessage.HasValidID: Boolean;
begin
  Result := (Length(ID) > 0) and (ID[0] <> '{') and (ID[0] <> '[');
end;

function TJsonRpcMessage.ToString: string;
begin
  Result := TJson.ObjectToJsonString(Self);
end;

{ TRequestOp }

function TRequestOp.Wait(const ParaTimeout: Cardinal): TJsonRpcMessage;
begin
  if not Resp.TryReceive(Result, ParaTimeout) then
  begin
    Err := TObject(ERpcClient.Create('request timed out')).Free;
  end;
end;

{ TJsonRpcClient }

constructor TJsonRpcClient.Create(const ParaConnectFunc: TFunc<IConnection>);
begin
  mConnectFunc := ParaConnectFunc;
  mWriteConn := mConnectFunc();
  mIsHTTP := mWriteConn is THttpConn;
  mClose := TEvent.Create(nil, True, False, '');
  mDidQuit := TEvent.Create(nil, True, False, '');
  mReconnected := TChannel<IConnection>.Create;
  mReadErr := TChannel<Exception>.Create;
  mReadResp := TChannel<TArray<TJsonRpcMessage>>.Create;
  mRequestOp := TChannel<TRequestOp>.Create;
  mSendDone := TChannel<Exception>.Create(1);
  mRespWait := TDictionary<string, TRequestOp>.Create;
  mSubs := TDictionary<string, TClientSubscription>.Create;
  if not mIsHTTP then
  begin
    TTask.Run(
      procedure
      begin
        Dispatch(mWriteConn);
      end);
  end;
end;

destructor TJsonRpcClient.Destroy;
begin
  Close;
  mClose.Free;
  mDidQuit.Free;
  mReconnected.Free;
  mReadErr.Free;
  mReadResp.Free;
  mRequestOp.Free;
  mSendDone.Free;
  mRespWait.Free;
  mSubs.Free;
  inherited;
end;

class function TJsonRpcClient.Dial(const ParaRawUrl: string): TJsonRpcClient;
var
  vURI: TURI;
begin
  vURI := TURI.Create(ParaRawUrl);
  case vURI.Scheme.ToLower of
    'http', 'https':
      Result := DialHttp(ParaRawUrl);
    'ws', 'wss':
      Result := DialWebsocket(ParaRawUrl, '');
  else
    if (vURI.Scheme = '') and TFile.Exists(ParaRawUrl) then
    begin
      Result := DialIpc(ParaRawUrl);
    end
    else
    begin
      raise ERpcClient.CreateFmt('no known transport for URL scheme %s', [vURI.Scheme]);
    end;
  end;
end;

procedure TJsonRpcClient.Close;
begin
  if mIsHTTP then
  begin
    Exit;
  end;
  mClose.SetEvent;
  mDidQuit.WaitFor(INFINITE);
end;

procedure TJsonRpcClient.Call(out ParaResult: TValue; const ParaMethod: string; const ParaArgs: array of TValue);
var
  vMsg: TJsonRpcMessage;
  vOp: TRequestOp;
  vResp: TJsonRpcMessage;
begin
  vMsg := NewMessage(ParaMethod, ParaArgs);
  vOp := TRequestOp.Create;
  try
    vOp.Ids := [vMsg.ID];
    vOp.Resp := TChannel<TJsonRpcMessage>.Create(1);
    if mIsHTTP then
    begin
      (mWriteConn as THttpConn).Send(vOp, vMsg);
    end
    else
    begin
      Send(vOp, vMsg);
    end;
    vResp := vOp.Wait(10000);
    if vResp.Error <> nil then
    begin
      raise Exception.Create(vResp.Error.Message);
    end;
    if Length(vResp.Result) = 0 then
    begin
      raise ERpcClient.Create('no result in JSON-RPC response');
    end;
    TJson.JsonToRtti(vResp.Result, ParaResult);
  finally
    vOp.Free;
  end;
end;

procedure TJsonRpcClient.BatchCall(const ParaB: TArray<TBatchElem>);
var
  vMsgs: TArray<TJsonRpcMessage>;
  vOp: TRequestOp;
  vIndex: Integer;
  vElem: TBatchElem;
  vMsg: TJsonRpcMessage;
  vResp: TJsonRpcMessage;
  vN: Integer;
begin
  SetLength(vMsgs, Length(ParaB));
  vOp := TRequestOp.Create;
  try
    vOp.Ids := TArray<TJSONRaw>.Create;
    vOp.Resp := TChannel<TJsonRpcMessage>.Create(Length(ParaB));
    for vIndex := 0 to High(ParaB) do
    begin
      vElem := ParaB[vIndex];
      vMsg := NewMessage(vElem.Method, vElem.Args);
      vMsgs[vIndex] := vMsg;
      vOp.Ids := vOp.Ids + [vMsg.ID];
    end;
    if mIsHTTP then
    begin
      (mWriteConn as THttpConn).SendBatch(vOp, vMsgs);
    end
    else
    begin
      for vMsg in vMsgs do
      begin
        Send(vOp, vMsg);
      end;
    end;
    for vN := 0 to High(ParaB) do
    begin
      vResp := vOp.Wait(10000);
      for vIndex := 0 to High(vMsgs) do
      begin
        if TBytes.Equal(vMsgs[vIndex].ID, vResp.ID) then
        begin
          vElem := ParaB[vIndex];
          Break;
        end;
      end;
      if vResp.Error <> nil then
      begin
        vElem.Error := Exception.Create(vResp.Error.Message);
      end
      else if Length(vResp.Result) = 0 then
      begin
        vElem.Error := ERpcClient.Create('no result in JSON-RPC response');
      end
      else
      begin
        TJson.JsonToRtti(vResp.Result, vElem.Result);
      end;
    end;
  finally
    vOp.Free;
  end;
end;

function TJsonRpcClient.Subscribe(const ParaNamespace: string; const ParaChannel: TValue; const ParaArgs: array of TValue): TClientSubscription;
var
  vMsg: TJsonRpcMessage;
  vOp: TRequestOp;
begin
  if mIsHTTP then
  begin
    raise ERpcClient.Create('notifications not supported');
  end;
  vMsg := NewMessage(ParaNamespace + '_subscription', ParaArgs);
  vOp := TRequestOp.Create;
  try
    vOp.Ids := [vMsg.ID];
    vOp.Resp := TChannel<TJsonRpcMessage>.Create;
    vOp.Sub := TClientSubscription.Create(Self, ParaNamespace, ParaChannel);
    Send(vOp, vMsg);
    vOp.Wait(5000);
    Result := vOp.Sub;
  finally
    vOp.Free;
  end;
end;

procedure TJsonRpcClient.Dispatch(const ParaConn: IConnection);
var
  vLastOp: TRequestOp;
  vRequestOpLock: TChannel<TRequestOp>;
  vReading: Boolean;
  vBatch: TArray<TJsonRpcMessage>;
  vMsg: TJsonRpcMessage;
  vErr: Exception;
  vNewConn: IConnection;
  vOp: TRequestOp;
  vId: TJSONRaw;
begin
  TTask.Run(
    procedure
    begin
      Read(ParaConn);
    end);
  vReading := True;
  vRequestOpLock := mRequestOp;
  try
    while True do
    begin
      if mClose.WaitFor(0) then
      begin
        Break;
      end;
      if mReadResp.TryReceive(vBatch) then
      begin
        for vMsg in vBatch do
        begin
          if vMsg.IsNotification then
          begin
            HandleNotification(vMsg);
          end
          else if vMsg.IsResponse then
          begin
            HandleResponse(vMsg);
          end;
        end;
      end;
      if mReadErr.TryReceive(vErr) then
      begin
        CloseRequestOps(vErr);
        ParaConn.Close;
        vReading := False;
      end;
      if mReconnected.TryReceive(vNewConn) then
      begin
        if vReading then
        begin
          ParaConn.Close;
          mReadErr.Receive(vErr);
        end;
        TTask.Run(
          procedure
          begin
            Read(vNewConn);
          end);
        vReading := True;
        ParaConn := vNewConn;
      end;
      if vRequestOpLock.TryReceive(vOp) then
      begin
        vRequestOpLock := nil;
        vLastOp := vOp;
        for vId in vOp.Ids do
        begin
          mRespWait.Add(string(vId), vOp);
        end;
      end;
      if mSendDone.TryReceive(vErr) then
      begin
        if vErr <> nil then
        begin
          for vId in vLastOp.Ids do
          begin
            mRespWait.Remove(string(vId));
          end;
        end;
        vRequestOpLock := mRequestOp;
        vLastOp := nil;
      end;
    end;
  finally
    CloseRequestOps(ERpcClient.Create('client is closed'));
    ParaConn.Close;
    if vReading then
    begin
      while mReadErr.TryReceive(vErr) or mReadResp.TryReceive(vBatch) do
      begin
      end;
    end;
    mDidQuit.SetEvent;
  end;
end;

procedure TJsonRpcClient.CloseRequestOps(const ParaErr: Exception);
var
  vDidClose: TDictionary<TRequestOp, Boolean>;
  vId: string;
  vOp: TRequestOp;
  vSub: TClientSubscription;
begin
  vDidClose := TDictionary<TRequestOp, Boolean>.Create;
  try
    for vId in mRespWait.Keys do
    begin
      vOp := mRespWait[vId];
      mRespWait.Remove(vId);
      if not vDidClose.ContainsKey(vOp) then
      begin
        vOp.Err := ParaErr;
        vOp.Resp.Close;
        vDidClose.Add(vOp, True);
      end;
    end;
    for vId in mSubs.Keys do
    begin
      vSub := mSubs[vId];
      mSubs.Remove(vId);
      vSub.QuitWithError(ParaErr, False);
    end;
  finally
    vDidClose.Free;
  end;
end;

procedure TJsonRpcClient.HandleNotification(const ParaMsg: TJsonRpcMessage);
var
  vSubResult: record
    ID: string;
    Result: TJSONRaw;
  end;
begin
  if not ParaMsg.Method.EndsWith('_subscription') then
  begin
    Exit;
  end;
  TJson.JsonToRecord(ParaMsg.Params, vSubResult);
  if mSubs.ContainsKey(vSubResult.ID) then
  begin
    mSubs[vSubResult.ID].Deliver(vSubResult.Result);
  end;
end;

procedure TJsonRpcClient.HandleResponse(const ParaMsg: TJsonRpcMessage);
var
  vOp: TRequestOp;
begin
  if not mRespWait.TryGetValue(string(ParaMsg.ID), vOp) then
  begin
    Exit;
  end;
  mRespWait.Remove(string(ParaMsg.ID));
  if vOp.Sub = nil then
  begin
    vOp.Resp.Send(ParaMsg);
    Exit;
  end;
  try
    if ParaMsg.Error <> nil then
    begin
      vOp.Err := Exception.Create(ParaMsg.Error.Message);
      Exit;
    end;
    TJson.JsonToRtti(ParaMsg.Result, vOp.Sub.mSubId);
    TTask.Run(
      procedure
      begin
        vOp.Sub.Start;
      end);
    mSubs.Add(vOp.Sub.mSubId, vOp.Sub);
  finally
    vOp.Resp.Close;
  end;
end;

procedure TJsonRpcClient.Read(const ParaConn: IConnection);
var
  vBuf: TBytes;
  vDec: TJsonTextReader;
  vJsonValue: TJsonValue;
  vMsgs: TArray<TJsonRpcMessage>;
begin
  vDec := TJsonTextReader.Create(TStreamReader.Create(ParaConn.GetStream));
  try
    while vDec.Read do
    begin
      vJsonValue := vDec.Value;
      if vJsonValue is TJsonArray then
      begin
        vMsgs := TJson.JsonToObject<TArray<TJsonRpcMessage>>(vJsonValue);
      end
      else
      begin
        SetLength(vMsgs, 1);
        vMsgs[0] := TJson.JsonToObject<TJsonRpcMessage>(vJsonValue);
      end;
      mReadResp.Send(vMsgs);
    end;
  except
    on E: Exception do
    begin
      mReadErr.Send(E);
    end;
  end;
end;

function TJsonRpcClient.NextID: TJSONRaw;
begin
  Result := TEncoding.UTF8.GetBytes(TInterlocked.Increment(mIdCounter).ToString);
end;

function TJsonRpcClient.NewMessage(const ParaMethod: string; const ParaParamsIn: array of TValue): TJsonRpcMessage;
var
  vParams: TBytes;
begin
  vParams := TJson.ObjectToJsonBytes(ParaParamsIn);
  Result := TJsonRpcMessage.Create;
  Result.Version := '2.0';
  Result.ID := NextID;
  Result.Method := ParaMethod;
  Result.Params := vParams;
end;

procedure TJsonRpcClient.Send(const ParaOp: TRequestOp; const ParaMsg: TObject);
begin
  if not mRequestOp.TrySend(ParaOp) then
  begin
    ParaOp.Err := ERpcClient.Create('client is closed');
    ParaOp.Resp.Close;
    Exit;
  end;
  try
    mWriteConn.Write(TJson.ObjectToJsonBytes(ParaMsg));
    mSendDone.Send(nil);
  except
    on E: Exception do
    begin
      mSendDone.Send(E);
    end;
  end;
end;

procedure TJsonRpcClient.Reconnect;
var
  vNewConn: IConnection;
begin
  vNewConn := mConnectFunc();
  if not mReconnected.TrySend(vNewConn) then
  begin
    vNewConn.Close;
  end;
end;

{ TClientSubscription }

constructor TClientSubscription.Create(const ParaClient: TJsonRpcClient; const ParaNamespace: string; const ParaChannel: TValue);
begin
  mClient := ParaClient;
  mNamespace := ParaNamespace;
  mEtype := ParaChannel.TypeInfo.GetRttiType.GetProcParam(0).ParamType.Handle;
  mChannel := ParaChannel;
  mQuit := TEvent.Create(nil, True, False, '');
  mErr := TChannel<Exception>.Create(1);
  mIn := TChannel<TJSONRaw>.Create;
end;

destructor TClientSubscription.Destroy;
begin
  Unsubscribe;
  mQuit.Free;
  mErr.Free;
  mIn.Free;
  inherited;
end;

function TClientSubscription.Err: TChannel<Exception>;
begin
  Result := mErr;
end;

procedure TClientSubscription.Unsubscribe;
begin
  QuitWithError(nil, True);
  mErr.Close;
end;

procedure TClientSubscription.QuitWithError(const ParaErr: Exception; const ParaUnsubscribeServer: Boolean);
begin
  if mQuit.WaitFor(0) then
  begin
    Exit;
  end;
  mQuit.SetEvent;
  if ParaUnsubscribeServer then
  begin
    RequestUnsubscribe;
  end;
  if ParaErr <> nil then
  begin
    mErr.Send(ParaErr);
  end;
end;

procedure TClientSubscription.Deliver(const ParaResult: TJSONRaw);
begin
  if not mIn.TrySend(ParaResult) then
  begin
    QuitWithError(ERpcClient.Create('subscription queue overflow'), True);
  end;
end;

procedure TClientSubscription.Start;
var
  vErr: Exception;
begin
  vErr := Forward;
  QuitWithError(vErr, True);
end;

function TClientSubscription.Forward: Exception;
var
  vCases: TArray<TSelectCase>;
  vBuffer: TQueue<TValue>;
  vChosen: Integer;
  vRecv: TValue;
  vVal: TValue;
begin
  vBuffer := TQueue<TValue>.Create;
  try
    SetLength(vCases, 3);
    vCases[0] := TSelectCase.Create(mQuit, seReceive);
    vCases[1] := TSelectCase.Create(mIn, seReceive);
    vCases[2] := TSelectCase.Create(mChannel, seSend);
    while True do
    begin
      if vBuffer.Count = 0 then
      begin
        vChosen := TSelect.Select(vCases, 2);
      end
      else
      begin
        vCases[2].SendValue := vBuffer.Peek;
        vChosen := TSelect.Select(vCases, 3);
      end;
      case vChosen of
        0: // <-mQuit
          Exit(nil);
        1: // <-mIn
          begin
            mIn.Receive(TValue.From<TJSONRaw>(vRecv));
            vVal := Unmarshal(vRecv.AsType<TJSONRaw>);
            if vBuffer.Count = 20000 then
            begin
              Exit(ERpcClient.Create('subscription queue overflow'));
            end;
            vBuffer.Enqueue(vVal);
          end;
        2: // mChannel<-
          begin
            vBuffer.Dequeue;
          end;
      end;
    end;
  finally
    vBuffer.Free;
  end;
end;

function TClientSubscription.Unmarshal(const ParaResult: TJSONRaw): TValue;
var
  vVal: TValue;
begin
  TJson.JsonToRtti(ParaResult, vVal, mEtype);
  Result := vVal;
end;

procedure TClientSubscription.RequestUnsubscribe;
var
  vResult: TValue;
begin
  mClient.Call(vResult, mNamespace + '_unsubscribe', [mSubId]);
end;

end.
