unit Ledger.Chain.Plugins.DB.Key.Prefix;

interface

uses
  Common.Types,
  Ledger.Chain.Plugins.Filter.Token,
  Ledger.Chain.Plugins.Interface,
  Ledger.Chain.Plugins.Onroad.Info,
  Ledger.Chain.Plugins.Onroad.Info.Test,
  Ledger.Chain.Plugins.Plugins,
  System.SysUtils;

const
  OnRoadInfoKeyPrefix = $01;
  DiffTokenHash = $02;

function CreateOnRoadInfoKey(const AAddr: TAddress; const ATId: TTokenTypeId): TBytes;
function CreateOnRoadInfoPrefixKey(const AAddr: TAddress): TBytes;

implementation

function CreateOnRoadInfoKey(const AAddr: TAddress; const ATId: TTokenTypeId): TBytes;
var
  vAddrBytes, vTIdBytes: TBytes;
begin
  vAddrBytes := AAddr.Bytes;
  vTIdBytes := ATId.Bytes;
  SetLength(Result, 1 + Length(vAddrBytes) + Length(vTIdBytes));
  Result[0] := OnRoadInfoKeyPrefix;
  System.Move(vAddrBytes[0], Result[1], Length(vAddrBytes));
  System.Move(vTIdBytes[0], Result[1 + Length(vAddrBytes)], Length(vTIdBytes));
end;

function CreateOnRoadInfoPrefixKey(const AAddr: TAddress): TBytes;
var
  vAddrBytes: TBytes;
begin
  vAddrBytes := AAddr.Bytes;
  SetLength(Result, 1 + Length(vAddrBytes));
  Result[0] := OnRoadInfoKeyPrefix;
  System.Move(vAddrBytes[0], Result[1], Length(vAddrBytes));
end;

end.
