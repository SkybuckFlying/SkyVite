unit Interfaces.Core.SnapshotBlock;

interface

uses
  Common.Types,
  Common.Upgrade,
  Common.VitePb,
  Crypto,
  Crypto.Ed25519,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.HashHeight,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils System.Classes System.Generics.Collections;

type
  TSnapshotContent = TDictionary<TAddress, THashHeight>;
  TSnapshotContentBytesList = TArray<TBytes>;

  TSnapshotBlock = record
  private
    mProducer: ^TAddress;
    function GetProducer: TAddress;
  public
    Hash: THash;
    PrevHash: THash;
    Height: UInt64;
    PublicKey: TPublicKey;
    Signature: TBytes;
    Timestamp: TDateTime;
    Seed: UInt64;
    SeedHash: ^THash;
    SnapshotContent: TSnapshotContent;
    Version: UInt32;

    property Producer: TAddress read GetProducer;

    function ComputeHash(out ParaError: Exception): THash;
    function VerifySignature(out ParaError: Exception): Boolean;
    function ToProto: TSnapshotBlockPb;
    function DeProto(const ParaPb: TSnapshotBlockPb): Exception;
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaBuf: TBytes): Exception;
  end;

function ComputeSeedHash(ParaSeed: UInt64; ParaPrevHash: THash; ParaTimestamp: TDateTime; out ParaError: Exception): THash;

implementation

uses
  System.DateUtils,
  Common.Helper;

const
  ScItemBytesLen = TAddress.Size + THash.Size + 8;

function ScItemToBytes(const ParaAddr: TAddress; const ParaHashHeight: THashHeight): TBytes;
var
  vHeightBytes: TBytes;
begin
  SetLength(Result, ScItemBytesLen);
  System.Move(ParaAddr.Bytes[0], Result[0], TAddress.Size);
  System.Move(ParaHashHeight.Hash.Bytes[0], Result[TAddress.Size], THash.Size);
  vHeightBytes := TBitConverter.GetBytes(ParaHashHeight.Height);
  System.Move(vHeightBytes[0], Result[TAddress.Size + THash.Size], 8);
end;

function BytesToScItem(const ParaBuf: TBytes; out ParaAddr: TAddress; out ParaHashHeight: THashHeight; out ParaError: Exception): Boolean;
var
  vHeightBytes: TBytes;
  vError: Exception;
begin
  Result := False;
  ParaError := nil;
  if Length(ParaBuf) <> ScItemBytesLen then
  begin
    ParaError := Exception.Create('Invalid buffer size for BytesToScItem');
    Exit;
  end;

  ParaAddr := TAddress.FromBytes(Copy(ParaBuf, 0, TAddress.Size), vError);
  if vError <> nil then
  begin
    ParaError := vError;
    Exit;
  end;
  ParaHashHeight.Hash := THash.FromBytes(Copy(ParaBuf, TAddress.Size, THash.Size), vError);
  if vError <> nil then
  begin
    ParaError := vError;
    Exit;
  end;
  SetLength(vHeightBytes, 8);
  System.Move(ParaBuf[TAddress.Size + THash.Size], vHeightBytes[0], 8);
  ParaHashHeight.Height := TBitConverter.ToUInt64(vHeightBytes);
  Result := True;
end;

function NewSnapshotContentBytesList(const ParaSc: TSnapshotContent): TSnapshotContentBytesList;
var
  vAddr: TAddress;
  vHashHeight: THashHeight;
begin
  SetLength(Result, ParaSc.Count);
  var i := 0;
  for vAddr in ParaSc.Keys do
  begin
    vHashHeight := ParaSc[vAddr];
    Result[i] := ScItemToBytes(vAddr, vHashHeight);
    Inc(i);
  end;
end;

function SnapshotContentBytesListSort(var ParaScbList: TSnapshotContentBytesList);
begin
  TArray.Sort<TBytes>(ParaScbList, TComparer<TBytes>.Construct(
    function(const L, R: TBytes): Integer
    begin
      Result := TBytes.Compare(L, R);
    end));
