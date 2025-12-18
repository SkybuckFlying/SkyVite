unit Ledger.Chain.Utils.Keys_State_Redo_Db;

interface

uses
  Common.Types,
  Ledger.Chain.Utils.Conversion,
  Ledger.Chain.Utils.Generate.Key,
  Ledger.Chain.Utils.Generate.Key.Test,
  Ledger.Chain.Utils.Key.Prefix,
  Ledger.Chain.Utils.Keys,
  Ledger.Chain.Utils.Keys.Index.DB,
  Ledger.Chain.Utils.Keys.State.DB,
  System.SysUtils;

type
  TSnapshotKey = record
  private
    FBytes: TBytes;
    const Size = 1 + 8; // HeightSize is 8
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure HeightRefill(height: uint64);
    class function New: TSnapshotKey;
  end;

implementation

uses
  System.Types,
  System.NetEncoding,
  System.SysConst,
  System.RTLConsts,
  System.ConvUtils,
  System.VarUtils,
  System.Variants,
  System.Math,
  System.SyncObjs,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Ansistrings,
  System.Encoding,
  GoToDelphi.Helpers.BigInt;

procedure Uint64Put(var bytes: TBytes; height: uint64);
var
  LBytes: TBytes;
begin
  LBytes := TBitConverter.GetBytes(height);
  if TBitConverter.IsLittleEndian then
    TArray.Reverse<byte>(LBytes);
  Move(LBytes[0], bytes[0], 8);
end;

{ TSnapshotKey }

class function TSnapshotKey.New: TSnapshotKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TSnapshotKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TSnapshotKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TSnapshotKey.HeightRefill(height: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, height);
  Move(LTempBytes[0], Self.FBytes[1], 8);
end;

end.
