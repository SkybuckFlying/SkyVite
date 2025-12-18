unit Vm.Contracts.Dex.DexAccount;

interface

uses
  Common.Types.TokenTypeId Vm.Contracts.Dex.Proto.DexProto,
  System.SysUtils System.Classes,
  VM.Contracts.Dex.Calculator,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Event,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper,
  VM.Contracts.Dex.Fund.Helper.Test,
  VM.Contracts.Dex.Fund.Mine,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

type
  TDexAccount = record
    Token: TTokenTypeId;
    Available: TBigInteger;
    Locked: TBigInteger;
    VxLocked: TBigInteger;
    VxUnlocking: TBigInteger;
    CancellingStake: TBigInteger;
    function Serialize: TDexProtoAccount;
    procedure Deserialize(const Pb: TDexProtoAccount);
  end;

implementation

{ TDexAccount }

function TDexAccount.Serialize: TDexProtoAccount;
begin
  Result := TDexProtoAccount.Create;
  Result.Token := Token.Bytes;
  if Available <> nil then
    Result.Available := Available.ToByteArray;
  if Locked <> nil then
    Result.Locked := Locked.ToByteArray;
  if VxLocked <> nil then
    Result.VxLocked := VxLocked.ToByteArray;
  if VxUnlocking <> nil then
    Result.VxUnlocking := VxUnlocking.ToByteArray;
  if CancellingStake <> nil then
    Result.CancellingStake := CancellingStake.ToByteArray;
end;

procedure TDexAccount.Deserialize(const Pb: TDexProtoAccount);
begin
  Token := BytesToTokenTypeId(Pb.Token);
  if Length(Pb.Available) > 0 then
    Available := TBigInteger.FromByteArray(Pb.Available);
  if Length(Pb.Locked) > 0 then
    Locked := TBigInteger.FromByteArray(Pb.Locked);
  if Length(Pb.VxLocked) > 0 then
    VxLocked := TBigInteger.FromByteArray(Pb.VxLocked);
  if Length(Pb.VxUnlocking) > 0 then
    VxUnlocking := TBigInteger.FromByteArray(Pb.VxUnlocking);
  if Length(Pb.CancellingStake) > 0 then
    CancellingStake := TBigInteger.FromByteArray(Pb.CancellingStake);
end;

end.