end;

function SnapshotContentToProto(const ParaSc: TSnapshotContent): TBytes;
var
  vKeys: TArray<TAddress>;
  vAddress: TAddress;
  i: Integer;
begin
  vKeys := ParaSc.Keys.ToArray;
  TArray.Sort<TAddress>(vKeys, TComparer<TAddress>.Construct(
    function(const L, R: TAddress): Integer
    begin
      Result := R.Compare(L);
    end));

  SetLength(Result, ScItemBytesLen * ParaSc.Count);
  i := 0;
  for vAddress in vKeys do
  begin
    System.Move(ScItemToBytes(vAddress, ParaSc[vAddress])[0], Result[i], ScItemBytesLen);
    Inc(i, ScItemBytesLen);
  end;
end;

function SnapshotContentDeProto(const ParaPb: TBytes; out ParaSc: TSnapshotContent; out ParaError: Exception): Boolean;
var
  vLenPb: Integer;
  vCurrentPointer, vNextPointer: Integer;
  vAddr: TAddress;
  vHashHeight: THashHeight;
  vError: Exception;
begin
  Result := False;
  ParaError := nil;
  vLenPb := Length(ParaPb);
  if vLenPb mod ScItemBytesLen <> 0 then
  begin
    ParaError := Exception.CreateFmt('The length of pb is %d, %d / %d <> 0', [vLenPb, vLenPb, ScItemBytesLen]);
    Exit;
  end;

  ParaSc := TSnapshotContent.Create;
  vCurrentPointer := 0;
  while vCurrentPointer < vLenPb do
  begin
    vNextPointer := vCurrentPointer + ScItemBytesLen;
    if not BytesToScItem(Copy(ParaPb, vCurrentPointer, ScItemBytesLen), vAddr, vHashHeight, vError) then
    begin
      ParaError := vError;
      Exit;
    end;
    ParaSc.Add(vAddr, vHashHeight);
    vCurrentPointer := vNextPointer;
  end;
  Result := True;
end;

{ TSnapshotBlock }

function TSnapshotBlock.GetProducer: TAddress;
var
  vError: Exception;
begin
  if mProducer = nil then
  begin
    New(mProducer);
    mProducer^ := TAddress.FromPublicKey(PublicKey, vError);
    if vError <> nil then
    begin
      // Handle error
    end;
  end;
  Result := mProducer^;
end;

function ComputeSeedHash(ParaSeed: UInt64; ParaPrevHash: THash; ParaTimestamp: TDateTime; out ParaError: Exception): THash;
var
  vSource: TBytes;
  vSeedBytes: TBytes;
  vUnixTimeBytes: TBytes;
begin
  ParaError := nil;
  SetLength(vSource, 0);

  vSeedBytes := TBitConverter.GetBytes(ParaSeed);
  vSource := vSource + vSeedBytes;

  vSource := vSource + ParaPrevHash.Bytes;

  vUnixTimeBytes := TBitConverter.GetBytes(DateTimeToUnix(ParaTimestamp));
  vSource := vSource + vUnixTimeBytes;

  Result := THash.Hash256(vSource, ParaError);
end;

function TSnapshotBlock.ComputeHash(out ParaError: Exception): THash;
var
  vSource: TBytes;
  vHeightBytes: TBytes;
  vUnixTimeBytes: TBytes;
  vSeedBytes: TBytes;
  vScBytesList: TSnapshotContentBytesList;
  vScBytesItem: TBytes;
  vForkPoint: PUpgradePoint;
  vVersionBytes: TBytes;
