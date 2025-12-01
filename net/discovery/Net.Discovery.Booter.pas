unit net.discovery.booter;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  Log15, net.vnode, net.discovery.discovery;

type
  IBooter = interface
    ['{YOUR_GUID_HERE}']
    function GetBootNodes(Count: Integer): TArray<TNode>;
  end;

  IBooterDB = interface
    ['{YOUR_GUID_HERE}']
    function ReadNodes(Expiration: Int64): TArray<TNode>;
  end;

  TDBBooter = class(TInterfacedObject, IBooter)
  private
    FDB: IBooterDB;
  public
    constructor Create(DB: IBooterDB);
    function GetBootNodes(Count: Integer): TArray<TNode>;
  end;

  TCfgBooter = class(TInterfacedObject, IBooter)
  private
    FBootNodes: TArray<TNode>;
    FNode: TVNode;
  public
    constructor Create(BootNodes: TArray<string>; Node: TVNode);
    function GetBootNodes(Count: Integer): TArray<TNode>;
  end;

  TRequest = class
  public
    Node: TVNode;
    Count: Integer;
    constructor Create(ANode: TVNode; ACount: Integer);
    destructor Destroy; override;
    function ToJSON: string;
  end;

  TResult = class
  public
    Code: Integer;
    Message: string;
    Data: TArray<string>;
    constructor Create;
    destructor Destroy; override;
    procedure FromJSON(const AJSON: string);
  end;

  TNetBooter = class(TInterfacedObject, IBooter)
  private
    FSelf: TVNode;
    FSeeds: TArray<string>;
    FLog: ILogger;
  public
    constructor Create(SelfNode: TVNode; Seeds: TArray<string>);
    function GetBootNodes(Count: Integer): TArray<TNode>;
  end;

function NewDBBooter(DB: IBooterDB): IBooter;
function NewCfgBooter(BootNodes: TArray<string>; Node: TVNode): IBooter;
function NewNetBooter(SelfNode: TVNode; Seeds: TArray<string>): IBooter;

implementation

uses
  System.Net.HttpClient, System.Net.HttpClient.Win.Utils, System.Random,
  Log15.Logger;

const
  SeedMaxAge = 24 * 3600 * 30; // Example value, adjust as needed

var
  ErrDifferentNet: Exception;

{ TDBBooter }

constructor TDBBooter.Create(DB: IBooterDB);
begin
  FDB := DB;
end;

function TDBBooter.GetBootNodes(Count: Integer): TArray<TNode>;
var
  Nodes: TArray<TNode>;
begin
  Nodes := FDB.ReadNodes(SeedMaxAge);
  DiscvLog.Info(Format('load %d nodes from db', [Length(Nodes)]));
  Result := Nodes;
end;

{ TCfgBooter }

constructor TCfgBooter.Create(BootNodes: TArray<string>; Node: TVNode);
var
  I: Integer;
  URL: string;
  N: TVNode;
begin
  FNode := Node;
  SetLength(FBootNodes, Length(BootNodes));

  for I := 0 to High(BootNodes) do
  begin
    URL := BootNodes[I];
    N := TVNode.ParseNode(URL);

    if N = nil then
      raise Exception.Create(Format('failed to parse bootNode: %s', [URL]));

    if (N.Net <> 0) and (N.Net <> Node.Net) then
      raise ErrDifferentNet;

    N.Net := Node.Net;

    FBootNodes[I] := TNode.Create(N);
  end;
end;

function TCfgBooter.GetBootNodes(Count: Integer): TArray<TNode>;
begin
  Result := FBootNodes;
end;

{ TRequest }

constructor TRequest.Create(ANode: TVNode; ACount: Integer);
begin
  Node := ANode;
  Count := ACount;
end;

destructor TRequest.Destroy;
begin
  Node.Free;
  inherited;
end;

function TRequest.ToJSON: string;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject.Create;
  try
    LJSONObject.AddPair('node', Node.ToJSONObject);
    LJSONObject.AddPair('count', TJSONNumber.Create(Count));
    Result := LJSONObject.ToString;
  finally
    LJSONObject.Free;
  end;
end;

{ TResult }

constructor TResult.Create;
begin
  SetLength(Data, 0);
end;

destructor TResult.Destroy;
begin
  inherited;
end;

procedure TResult.FromJSON(const AJSON: string);
var
  LJSONObject: TJSONObject;
  LJSONArray: TJSONArray;
  LJSONValue: TJSONValue;
  I: Integer;
begin
  LJSONObject := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
  try
    Code := LJSONObject.GetValue<Integer>('code');
    Message := LJSONObject.GetValue<string>('message');

    LJSONArray := LJSONObject.GetValue<TJSONArray>('data');
    if Assigned(LJSONArray) then
    begin
      SetLength(Data, LJSONArray.Count);
      for I := 0 to LJSONArray.Count - 1 do
      begin
        LJSONValue := LJSONArray.Items[I];
        if LJSONValue is TJSONString then
          Data[I] := TJSONString(LJSONValue).Value;
      end;
    end;
  finally
    LJSONObject.Free;
  end;
end;

{ TNetBooter }

constructor TNetBooter.Create(SelfNode: TVNode; Seeds: TArray<string>);
begin
  FSelf := SelfNode;
  FSeeds := Seeds;
  FLog := DiscvLog.New(['module', 'netBooter']);
end;

function TNetBooter.GetBootNodes(Count: Integer): TArray<TNode>;
var
  Seed: string;
  HTTPClient: THTTPClient;
  RequestContent: TStringStream;
  Response: IHTTPResponse;
  ResponseBytes: TBytes;
  ResultObj: TResult;
  NodeStr: string;
  N: TVNode;
  Err: Exception;
begin
  SetLength(Result, 0);
  if Length(FSeeds) = 0 then
    Exit;

  Seed := FSeeds[Random(Length(FSeeds))];

  HTTPClient := THTTPClient.Create;
  try
    RequestContent := TStringStream.Create(TRequest.Create(FSelf, Count).ToJSON, TEncoding.UTF8);
    try
      Response := HTTPClient.Post(Seed, RequestContent);
      ResponseBytes := Response.ContentAsBytes(False);

      ResultObj := TResult.Create;
      try
        ResultObj.FromJSON(TEncoding.UTF8.GetString(ResponseBytes));

        if ResultObj.Code <> 0 then
        begin
          FLog.Error(Format('failed to get bootNodes from seed %s: %d %s', [Seed, ResultObj.Code, ResultObj.Message]));
          Exit;
        end;

        for NodeStr in ResultObj.Data do
        begin
          N := TVNode.ParseNode(NodeStr);
          if N = nil then
          begin
            FLog.Error(Format('failed to parse bootNode %s from seed %s', [NodeStr, Seed]));
          end
          else
          begin
            N.Net := FSelf.Net;
            Result := Result + [TNode.Create(N)];
          end;
        end;
      finally
        ResultObj.Free;
      end;
    finally
      RequestContent.Free;
    end;
  finally
    HTTPClient.Free;
  end;
end;

function NewDBBooter(DB: IBooterDB): IBooter;
begin
  Result := TDBBooter.Create(DB);
end;

function NewCfgBooter(BootNodes: TArray<string>; Node: TVNode): IBooter;
begin
  Result := TCfgBooter.Create(BootNodes, Node);
end;

function NewNetBooter(SelfNode: TVNode; Seeds: TArray<string>): IBooter;
begin
  Result := TNetBooter.Create(SelfNode, Seeds);
end;

initialization
  ErrDifferentNet := Exception.Create('different net');
end.
