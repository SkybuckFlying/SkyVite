unit Ledger.Consensus.CDB.Consensus;

interface

uses
  Common.Types,
  GoLevelDB,
  Ledger.Consensus.CDB.DB.Test,
  Ledger.Consensus.CDB.Point,
  Ledger.Consensus.CDB.Point.Test,
  System.Generics.Collections,
  System.SysUtils;

const
  IndexElectionResult = $00;
  IndexPointPeriod = $01;
  IndexPointHour = $02;
  IndexPointDay = $03;

type
  TAddrArr = TArray<TAddress>;
  TConsensusDB = class
  private
    FDB: ILevelDB;
  public
    constructor Create(const ADB: ILevelDB);
    function GetPointByHeight(APrefix: Byte; AHeight: UInt64): IPoint;
    procedure DeletePointByHeight(APrefix: Byte; AHeight: UInt64);
    procedure StorePointByHeight(APrefix: Byte; AHeight: UInt64; const AP: IPoint);
    function GetElectionResultByHash(const AHash: THash): TAddrArr;
    procedure DeleteElectionResultByHash(const AHash: THash);
    procedure StoreElectionResultByHash(const AHash: THash; const AAddrArr: TAddrArr);
    procedure Check;
  end;

function AddrArrToBytes(const AAddrs: TAddrArr): TBytes;
function BytesToAddrArr(const AByt: TBytes): TAddrArr;
function CreateElectionResultPrefixKey: TBytes;
function CreateElectionResultKey(const AHash: THash): TBytes;
function CreatePointKey(APrefix: Byte; AHeight: UInt64): TBytes;

implementation

uses
  System.Net.Sockets;

function AddrArrToBytes(const AAddrs: TAddrArr): TBytes;
var
  vAddr: TAddress;
  vOffset: Integer;
begin
  SetLength(Result, Length(AAddrs) * TAddress.AddressSize);
  vOffset := 0;
  for vAddr in AAddrs do
  begin
    System.Move(vAddr.Bytes[0], Result[vOffset], TAddress.AddressSize);
    Inc(vOffset, TAddress.AddressSize);
  end;
end;

function BytesToAddrArr(const AByt: TBytes): TAddrArr;
var
  vSize: Integer;
  I: Integer;
  vAddrBytes: TBytes;
begin
  vSize := Length(AByt) div TAddress.AddressSize;
  SetLength(Result, vSize);
  for I := 0 to vSize - 1 do
  begin
    SetLength(vAddrBytes, TAddress.AddressSize);
    System.Move(AByt[I * TAddress.AddressSize], vAddrBytes[0], TAddress.AddressSize);
    Result[I] := TAddress.BytesToAddress(vAddrBytes);
  end;
end;

{ TConsensusDB }

constructor TConsensusDB.Create(const ADB: ILevelDB);
begin
  FDB := ADB;
end;

function TConsensusDB.GetPointByHeight(APrefix: Byte; AHeight: UInt64): IPoint;
var
  vKey, vValue: TBytes;
begin
  vKey := CreatePointKey(APrefix, AHeight);
  if FDB.Get(vKey, vValue) then
  begin
    Result := TPoint.Create;
    Result.Unmarshal(vValue);
  end
  else
    Result := nil;
end;

procedure TConsensusDB.DeletePointByHeight(APrefix: Byte; AHeight: UInt64);
var
  vKey: TBytes;
begin
  vKey := CreatePointKey(APrefix, AHeight);
  FDB.Delete(vKey);
end;

procedure TConsensusDB.StorePointByHeight(APrefix: Byte; AHeight: UInt64; const AP: IPoint);
var
  vKey, vByt: TBytes;
begin
  vKey := CreatePointKey(APrefix, AHeight);
  vByt := AP.Marshal;
  FDB.Put(vKey, vByt);
end;

function TConsensusDB.GetElectionResultByHash(const AHash: THash): TAddrArr;
var
  vKey, vValue: TBytes;
begin
  vKey := CreateElectionResultKey(AHash);
  if FDB.Get(vKey, vValue) then
  begin
    Result := BytesToAddrArr(vValue);
  end
  else
    Result := nil;
end;

procedure TConsensusDB.DeleteElectionResultByHash(const AHash: THash);
var
  vKey: TBytes;
begin
  vKey := CreateElectionResultKey(AHash);
  FDB.Delete(vKey);
end;

procedure TConsensusDB.StoreElectionResultByHash(const AHash: THash; const AAddrArr: TAddrArr);
var
  vData, vKey: TBytes;
begin
  vData := AddrArrToBytes(AAddrArr);
  vKey := CreateElectionResultKey(AHash);
  FDB.Put(vKey, vData);
end;

procedure TConsensusDB.Check;
var
  vIterator: IIterator;
  vKey, vBytes: TBytes;
  vHash: THash;
begin
  vKey := CreateElectionResultPrefixKey;
  vIterator := FDB.NewIterator(vKey);
  try
    while vIterator.Next do
    begin
      vBytes := vIterator.Key;
      vHash := THash.BytesToHash(TBytes.Copy(vBytes, 1, Length(vBytes) - 1));
      // In a real application, you'd do something with the hash.
      // For this translation, we're just iterating as in the Go example.
      Writeln(vHash.ToString);
    end;
  finally
    vIterator := nil;
  end;
end;

function CreateElectionResultPrefixKey: TBytes;
begin
  SetLength(Result, 1);
  Result[0] := IndexElectionResult;
end;

function CreateElectionResultKey(const AHash: THash): TBytes;
begin
  SetLength(Result, 1 + THash.HashSize);
  Result[0] := IndexElectionResult;
  System.Move(AHash.Bytes[0], Result[1], THash.HashSize);
end;

function CreatePointKey(APrefix: Byte; AHeight: UInt64): TBytes;
begin
  SetLength(Result, 1 + 8);
  Result[0] := APrefix;
  PUInt64(@Result[1])^ := HToN(AHeight);
end;

end.
