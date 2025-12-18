unit Interfaces.Core.ContractMeta;

interface

uses
  Common.Types,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils;

type
  TContractMeta = record
    Gid: TGid;
    SendConfirmedTimes: Byte;
    CreateBlockHash: THash;
    QuotaRatio: Byte;
    SeedConfirmedTimes: Byte;
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaBuf: TBytes): Exception;
  end;

function GetBuiltinContractMeta(const ParaAddr: TAddress): ^TContractMeta;

implementation

const
  LengthBeforeSeedFork = TGidSize + 1 + THashSize + 1;

function TContractMeta.Serialize(out ParaError: Exception): TBytes;
begin
  ParaError := nil;
  SetLength(Result, 0);
  Result := Result + Self.Gid.Bytes;
  Result := Result + [Self.SendConfirmedTimes];
  Result := Result + Self.CreateBlockHash.Bytes;
  Result := Result + [Self.QuotaRatio];
  Result := Result + [Self.SeedConfirmedTimes];
end;

function TContractMeta.Deserialize(const ParaBuf: TBytes): Exception;
var
  vGidBytes, vCreateBlockHashBuf: TBytes;
  vGid: TGid;
  vCreateBlockHash: THash;
  vError: Exception;
begin
  Result := nil;
  SetLength(vGidBytes, TGidSize);
  System.Move(ParaBuf[0], vGidBytes[0], TGidSize);
  vGid := TGid.FromBytes(vGidBytes, vError);
  if vError <> nil then
    Exit(vError);

  SetLength(vCreateBlockHashBuf, THashSize);
  System.Move(ParaBuf[1 + TGidSize], vCreateBlockHashBuf[0], THashSize);
  vCreateBlockHash := THash.FromBytes(vCreateBlockHashBuf, vError);
  if vError <> nil then
    Exit(vError);

  Self.Gid := vGid;
  Self.SendConfirmedTimes := ParaBuf[TGidSize];
  Self.CreateBlockHash := vCreateBlockHash;
  Self.QuotaRatio := ParaBuf[TGidSize + 1 + THashSize];

  if Length(ParaBuf) <= LengthBeforeSeedFork then
  begin
    Self.SeedConfirmedTimes := Self.SendConfirmedTimes;
    Exit;
  end;

  Self.SeedConfirmedTimes := ParaBuf[LengthBeforeSeedFork];
end;

function GetBuiltinContractQuotaRatio(const ParaAddr: TAddress): Byte;
begin
  Result := 10;
end;

function GetBuiltinContractMeta(const ParaAddr: TAddress): ^TContractMeta;
var
  vIsBuiltin, vWithSendConfirm: Boolean;
  vError: Exception;
begin
  Result := nil;
  vIsBuiltin := TAddress.IsBuiltinContractAddrInUse(ParaAddr, vError);
  if vError = nil then
  begin
    vWithSendConfirm := TAddress.IsBuiltinContractAddrInUseWithSendConfirm(ParaAddr, vError);
    if vError = nil then
    begin
      if vWithSendConfirm then
      begin
        New(Result);
        Result.Gid := DELEGATE_GID;
        Result.SendConfirmedTimes := 1;
        Result.CreateBlockHash := Default(THash);
        Result.QuotaRatio := GetBuiltinContractQuotaRatio(ParaAddr);
        Result.SeedConfirmedTimes := 0;
      end
      else if vIsBuiltin then
      begin
        New(Result);
        Result.Gid := DELEGATE_GID;
        Result.SendConfirmedTimes := 0;
        Result.CreateBlockHash := Default(THash);
        Result.QuotaRatio := GetBuiltinContractQuotaRatio(ParaAddr);
        Result.SeedConfirmedTimes := 0;
      end;
    end;
  end;
end;

end.
