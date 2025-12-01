// Copyright (c) 2013, Suryandaru Triandana <syndtr@gmail.com>
// All rights reserved.
//
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
unit Common.Db.XLevelDB.DB.State;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Threading,
  System.Generics.Collections,
  GoToDelphi.Helpers.TChannel,
  Common.Db.XLevelDB.Journal,
  Common.Db.XLevelDB.MemDB,
  Common.Db.XLevelDB.Storage,
  Common.Db.XLevelDB.Key,
  Common.Db.XLevelDB.Errors,
  Common.Db.XLevelDB.DB;

type
  EErrHasFrozenMem = class(ELevelDBError);

  TMemDBWrapper = class
  private
    FDb: TDB;
    FMemDB: TMemDB;
    FRef: Integer;
  public
    constructor Create(ADB: TDB; AMemDB: TMemDB);
    destructor Destroy; override;
    function GetRef: Integer;
    procedure Incref;
    procedure Decref;
    property DB: TMemDB read FMemDB;
  end;

implementation

uses
  System.DateUtils,
  System.Math;

{ TMemDBWrapper }

constructor TMemDBWrapper.Create(ADB: TDB; AMemDB: TMemDB);
begin
  inherited Create;
  FDb := ADB;
  FMemDB := AMemDB;
end;

destructor TMemDBWrapper.Destroy;
begin
  FMemDB.Free;
  inherited;
end;

function TMemDBWrapper.GetRef: Integer;
begin
  Result := TInterlocked.Read(FRef);
end;

procedure TMemDBWrapper.Incref;
begin
  TInterlocked.Increment(FRef);
end;

procedure TMemDBWrapper.Decref;
begin
  if TInterlocked.Decrement(FRef) = 0 then
  begin
    if FMemDB.Capacity = FDb.FS.O.GetWriteBuffer then
    begin
      FMemDB.Reset;
      FDb.MpoolPut(FMemDB);
    end;
    FDb := nil;
    FMemDB := nil;
  end
  else if TInterlocked.Read(FRef) < 0 then
    raise Exception.Create('negative memdb ref');
end;

{ TDB }

function TDB.GetSeq: UInt64;
begin
  Result := TInterlocked.Read(FSeq);
end;

procedure TDB.AddSeq(ADelta: UInt64);
begin
  TInterlocked.Add(FSeq, ADelta);
end;

procedure TDB.SetSeq(ASeq: UInt64);
begin
  TInterlocked.Exchange(FSeq, ASeq);
end;

procedure TDB.SampleSeek(AIkey: TBytes);
var
  vV: TVersion;
begin
  vV := FS.Version;
  try
    if vV.SampleSeek(AIkey) then
      CompTrigger(FTCompCmdC);
  finally
    vV.Release;
  end;
end;

procedure TDB.MpoolPut(AMem: TMemDB);
begin
  if not IsClosed then
    FMemPool.Send(AMem);
end;

function TDB.MpoolGet(AN: Integer): TMemDBWrapper;
var
  vMdb: TMemDB;
begin
  if not FMemPool.Receive(vMdb) then
    vMdb := nil;

  if (vMdb = nil) or (vMdb.Capacity < AN) then
    vMdb := TMemDB.Create(FS.ICmp, Max(FS.O.GetWriteBuffer, AN));

  Result := TMemDBWrapper.Create(Self, vMdb);
end;

procedure TDB.MpoolDrain;
var
  vTicker: TTimer;
  vMdb: TMemDB;
begin
  vTicker := TTimer.Create(nil);
  try
    vTicker.Interval := 30000;
    vTicker.OnTimer :=
      procedure(Sender: TObject)
      begin
        if FMemPool.TryReceive(vMdb) then
          vMdb.Free;
      end;
    vTicker.Enabled := True;
    FCloseC.Receive(nil);
  finally
    vTicker.Free;
  end;
  if FMemPool.TryReceive(vMdb) then
    vMdb.Free;
  FMemPool.Close;
end;

function TDB.NewMem(AN: Integer): TMemDBWrapper;
var
  vFd: TFileDesc;
  vW: IWriter;
  vMem: TMemDBWrapper;
  vErr: Exception;
begin
  vFd := TFileDesc.Create(TFileType.TypeJournal, FS.AllocFileNum);
  vW := FS.Stor.Create(vFd, vErr);
  if vErr <> nil then
  begin
    FS.ReuseFileNum(vFd.Num);
    raise vErr;
  end;

  EnterCriticalSection(FMemMu);
  try
    if FFrozenMem <> nil then
      raise EErrHasFrozenMem.Create('');

    if FJournal = nil then
      FJournal := TJournalWriter.Create(vW)
    else
    begin
      FJournal.Reset(vW);
      FJournalWriter.Close;
      FFrozenJournalFd := FJournalFd;
    end;
    FJournalWriter := vW;
    FJournalFd := vFd;
    FFrozenMem := FMem;
    vMem := MpoolGet(AN);
    vMem.Incref;
    vMem.Incref;
    FMem := vMem;
    FFrozenSeq := FSeq;
    Result := vMem;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

procedure TDB.GetMems(out AE, AF: TMemDBWrapper);
begin
  EnterCriticalSection(FMemMu);
  try
    if FMem <> nil then
      FMem.Incref
    else if not IsClosed then
      raise Exception.Create('nil effective mem');
    if FFrozenMem <> nil then
      FFrozenMem.Incref;
    AE := FMem;
    AF := FFrozenMem;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

function TDB.GetEffectiveMem: TMemDBWrapper;
begin
  EnterCriticalSection(FMemMu);
  try
    if FMem <> nil then
      FMem.Incref
    else if not IsClosed then
      raise Exception.Create('nil effective mem');
    Result := FMem;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

function TDB.HasFrozenMem: Boolean;
begin
  EnterCriticalSection(FMemMu);
  try
    Result := FFrozenMem <> nil;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

function TDB.GetFrozenMem: TMemDBWrapper;
begin
  EnterCriticalSection(FMemMu);
  try
    if FFrozenMem <> nil then
      FFrozenMem.Incref;
    Result := FFrozenMem;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

procedure TDB.DropFrozenMem;
var
  vErr: Exception;
begin
  EnterCriticalSection(FMemMu);
  try
    vErr := FS.Stor.Remove(FFrozenJournalFd);
    if vErr <> nil then
      LogF('journal@remove removing @%d %s', [FFrozenJournalFd.Num, vErr.Message])
    else
      LogF('journal@remove removed @%d', [FFrozenJournalFd.Num]);
    FFrozenJournalFd := TFileDesc.Create(TFileType.TypeInvalid, 0);
    FFrozenMem.Decref;
    FFrozenMem := nil;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

procedure TDB.ClearMems;
begin
  EnterCriticalSection(FMemMu);
  try
    FMem := nil;
    FFrozenMem := nil;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

function TDB.SetClosed: Boolean;
begin
  Result := TInterlocked.CompareExchange(FClosed, 1, 0) = 0;
end;

function TDB.IsClosed: Boolean;
begin
  Result := TInterlocked.Read(FClosed) <> 0;
end;

function TDB.Ok: Exception;
begin
  Result := nil;
  if IsClosed then
    Result := EErrClosed.Create('');
end;

end.
