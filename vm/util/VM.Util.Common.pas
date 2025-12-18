unit VM.Util.Common;

interface

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Ledger;

var
  AttovPerVite: TBigInteger;
  CreateContractDataLengthMin: Integer;
  CreateContractDataLengthMinRand: Integer;
  SolidityPPContractType: Byte;

function IsViteToken(const ATokenID: TTokenTypeId): Boolean;
function IsSnapshotGid(AGid: TGid): Boolean;
function IsDelegateGid(AGid: TGid): Boolean;
function MakeRequestBlock(const AFromAddress, AToAddress: TAddress; ABlockType: Byte; AAmount: TBigInteger; ATokenID: TTokenTypeId; const AData: TBytes): TAccountBlock;
function GetCreateContractData(const ABytecode: TBytes; AContractType, ASnapshotCount, ASnapshotWithSeedCount, AQuotaMultiplier: Byte; AGid: TGid): TBytes;
function GetGidFromCreateContractData(const AData: TBytes): TGid;
function GetContractTypeFromCreateContractData(const AData: TBytes): Byte;
function IsExistContractType(AContractType: Byte): Boolean;
function GetSnapshotCountFromCreateContractData(const AData: TBytes): Byte;
function GetSnapshotWithSeedCountCountFromCreateContractData(const AData: TBytes): Byte;
function GetQuotaMultiplierFromCreateContractData(const AData: TBytes; ASnapshotHeight: UInt64): Byte;
function GetCodeFromCreateContractData(const AData: TBytes; ASnapshotHeight: UInt64): TBytes;
function PackContractCode(AContractType: Byte; const ACode: TBytes): TBytes;
function NewContractAddress(const AAccountAddress: TAddress; AAccountBlockHeight: UInt64; const APrevBlockHash: THash): TAddress;
function PrintMap(AMap: TDictionary<string, TBytes>): string;
function CheckFork(const ADB: IDbInterface; AFunc: TFunc<UInt64, Boolean>): Boolean;
function FirstToLower(const AStr: string): string;
function ComputeSendBlockHash(const AReceiveBlock, ASendBlock: TAccountBlock; AIndex: Byte): THash;

implementation

uses
  System.Character, GoVite.Common.Upgrade;

initialization
  AttovPerVite := TBigInteger.Parse('1000000000000000000');
  CreateContractDataLengthMin := 13;
  CreateContractDataLengthMinRand := 14;
  SolidityPPContractType := 1;

function IsViteToken(const ATokenID: TTokenTypeId): Boolean;
begin
  Result := ATokenID.Equals(ViteTokenId);
end;

// ... other function implementations ...

end.
