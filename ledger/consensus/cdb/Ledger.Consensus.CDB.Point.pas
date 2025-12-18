unit Ledger.Consensus.CDB.Point;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  BigNumbers,
  Common.Types,
  Common.VitePB;

type
  IContent = interface
    ['{F4D8E6B1-C2B1-4E6E-B8A6-8F2B9D4E1C6A}']
    function GetExpectedNum: Cardinal;
    procedure SetExpectedNum(const Value: Cardinal);
    function GetFactualNum: Cardinal;
    procedure SetFactualNum(const Value: Cardinal);
    function Copy: IContent;
    procedure Merge(const AC: IContent);
    function Rate: Integer;
    procedure AddNum(AExpectedNum, AFactualNum: Cardinal);
    property ExpectedNum: Cardinal read GetExpectedNum write SetExpectedNum;
    property FactualNum: Cardinal read GetFactualNum write SetFactualNum;
  end;

  TContent = class(TInterfacedObject, IContent)
  private
    FExpectedNum: Cardinal;
    FFactualNum: Cardinal;
    function GetExpectedNum: Cardinal;
    procedure SetExpectedNum(const Value: Cardinal);
    function GetFactualNum: Cardinal;
    procedure SetFactualNum(const Value: Cardinal);
  public
    constructor Create(AExpectedNum, AFactualNum: Cardinal);
    function Copy: IContent;
    procedure Merge(const AC: IContent);
    function Rate: Integer;
    procedure AddNum(AExpectedNum, AFactualNum: Cardinal);
  end;

  IVoteContent = interface
    ['{E3A2E8B9-A2C3-4B8D-9B1A-2A8E5C1B4A5D}']
    function GetDetails: TDictionary<string, TBigInteger>;
    function GetTotal: TBigInteger;
    property Details: TDictionary<string, TBigInteger> read GetDetails;
    property Total: TBigInteger read GetTotal;
  end;

  TVoteContent = class(TInterfacedObject, IVoteContent)
  private
    FDetails: TDictionary<string, TBigInteger>;
    FTotal: TBigInteger;
    function GetDetails: TDictionary<string, TBigInteger>;
    function GetTotal: TBigInteger;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  IPoint = interface
    ['{A9B8C7D6-E5F4-4A3B-8C1A-7B6A5C4B3A2D}']
    function GetPrevHash: THash;
    procedure SetPrevHash(const Value: THash);
    function GetHash: THash;
    procedure SetHash(const Value: THash);
    function GetSbps: TDictionary<TAddress, IContent>;
    function GetVotes: IVoteContent;
    procedure SetVotes(const Value: IVoteContent);
    function Json: string;
    function Marshal: TBytes;
    procedure Unmarshal(const ABuf: TBytes);
    function LeftAppend(const AP: IPoint): Boolean;
    function RightAppend(const AP: IPoint): Boolean;
    function IsEmpty: Boolean;
    property PrevHash: THash read GetPrevHash write SetPrevHash;
    property Hash: THash read GetHash write SetHash;
    property Sbps: TDictionary<TAddress, IContent> read GetSbps;
    property Votes: IVoteContent read GetVotes write SetVotes;
  end;

  TPoint = class(TInterfacedObject, IPoint)
  private
    FPrevHash: THash;
    FHash: THash;
    FSbps: TDictionary<TAddress, IContent>;
    FVotes: IVoteContent;
    function GetPrevHash: THash;
    procedure SetPrevHash(const Value: THash);
    function GetHash: THash;
    procedure SetHash(const Value: THash);
    function GetSbps: TDictionary<TAddress, IContent>;
    function GetVotes: IVoteContent;
    procedure SetVotes(const Value: IVoteContent);
  public
    constructor Create; overload;
    constructor Create(const APrevHash, AHash: THash; const ASbps: TDictionary<TAddress, IContent>); overload;
    destructor Destroy; override;
    function Json: string;
    function Marshal: TBytes;
    procedure Unmarshal(const ABuf: TBytes);
    function LeftAppend(const AP: IPoint): Boolean;
    function RightAppend(const AP: IPoint): Boolean;
    function IsEmpty: Boolean;
  end;

