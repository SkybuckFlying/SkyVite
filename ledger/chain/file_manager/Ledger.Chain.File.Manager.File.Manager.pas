unit Ledger.Chain.FileManager.FileManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Vite.Common,
  Vite.Interfaces,
  Ledger.Chain.FileManager.Interfaces,
  Ledger.Chain.FileManager.FdManager,
  Ledger.Chain.FileManager.Location,
  Ledger.Chain.FileManager.Fd;

type
  TDataParser = class(IDataParser)
  public
    function Write(ParaBuf: TBytes): TError;
    procedure WriteError(ParaError: TError);
  end;

  TFileManager = class(IFileManager)
  private
    mFileSize: Int64;
    mFdSet: IFdManager;
    mNextFlushStartLocation: ILocation;
    mPrevFlushLocation: ILocation;
    mFSyncWg: TCountdownEvent;
    mLog: TLogger;
    function readFile(ParaFd: TFileDescription; ParaFromLocation, ParaToLocation: ILocation): TBytes;
    function write(ParaBuf: TBytes): Integer;
  public
    constructor Create(ParaDirName: string; ParaFileSize: Int64; ParaCacheCount: Integer);
    destructor Destroy; override;
    function NextFlushStartLocation: ILocation;
    procedure SetNextFlushStartLocation(ParaLocation: ILocation);
    function LatestLocation: ILocation;
    function Write(ParaBuf: TBytes): ILocation;
    function DeleteTo(ParaLocation: ILocation): TError;
    function Flush(ParaStartLocation, ParaTargetLocation: ILocation; ParaBuf: TBytes): TError;
    function GetNextLocation(ParaLocation: ILocation): ILocation;
    function Read(ParaLocation: ILocation; out ParaNextLocation: ILocation): TBytes;
    function ReadRaw(ParaStartLocation: ILocation; ParaBuf: TBytes; out ParaNextLocation: ILocation): Integer;
    procedure ReadRange(ParaStartLocation, ParaEndLocation: ILocation; ParaParser: IDataParser);
    procedure SetLog(ParaHandler: TLogHandler);
    procedure Close;
    function GetCacheStatusList: TArray<IDBStatus>;
  end;

implementation

{ TDataParser }

function TDataParser.Write(ParaBuf: TBytes): TError;
begin
  Result := nil;
end;

procedure TDataParser.WriteError(ParaError: TError);
begin
end;

{ TFileManager }

constructor TFileManager.Create(ParaDirName: string; ParaFileSize: Int64; ParaCacheCount: Integer);
begin
  inherited Create;
  mFileSize := ParaFileSize;
  mLog := TLogger.Create('fileManager');
  mFdSet := TFdManager.Create(Self, ParaDirName, ParaFileSize, ParaCacheCount);
  mNextFlushStartLocation := mFdSet.LatestLocation;
  mPrevFlushLocation := mNextFlushStartLocation;
  mFSyncWg := TCountdownEvent.Create(0);
end;

destructor TFileManager.Destroy;
begin
  Close;
  mFSyncWg.Free;
  inherited Destroy;
end;

function TFileManager.NextFlushStartLocation: ILocation;
begin
  if mNextFlushStartLocation = nil then
    Result := nil
  else
    Result := TLocation.Create(mNextFlushStartLocation.FileId, mNextFlushStartLocation.Offset);
end;

procedure TFileManager.SetNextFlushStartLocation(ParaLocation: ILocation);
begin
  mNextFlushStartLocation := TLocation.Create(ParaLocation.FileId, ParaLocation.Offset);
end;

function TFileManager.LatestLocation: ILocation;
begin
  Result := mFdSet.LatestLocation;
end;

function TFileManager.Write(ParaBuf: TBytes): ILocation;
var
  vBufSize, n, vCount: Integer;
begin
  vBufSize := Length(ParaBuf);
  Result := mFdSet.LatestLocation;
  n := 0;
  while n < vBufSize do
  begin
    vCount := write(TBytes.Create(@ParaBuf[n], vBufSize - n));
    n := n + vCount;
  end;
