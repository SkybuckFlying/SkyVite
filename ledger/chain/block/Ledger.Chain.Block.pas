unit Ledger.Chain.Block;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Interfaces.Core,
  Ledger.Chain.Utils,
  Ledger.Chain.File.Manager;

type
  TBlockDB = class; // Forward declaration

  TBufWriter = class
  private
    FBuffer: TBytesStream;
    FErr: Exception;
    class var FPool: TObjectPool<TBytesStream>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Write(const AData: TBytes);
    procedure WriteError(AErr: Exception);
    procedure Close;
    procedure Release;
    property Buffer: TBytesStream read FBuffer;
    property Err: Exception read FErr;
  end;

  TBlockDB = class
  public
    // from flush.go
    function Id: THash;
    procedure Prepare;
    procedure CancelPrepare;
    function RedoLog: TBytes;
    function Commit: HResult;
    procedure AfterCommit;
    procedure BeforeRecover(const ARedoLog: TBytes);
    procedure AfterRecover;
    function PatchRedoLog(const ARedoLog: TBytes): HResult;

    // from snapshot_block.go
    function GetSnapshotBlock(const ALocation: TLocation): TSnapshotBlock;
    function GetSnapshotHeader(const ALocation: TLocation): TSnapshotBlock;
  end;

implementation

{ TBufWriter }

constructor TBufWriter.Create;
begin
  inherited Create;
  if not Assigned(FPool) then
    FPool := TObjectPool<TBytesStream>.Create;
  FBuffer := FPool.Acquire;
  FBuffer.Clear;
end;

destructor TBufWriter.Destroy;
begin
  Release;
  inherited;
end;

procedure TBufWriter.Write(const AData: TBytes);
begin
  FBuffer.Write(AData, 0, Length(AData));
end;

procedure TBufWriter.WriteError(AErr: Exception);
begin
  FErr := AErr;
end;

procedure TBufWriter.Close;
begin
  // No-op to match Go implementation
end;

procedure TBufWriter.Release;
begin
  if FBuffer <> nil then
  begin
    FPool.Release(FBuffer);
    FBuffer := nil;
  end;
end;

{ TBlockDB }

function TBlockDB.Id: THash;
begin
  Result := Self.id;
end;

procedure TBlockDB.Prepare;
var
  vBufWriter: TBufWriter;
begin
  Self.flushStartLocation := Self.fm.NextFlushStartLocation;
  Self.flushTargetLocation := Self.fm.LatestLocation;

  vBufWriter := TBufWriter.Create;
  Self.fm.ReadRange(Self.flushStartLocation, Self.flushTargetLocation, vBufWriter);

  if vBufWriter.Err <> nil then
    raise Exception.Create(Format('BlockDB prepare failed when flush, start location is %s, target location is %s. Error: %s',
      [Self.flushStartLocation.ToString, Self.flushTargetLocation.ToString, vBufWriter.Err.Message]));

  Self.flushBuf := vBufWriter;
  Self.fm.SetNextFlushStartLocation(Self.flushTargetLocation);
end;

procedure TBlockDB.CancelPrepare;
var
  vNextFlushStartLocation: TLocation;
begin
  vNextFlushStartLocation := Self.fm.NextFlushStartLocation;
  if vNextFlushStartLocation.Compare(Self.flushStartLocation) > 0 then
    Self.fm.SetNextFlushStartLocation(Self.flushStartLocation);

  Self.flushStartLocation := nil;
  Self.flushTargetLocation := nil;

  Self.flushBuf.Release;
  Self.flushBuf := nil;
end;

function TBlockDB.RedoLog: TBytes;
var
  vData: TBytes;
begin
  vData := Self.flushBuf.Buffer.Bytes;
  SetLength(Result, 24 + Length(vData));
  System.Move(SerializeLocation(Self.flushStartLocation)^, Result[0], 12);
  System.Move(SerializeLocation(Self.flushTargetLocation)^, Result[12], 12);
  System.Move(vData[0], Result[24], Length(vData));
end;

function TBlockDB.Commit: HResult;
begin
  Result := Self.fm.Flush(Self.flushStartLocation, Self.flushTargetLocation, Self.flushBuf.Buffer.Bytes);
end;

procedure TBlockDB.AfterCommit;
begin
  Self.flushStartLocation := nil;
  Self.flushTargetLocation := nil;

  Self.flushBuf.Release;
  Self.flushBuf := nil;
end;

procedure TBlockDB.BeforeRecover(const ARedoLog: TBytes);
var
  vFlushStartLocation: TLocation;
begin
  vFlushStartLocation := DeserializeLocation(System.Copy(ARedoLog, 0, 12));
  if Self.fm.DeleteTo(vFlushStartLocation) <> S_OK then
    raise Exception.Create('Failed to delete to flush start location');
  if Self.fm.Write(System.Copy(ARedoLog, 24, Length(ARedoLog) - 24)) < 0 then
    raise Exception.Create('Failed to write redo log');
end;

procedure TBlockDB.AfterRecover;
begin
  // No-op
end;

function TBlockDB.PatchRedoLog(const ARedoLog: TBytes): HResult;
var
  vFlushStartLocation, vFlushTargetLocation: TLocation;
begin
  vFlushStartLocation := DeserializeLocation(System.Copy(ARedoLog, 0, 12));
  vFlushTargetLocation := DeserializeLocation(System.Copy(ARedoLog, 12, 12));
  Result := Self.fm.Flush(vFlushStartLocation, vFlushTargetLocation, System.Copy(ARedoLog, 24, Length(ARedoLog) - 24));
end;

function TBlockDB.GetSnapshotBlock(const ALocation: TLocation): TSnapshotBlock;
var
  vBuf: TBytes;
begin
  vBuf := Self.Read(ALocation);
  if Length(vBuf) = 0 then
    Exit(nil);

  Result := TSnapshotBlock.Create;
  try
    Result.Deserialize(vBuf);
  except
    on E: Exception do
    begin
      Result.Free;
      raise Exception.Create(Format('sb.Deserialize failed, Error: %s', [E.Message]));
    end;
  end;
end;

function TBlockDB.GetSnapshotHeader(const ALocation: TLocation): TSnapshotBlock;
var
  vSB: TSnapshotBlock;
begin
  vSB := GetSnapshotBlock(ALocation);
  if vSB = nil then
    Exit(nil);

  vSB.SnapshotContent := nil;
  Result := vSB;
end;

end.