function NewEmptyPoint(const AProofHash: THash): IPoint;
function MergeMap(const M1, M2: TDictionary<TAddress, IContent>): TDictionary<TAddress, IContent>;

implementation

uses
  System.JSON, ProtoBuf;

{ TContent }

constructor TContent.Create(AExpectedNum, AFactualNum: Cardinal);
begin
  FExpectedNum := AExpectedNum;
  FFactualNum := AFactualNum;
end;

function TContent.GetExpectedNum: Cardinal; begin Result := FExpectedNum; end;
procedure TContent.SetExpectedNum(const Value: Cardinal); begin FExpectedNum := Value; end;
function TContent.GetFactualNum: Cardinal; begin Result := FFactualNum; end;
procedure TContent.SetFactualNum(const Value: Cardinal); begin FFactualNum := Value; end;

function TContent.Copy: IContent;
begin
  Result := TContent.Create(Self.FExpectedNum, Self.FFactualNum);
end;

procedure TContent.Merge(const AC: IContent);
begin
  Self.FExpectedNum := Self.FExpectedNum + AC.ExpectedNum;
  Self.FFactualNum := Self.FFactualNum + AC.FactualNum;
end;

function TContent.Rate: Integer;
var
  vResult: TBigInteger;
begin
  if Self.FExpectedNum = 0 then
    Result := -1
  else if Self.FFactualNum = 0 then
    Result := 0
  else
  begin
    vResult := TBigInteger.Create(Self.FFactualNum * 1000000) / TBigInteger.Create(Self.FExpectedNum);
    Result := vResult.AsInteger;
  end;
end;

procedure TContent.AddNum(AExpectedNum, AFactualNum: Cardinal);
begin
  Self.FExpectedNum := Self.FExpectedNum + AExpectedNum;
  Self.FFactualNum := Self.FFactualNum + AFactualNum;
end;

{ TVoteContent }

constructor TVoteContent.Create;
begin
  FDetails := TDictionary<string, TBigInteger>.Create;
  FTotal := TBigInteger.Zero;
end;

destructor TVoteContent.Destroy;
begin
  FDetails.Free;
  inherited;
end;

function TVoteContent.GetDetails: TDictionary<string, TBigInteger>; begin Result := FDetails; end;
function TVoteContent.GetTotal: TBigInteger; begin Result := FTotal; end;

{ TPoint }

constructor TPoint.Create;
begin
  FSbps := TDictionary<TAddress, IContent>.Create;
end;

constructor TPoint.Create(const APrevHash, AHash: THash; const ASbps: TDictionary<TAddress, IContent>);
begin
  Create;
  FPrevHash := APrevHash;
  FHash := AHash;
  FSbps.AddPairs(ASbps);
end;

destructor TPoint.Destroy;
begin
  FSbps.Free;
  inherited;
end;

function TPoint.GetPrevHash: THash; begin Result := FPrevHash; end;
procedure TPoint.SetPrevHash(const Value: THash); begin FPrevHash := Value; end;
function TPoint.GetHash: THash; begin Result := FHash; end;
procedure TPoint.SetHash(const Value: THash); begin FHash := Value; end;
function TPoint.GetSbps: TDictionary<TAddress, IContent>; begin Result := FSbps; end;
function TPoint.GetVotes: IVoteContent; begin Result := FVotes; end;
procedure TPoint.SetVotes(const Value: IVoteContent); begin FVotes := Value; end;

function TPoint.Json: string;
begin
  Result := TJson.ObjectToJsonString(Self);
end;

function TPoint.Marshal: TBytes;
var
  vPB: TConsensusPoint;
  vContent: TPointContent;
  vVoteContent: TPointVoteContent;
  I: Integer;
  kvp: TPair<TAddress, IContent>;
  kvpVote: TPair<string, TBigInteger>;
