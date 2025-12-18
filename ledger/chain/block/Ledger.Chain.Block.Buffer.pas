unit Ledger.Chain.Block.Buffer;

interface

uses
  Ledger.Chain.Block.Account.Block,
  Ledger.Chain.Block.Block.DB,
  Ledger.Chain.Block.Block.DB.Test,
  Ledger.Chain.Block.Block.Parser,
  Ledger.Chain.Block.Flush,
  Ledger.Chain.Block.Snapshot.Block,
  System.SysUtils System.Classes System.Types;

function MakeWriteBytes(var ParaBuf: TBytes; ParaDataType: Byte; const ParaData: TBytes): TBytes;

implementation

uses
  GoToDelphi.Dependencies.snappy.libsnappy, System.Math;

function MakeWriteBytes(var ParaBuf: TBytes; ParaDataType: Byte; const ParaData: TBytes): TBytes;
var
  vSBuf: TBytes;
  vSBufLen: Integer;
  vLen: Integer;
  vStatus: snappy_status;
begin
  vStatus := SnappyCompress(ParaData, vSBuf);
  if vStatus <> SNAPPY_OK then
  begin
    // Handle compression error, maybe raise an exception
    raise Exception.Create('Snappy compression failed.');
  end;

  vSBufLen := Length(vSBuf);

  if Length(ParaBuf) < 5 + vSBufLen then
  begin
    SetLength(ParaBuf, 5 + vSBufLen);
  end;

  ParaBuf[4] := ParaDataType;
  Move(vSBuf[0], ParaBuf[5], vSBufLen);

  // Write length in big endian
  vLen := vSBufLen + 1;
  ParaBuf[0] := (vLen shr 24) and $FF;
  ParaBuf[1] := (vLen shr 16) and $FF;
  ParaBuf[2] := (vLen shr 8) and $FF;
  ParaBuf[3] := vLen and $FF;

  SetLength(Result, 5 + vSBufLen);
  Move(ParaBuf[0], Result[0], 5 + vSBufLen);
end;

end.
