unit VM.Util.DB.Helper;

interface

uses
  System.SysUtils, System.BigInt,
  GoVite.Types, GoVite.Ledger;

type
  IDbInterface = interface
    ['{E3B9F2A0-4F6D-4A4D-8B4A-9A2B2C2D2E3F}']
    function GetBalance(ATokenTypeID: TTokenTypeId): TBigInteger;
    procedure SetBalance(ATokenTypeID: TTokenTypeId; AAmount: TBigInteger);
    function GetValue(const AKey: TBytes): TBytes;
    procedure SetValue(const AKey, AValue: TBytes);
    function LatestSnapshotBlock: TSnapshotBlock;
    function Address: TAddress;
    function GetContractCode: TBytes;
    function GetContractCodeBySnapshotBlock(const AAddr: TAddress; const ASnapshotBlock: TSnapshotBlock): TBytes;
  end;

procedure AddBalance(const ADB: IDbInterface; const AID: TTokenTypeId; const AAmount: TBigInteger);
function SubBalance(const ADB: IDbInterface; const AID: TTokenTypeId; const AAmount: TBigInteger): Boolean;
function GetValue(const ADB: IDbInterface; const AKey: TBytes): TBytes;
procedure SetValue(const ADB: IDbInterface; const AKey, AValue: TBytes);
function GetContractCode(const ADB: IDbInterface; const AAddr: TAddress; const AStatus: IGlobalStatus): TPair<TBytes, TBytes>;

implementation

uses
  VM.Util.Common;

procedure AddBalance(const ADB: IDbInterface; const AID: TTokenTypeId; const AAmount: TBigInteger);
var
  LBalance: TBigInteger;
begin
  LBalance := ADB.GetBalance(AID);
  LBalance := LBalance + AAmount;
  ADB.SetBalance(AID, LBalance);
end;

// ... other implementations ...

end.