begin
  ParaError := nil;
  SetLength(vSource, 0);
  vSource := vSource + Self.PrevHash.Bytes;

  vHeightBytes := TBitConverter.GetBytes(Self.Height);
  vSource := vSource + vHeightBytes;

  vUnixTimeBytes := TBitConverter.GetBytes(DateTimeToUnix(Self.Timestamp));
  vSource := vSource + vUnixTimeBytes;

  vSeedBytes := TBitConverter.GetBytes(Self.Seed);
  vSource := vSource + vSeedBytes;

  if Self.SeedHash <> nil then
    vSource := vSource + Self.SeedHash.Bytes
  else
    vSource := vSource + TBytes.Create(32);

  vScBytesList := NewSnapshotContentBytesList(Self.SnapshotContent);
  SnapshotContentBytesListSort(vScBytesList);

  for vScBytesItem in vScBytesList do
    vSource := vSource + vScBytesItem;

  vForkPoint := GetCurPoint(Self.Height);
  if vForkPoint <> nil then
    vSource := vSource + TEncoding.UTF8.GetBytes(vForkPoint.Name);

  if IsLeafUpgrade(Self.Height) then
  begin
    vVersionBytes := TBitConverter.GetBytes(Self.Version);
    vSource := vSource + vVersionBytes;
  end;

  Result := THash.Hash256(vSource, ParaError);
end;

function TSnapshotBlock.VerifySignature(out ParaError: Exception): Boolean;
begin
  Result := TEd25519.Verify(Self.PublicKey, Self.Hash.Bytes, Self.Signature, ParaError);
end;

function TSnapshotBlock.ToProto: TSnapshotBlockPb;
begin
  Result := TSnapshotBlockPb.Create;
  Result.Hash := Self.Hash.Bytes;
  Result.PrevHash := Self.PrevHash.Bytes;
  Result.Height := Self.Height;
  Result.PublicKey := Self.PublicKey;
  Result.Signature := Self.Signature;
  Result.Timestamp := DateTimeToUnix(Self.Timestamp) * 1000000000; // Convert to nanoseconds
  Result.Seed := Self.Seed;
  if Self.SeedHash <> nil then
    Result.SeedHash := Self.SeedHash.Bytes;
  Result.SnapshotContent := SnapshotContentToProto(Self.SnapshotContent);
  Result.Version := Self.Version;
end;

function TSnapshotBlock.DeProto(const ParaPb: TSnapshotBlockPb): Exception;
var
  vTimestampUnix: Int64;
  vSeedHash: THash;
  vError: Exception;
begin
  Result := nil;
  Self.Hash := THash.FromBytes(ParaPb.Hash, vError);
  if vError <> nil then Exit(vError);
  Self.PrevHash := THash.FromBytes(ParaPb.PrevHash, vError);
  if vError <> nil then Exit(vError);
  Self.Height := ParaPb.Height;
  Self.PublicKey := ParaPb.PublicKey;
  Self.Signature := ParaPb.Signature;
  vTimestampUnix := ParaPb.Timestamp div 1000000000; // Convert from nanoseconds to seconds
  Self.Timestamp := UnixToDateTime(vTimestampUnix);
  Self.Seed := ParaPb.Seed;
  if Length(ParaPb.SeedHash) > 0 then
  begin
    vSeedHash := THash.FromBytes(ParaPb.SeedHash, vError);
    if vError <> nil then Exit(vError);
    New(Self.SeedHash);
    Self.SeedHash^ := vSeedHash;
  end;

  if Length(ParaPb.SnapshotContent) > 0 then
  begin
    if not SnapshotContentDeProto(ParaPb.SnapshotContent, Self.SnapshotContent, vError) then
      Exit(vError);
  end
  else
    Self.SnapshotContent := TSnapshotContent.Create;

  Self.Version := ParaPb.Version;
end;

function TSnapshotBlock.Serialize(out ParaError: Exception): TBytes;
var
  vPb: TSnapshotBlockPb;
begin
  vPb := Self.ToProto;
  Result := vPb.ToBytes(ParaError);
end;

function TSnapshotBlock.Deserialize(const ParaBuf: TBytes): Exception;
var
  vPb: TSnapshotBlockPb;
begin
  Result := nil;
  vPb := TSnapshotBlockPb.Create;
  Result := vPb.FromBytes(ParaBuf);
  if Result = nil then
    Result := Self.DeProto(vPb);
end;

end.
