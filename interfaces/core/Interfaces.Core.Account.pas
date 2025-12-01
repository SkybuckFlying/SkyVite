unit Interfaces.Core.Account;

interface

uses
  System.SysUtils,
  Common.Types,
  Crypto.Ed25519,
  Common.VitePb;

type
  TAccount = record
    AccountAddress: TAddress;
    AccountId: UInt64;
    PublicKey: TPublicKey;
    function ToProto: TAccountPb;
    procedure DeProto(const ParaPb: TAccountPb);
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaBuf: TBytes): Exception;
  end;

implementation

function TAccount.ToProto: TAccountPb;
begin
  Result := TAccountPb.Create;
  Result.AccountId := Self.AccountId;
  Result.PublicKey := Self.PublicKey;
end;

procedure TAccount.DeProto(const ParaPb: TAccountPb);
var
  vError: Exception;
begin
  Self.AccountId := ParaPb.AccountId;
  Self.PublicKey := ParaPb.PublicKey;
  Self.AccountAddress := TAddress.FromBytes(Self.PublicKey, vError);
  if vError <> nil then
  begin
    // Handle error
  end;
end;

function TAccount.Serialize(out ParaError: Exception): TBytes;
var
  vPb: TAccountPb;
begin
  vPb := Self.ToProto;
  Result := vPb.ToBytes(ParaError);
end;

function TAccount.Deserialize(const ParaBuf: TBytes): Exception;
var
  vPb: TAccountPb;
begin
  Result := nil;
  vPb := TAccountPb.Create;
  Result := vPb.FromBytes(ParaBuf);
  if Result = nil then
  begin
    Self.DeProto(vPb);
  end;
end;

end.
