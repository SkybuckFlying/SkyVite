unit Net.Discovery.Pool;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  System.DateUtils,
  Net.VNode,
  Net.Discovery.Message,
  Net.Discovery.Node,
  GoToDelphi.Helpers.TList,
  GoToDelphi.Helpers.TChannel;

const
  ErrStopped = 'discovery server has stopped';
  ErrResponseTimeout = 'response timeout';

type
  IRequestHandler = interface
    ['{B5F8E1C2-E3D4-4A5B-8F9C-0A1B2C3D4E5F}']
    function Handle(ParaPkt: TPacket; ParaErr: Exception): Boolean;
  end;

  TRequest = class
  public
    ExpectFrom: string;
    ExpectID: TVNodeID;
    ExpectCode: TCode;
    Handler: IRequestHandler;
    Expiration: TDateTime;
    constructor Create;
    destructor Destroy; override;
  end;

  IRequestPool = interface
    ['{A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D}']
    procedure Start;
    procedure Stop;
    function Add(ParaReq: TRequest): Boolean;
    function Rec(ParaPkt: TPacket): Boolean;
    function Size: Integer;
  end;

  TRequestPool = class(TInterfacedObject, IRequestPool)
  private
    mPending: TDictionary<string, ITList>;
    mMu: TCriticalSection;
    mRunning: Integer;
    mTerm: TEvent;
    mWg: TThread;

    procedure Loop;
    procedure Clean(ParaNow: TDateTime);
    procedure Release;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Add(ParaReq: TRequest): Boolean;
    function Rec(ParaPkt: TPacket): Boolean;
    function Size: Integer;
  end;

  TPingRequest = class(TInterfacedObject, IRequestHandler)
  private
    mHash: TBytes;
    mDone: TProc<TNode, Exception>;
    procedure ReceivePong(ParaPkt: TPacket; ParaPng: TPongPacketBody);
  public
    constructor Create(ParaHash: TBytes; ParaDone: TProc<TNode, Exception>);
    function Handle(ParaPkt: TPacket; ParaErr: Exception): Boolean;
  end;

  TFindNodeRequest = class(TInterfacedObject, IRequestHandler)
  private
    mCount: Integer;
    mReceived: Integer;
    mCh: TChannel<TArray<TVNodeEndPoint>>;
    mClosed: Integer;
    procedure CloseChannel;
  public
    constructor Create(ParaCount: Integer; ParaCh: TChannel<TArray<TVNodeEndPoint>>);
    destructor Destroy; override;
    function Handle(ParaPkt: TPacket; ParaErr: Exception): Boolean;
  end;

function NewRequestPool: IRequestPool;

implementation

uses
  System.Math;

{ TRequest }

constructor TRequest.Create;
begin
  inherited;
  ExpectID := TVNodeID.Create;
end;

destructor TRequest.Destroy;
begin
  ExpectID.Free;
  inherited;
end;

{ TRequestPool }

constructor TRequestPool.Create;
begin
  inherited;
  mPending := TDictionary<string, ITList>.Create;
  mMu := TCriticalSection.Create;
  mTerm := TEvent.Create(nil, True, False, '');
end;

destructor TRequestPool.Destroy;
begin
  Stop;
  mPending.Free;
  mMu.Free;
  mTerm.Free;
  inherited;
end;

function TRequestPool.Size: Integer;
var
  vL: ITList;
begin
  Result := 0;
  mMu.Acquire;
  try
    for vL in mPending.Values do
      Result := Result + vL.Size;
  finally
    mMu.Release;
  end;
end;

procedure TRequestPool.Start;
begin
  if TInterlocked.CompareExchange(mRunning, 1, 0) = 0 then
  begin
    mTerm.ResetEvent;
    mPending.Clear;
    mWg := TThread.CreateAnonymousThread(Loop);
    mWg.Start;
  end;
end;

procedure TRequestPool.Stop;
begin
  if TInterlocked.CompareExchange(mRunning, 0, 1) = 1 then
  begin
    mTerm.SetEvent;
    mWg.WaitFor;
  end;
end;

function TRequestPool.Add(ParaReq: TRequest): Boolean;
var
  vL: ITList;
begin
  Result := False;
  if TInterlocked.Read(mRunning) = 0 then
    Exit;

  mMu.Acquire;
  try
    if not mPending.TryGetValue(ParaReq.ExpectFrom, vL) then
    begin
      vL := TList.Create;
      mPending.Add(ParaReq.ExpectFrom, vL);
    end;
    vL.Append(ParaReq);
    Result := True;
  finally
    mMu.Release;
  end;
end;

function TRequestPool.Rec(ParaPkt: TPacket): Boolean;
var
  vWant: Boolean;
  vL: ITList;
  vAddr: string;