end;

function TFileManager.DeleteTo(ParaLocation: ILocation): TError;
begin
  Result := nil;
  if ParaLocation.Compare(LatestLocation) >= 0 then
    Exit;
  Result := mFdSet.DeleteTo(ParaLocation);
  if Result <> nil then
    Exit;

  if ParaLocation.Compare(mNextFlushStartLocation) < 0 then
    mNextFlushStartLocation := ParaLocation;
end;

function TFileManager.Flush(ParaStartLocation, ParaTargetLocation: ILocation; ParaBuf: TBytes): TError;
var
  vFlushLocation: ILocation;
  vBufStart: Int64;
  vFd: TFileDescription;
  vTargetOffset, vBufEnd: Int64;
  n, vFlushOffset: Int64;
begin
  Result := nil;
  vFlushLocation := TLocation.Create(ParaStartLocation.FileId, ParaStartLocation.Offset);
  vBufStart := 0;

  while vFlushLocation.Compare(ParaTargetLocation) < 0 do
  begin
    vFd := mFdSet.GetFd(vFlushLocation.FileId);
    if vFd = nil then
    begin
      vFd := mFdSet.GetTmpFlushFd(vFlushLocation.FileId);
      if vFd = nil then
      begin
        Result := TError.CreateFmt('fd is nil, fileId is %d', [vFlushLocation.FileId]);
        Exit;
      end;
    end;

    vTargetOffset := mFileSize;
    if vFlushLocation.FileId = ParaTargetLocation.FileId then
      vTargetOffset := ParaTargetLocation.Offset;

    vBufEnd := vBufStart + vTargetOffset - vFlushLocation.Offset;
    n := vFd.Flush(vFlushLocation.Offset, TBytes.Create(@ParaBuf[vBufStart], vBufEnd - vBufStart));
    vFlushOffset := vFlushLocation.Offset + n;
    vBufStart := vBufStart + n;

    if vFlushOffset >= mFileSize then
    begin
      vFlushLocation.FileId := vFlushLocation.FileId + 1;
      vFlushLocation.Offset := 0;
    end
    else
      vFlushLocation.Offset := vFlushOffset;
  end;

  if mPrevFlushLocation.Compare(ParaTargetLocation) > 0 then
  begin
    Result := mFdSet.DiskDelete(mPrevFlushLocation, ParaTargetLocation);
    if Result <> nil then
      Exit;
  end;

  mPrevFlushLocation := ParaTargetLocation;
end;

function TFileManager.GetNextLocation(ParaLocation: ILocation): ILocation;
var
  vBufSizeBytes: TBytes;
  vBufSize: UInt32;
  vOffset: Int64;
begin
  SetLength(vBufSizeBytes, 4);
  ReadRaw(ParaLocation, vBufSizeBytes, Result);
  vBufSize := TBitConverter.ToUInt32(vBufSizeBytes, 0);
  vOffset := ParaLocation.Offset + vBufSize + 4;
  Result := TLocation.Create(ParaLocation.FileId + (vOffset div mFileSize), vOffset mod mFileSize);
end;

function TFileManager.Read(ParaLocation: ILocation; out ParaNextLocation: ILocation): TBytes;
var
  vBufSizeBytes: TBytes;
  vBufSize: UInt32;
begin
  SetLength(vBufSizeBytes, 4);
  ReadRaw(ParaLocation, vBufSizeBytes, ParaNextLocation);
  vBufSize := TBitConverter.ToUInt32(vBufSizeBytes, 0);
  SetLength(Result, vBufSize);
  ReadRaw(ParaNextLocation, Result, ParaNextLocation);
end;

function TFileManager.ReadRaw(ParaStartLocation: ILocation; ParaBuf: TBytes; out ParaNextLocation: ILocation): Integer;
var
  vReadLen, i, vReadSize, vFreeSize, vReadN: Integer;
  vCurrentLocation: ILocation;
  vFd: TFileDescription;
  vNextOffset: Int64;
