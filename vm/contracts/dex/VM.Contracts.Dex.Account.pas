unit Vm.Contracts.Dex.DexAccount;

interface

uses
  System.SysUtils, System.Classes,
  Common.Types.TokenTypeId, Vm.Contracts.Dex.Proto.DexProto;

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