begin
  vWant := False;

  mMu.Acquire;
  try
    vAddr := ParaPkt.from.ToString;
    if mPending.TryGetValue(vAddr, vL) then
    begin
      vL.Filter(function(Value: TObject): Boolean
      var
        vWt: TRequest;
      begin
        vWt := Value as TRequest;
        if vWt.ExpectCode = ParaPkt.c then
        begin
          vWant := True;
          Result := vWt.Handler.Handle(ParaPkt, nil);
        end
        else
          Result := False;
      end);
    end;
  finally
    mMu.Release;
  end;
  Result := vWant;
end;

procedure TRequestPool.Loop;
const
  Expiration = 30 * 1000; // 30 seconds
var
  vCheckTicker: TStopwatch;
begin
  vCheckTicker := TStopwatch.StartNew;
  while mTerm.WaitFor(Expiration div 2) = wrTimeout do
  begin
    Clean(Now);
  end;
  Release;
end;

procedure TRequestPool.Clean(ParaNow: TDateTime);
var
  vAddr: string;
  vL: ITList;
  vKeysToRemove: TArray<string>;
begin
  mMu.Acquire;
  try
    SetLength(vKeysToRemove, 0);
    for vAddr in mPending.Keys do
    begin
      vL := mPending[vAddr];
      vL.Filter(function(Value: TObject): Boolean
      var
        vWt: TRequest;
      begin
        vWt := Value as TRequest;
        if vWt.Expiration < ParaNow then
        begin
          vWt.Handler.Handle(nil, Exception.Create(ErrResponseTimeout));
          Result := True;
        end
        else
          Result := False;
      end);

      if vL.Size = 0 then
        vKeysToRemove := vKeysToRemove + [vAddr];
    end;

    for vAddr in vKeysToRemove do
      mPending.Remove(vAddr);

  finally
    mMu.Release;
  end;
end;

procedure TRequestPool.Release;
var
  vL: ITList;
begin
  mMu.Acquire;
  try
    for vL in mPending.Values do
    begin
      vL.Filter(function(Value: TObject): Boolean
      var
        vWt: TRequest;
      begin
        vWt := Value as TRequest;
        vWt.Handler.Handle(nil, Exception.Create(ErrStopped));
        Result := True;
      end);
    end;
    mPending.Clear;
  finally
    mMu.Release;
  end;
end;

{ TPingRequest }

constructor TPingRequest.Create(ParaHash: TBytes; ParaDone: TProc<TNode, Exception>);
begin
  inherited Create;
  mHash := ParaHash;
  mDone := ParaDone;
end;

function TPingRequest.Handle(ParaPkt: TPacket; ParaErr: Exception): Boolean;
var
  vPng: TPongPacketBody;
begin
  Result := False;
  if Assigned(ParaErr) then
  begin
    mDone(nil, ParaErr);
    Result := True;
    Exit;
  end;

  if ParaPkt.body is TPongPacketBody then
  begin
    vPng := ParaPkt.body as TPongPacketBody;
    if TBytes.Equals(vPng.echo, mHash) then
    begin
      TThread.CreateAnonymousThread(
        procedure
        begin
          ReceivePong(ParaPkt, vPng);
        end).Start;
      Result := True;
    end;
  end;
end;

procedure TPingRequest.ReceivePong(ParaPkt: TPacket; ParaPng: TPongPacketBody);
var
  vNode: TNode;
begin
  vNode := nodeFromPong(ParaPkt);
  mDone(vNode, nil);
end;

{ TFindNodeRequest }

constructor TFindNodeRequest.Create(ParaCount: Integer; ParaCh: TChannel<TArray<TVNodeEndPoint>>);
begin
  inherited Create;
  mCount := ParaCount;
  mCh := ParaCh;
  mClosed := 0;
end;

destructor TFindNodeRequest.Destroy;
begin
  CloseChannel;
  inherited;
end;

function TFindNodeRequest.Handle(ParaPkt: TPacket; ParaErr: Exception): Boolean;
var
  vN: TNeighborsPacketBody;
begin
  Result := False;
  if Assigned(ParaErr) then
  begin
    CloseChannel;
    Result := True;
    Exit;
  end;

  if ParaPkt.body is TNeighborsPacketBody then
  begin
    vN := ParaPkt.body as TNeighborsPacketBody;
    mReceived := mReceived + Length(vN.endpoints);
    mCh.Send(vN.endpoints);

    if (mReceived >= mCount) or vN.last then
    begin
      CloseChannel;
      Result := True;
    end;
  end;
end;

procedure TFindNodeRequest.CloseChannel;
begin
  if TInterlocked.CompareExchange(mClosed, 1, 0) = 0 then
  begin
    mCh.Close;
  end;
end;

function NewRequestPool: IRequestPool;
begin
  Result := TRequestPool.Create;
end;

end.