begin
  vReadLen := Length(ParaBuf);
  i := 0;
  vCurrentLocation := ParaStartLocation;
  while i < vReadLen do
  begin
    vReadSize := vReadLen - i;
    vFreeSize := mFileSize - vCurrentLocation.Offset;
    if vReadSize > vFreeSize then
      vReadSize := vFreeSize;

    vFd := mFdSet.GetFd(vCurrentLocation.FileId);
    if vFd = nil then
    begin
      ParaNextLocation := vCurrentLocation;
      Result := i;
      Exit;
    end;
    try
      vReadN := vFd.ReadAt(TBytes.Create(@ParaBuf[i], vReadSize), vCurrentLocation.Offset);
    finally
      vFd.Free;
    end;
    i := i + vReadN;
    vNextOffset := vCurrentLocation.Offset + vReadN;

    if vNextOffset >= mFileSize then
      vCurrentLocation := TLocation.Create(vCurrentLocation.FileId + 1, 0)
    else
      vCurrentLocation := TLocation.Create(vCurrentLocation.FileId, vNextOffset);
  end;
  ParaNextLocation := vCurrentLocation;
  Result := i;
end;

procedure TFileManager.ReadRange(ParaStartLocation, ParaEndLocation: ILocation; ParaParser: IDataParser);
var
  vRealEndLocation, vCurrentLocation, vToLocation: ILocation;
  vFd: TFileDescription;
  vBuf: TBytes;
begin
  vRealEndLocation := ParaEndLocation;
  if vRealEndLocation = nil then
    vRealEndLocation := LatestLocation;

  vCurrentLocation := ParaStartLocation;
  while vCurrentLocation.FileId <= vRealEndLocation.FileId do
  begin
    vFd := mFdSet.GetFd(vCurrentLocation.FileId);
    if vFd = nil then
    begin
      ParaParser.WriteError(TError.CreateFmt('fd is nil, location is %s', [vCurrentLocation.ToString]));
      Exit;
    end;
    try
      vToLocation := TLocation.Create(vCurrentLocation.FileId, mFileSize);
      if vCurrentLocation.FileId = vRealEndLocation.FileId then
        vToLocation := vRealEndLocation;

      vBuf := readFile(vFd, vCurrentLocation, vToLocation);
      if ParaParser.Write(vBuf) <> nil then
        Exit;
    finally
      vFd.Free;
    end;
    vCurrentLocation := TLocation.Create(vCurrentLocation.FileId + 1, 0);
  end;
end;

procedure TFileManager.SetLog(ParaHandler: TLogHandler);
begin
  mLog.SetHandler(ParaHandler);
end;

procedure TFileManager.Close;
begin
  mFdSet.Close;
end;

function TFileManager.GetCacheStatusList: TArray<IDBStatus>;
begin
  SetLength(Result, 1);
  Result[0] := TDBStatus.Create('blockDB.fm.cache', mFdSet.FileFdCache.Count, mFdSet.FileFdCache.Count * mFileSize, '');
end;

function TFileManager.readFile(ParaFd: TFileDescription; ParaFromLocation, ParaToLocation: ILocation): TBytes;
var
  vReadN: Integer;
begin
  SetLength(Result, ParaToLocation.Offset - ParaFromLocation.Offset);
  vReadN := ParaFd.ReadAt(Result, ParaFromLocation.Offset);
  SetLength(Result, vReadN);
end;

function TFileManager.write(ParaBuf: TBytes): Integer;
var
  vBufLen, vCount: Integer;
  vFd: TFileDescription;
begin
  vBufLen := Length(ParaBuf);
  vFd := mFdSet.GetWriteFd;
  vCount := vFd.Write(ParaBuf);
  if vCount < vBufLen then
    mFdSet.CreateNextFd;
  Result := vCount;
end;

end.