begin
  vPB := TConsensusPoint.Create;
  try
    vPB.Hash := Self.FHash.Bytes;
    vPB.PrevHash := Self.FPrevHash.Bytes;

    if Self.FSbps.Count > 0 then
    begin
      SetLength(vPB.Contents, Self.FSbps.Count);
      I := 0;
      for kvp in Self.FSbps do
      begin
        vContent := TPointContent.Create;
        vContent.Address := kvp.Key.Bytes;
        vContent.ENum := kvp.Value.ExpectedNum;
        vContent.FNum := kvp.Value.FactualNum;
        vPB.Contents[I] := vContent;
        Inc(I);
      end;
    end;

    if Assigned(Self.FVotes) then
    begin
      SetLength(vPB.Votes, Self.FVotes.Details.Count + 1);
      vVoteContent := TPointVoteContent.Create;
      vVoteContent.VoteCnt := Self.FVotes.Total.ToBytes;
      vPB.Votes[0] := vVoteContent;
      I := 1;
      for kvpVote in Self.FVotes.Details do
      begin
        vVoteContent := TPointVoteContent.Create;
        vVoteContent.Name := kvpVote.Key;
        vVoteContent.VoteCnt := kvpVote.Value.ToBytes;
        vPB.Votes[I] := vVoteContent;
        Inc(I);
      end;
    end;

    Result := vPB.ToBytes;
  finally
    vPB.Free;
  end;
end;

procedure TPoint.Unmarshal(const ABuf: TBytes);
var
  vPB: TConsensusPoint;
  vContent: TPointContent;
  vVoteContent: TPointVoteContent;
  vAddr: TAddress;
  vTotal: TBigInteger;
begin
  vPB := TConsensusPoint.Create;
  try
    vPB.MergeFromBytes(ABuf);
    if Length(vPB.Hash) > 0 then
      Self.FHash.SetBytes(vPB.Hash);
    if Length(vPB.PrevHash) > 0 then
      Self.FPrevHash.SetBytes(vPB.PrevHash);

    Self.FSbps.Clear;
    for vContent in vPB.Contents do
    begin
      vAddr.SetBytes(vContent.Address);
      Self.FSbps.Add(vAddr, TContent.Create(vContent.ENum, vContent.FNum));
    end;

    if Length(vPB.Votes) > 0 then
    begin
      Self.FVotes := TVoteContent.Create;
      vTotal.FromBytes(vPB.Votes[0].VoteCnt);
      (Self.FVotes as TVoteContent).FTotal := vTotal;
      for var I := 1 to High(vPB.Votes) do
      begin
        vVoteContent := vPB.Votes[I];
        vTotal.FromBytes(vVoteContent.VoteCnt);
        Self.FVotes.Details.Add(vVoteContent.Name, vTotal);
      end;
    end;

  finally
    vPB.Free;
  end;
end;

function TPoint.LeftAppend(const AP: IPoint): Boolean;
begin
  if not AP.Hash.IsEqual(Self.FPrevHash) then
  begin
    // Raise Exception or return false
    Result := False;
    Exit;
  end;
  Self.FPrevHash := AP.PrevHash;
  Self.FSbps := MergeMap(Self.FSbps, AP.Sbps);
  Result := True;
end;

function TPoint.RightAppend(const AP: IPoint): Boolean;
begin
  if not Self.FHash.IsEqual(AP.PrevHash) then
  begin
    Result := False;
    Exit;
  end;
  Self.FHash := AP.Hash;
  Self.FSbps := MergeMap(Self.FSbps, AP.Sbps);
  Result := True;
end;

function TPoint.IsEmpty: Boolean;
begin
  Result := Self.FHash.IsEqual(Self.FPrevHash);
end;

function NewEmptyPoint(const AProofHash: THash): IPoint;
begin
  Result := TPoint.Create(AProofHash, AProofHash, nil);
end;

function MergeMap(const M1, M2: TDictionary<TAddress, IContent>): TDictionary<TAddress, IContent>;
var
  kvp: TPair<TAddress, IContent>;
  vContent: IContent;
begin
  Result := TDictionary<TAddress, IContent>.Create;
  for kvp in M1 do
  begin
    Result.Add(kvp.Key, kvp.Value.Copy);
  end;
  for kvp in M2 do
  begin
    if Result.TryGetValue(kvp.Key, vContent) then
      vContent.Merge(kvp.Value)
    else
      Result.Add(kvp.Key, kvp.Value.Copy);
  end;
end;

end.
