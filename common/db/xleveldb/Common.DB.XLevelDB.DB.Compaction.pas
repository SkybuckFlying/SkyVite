// Copyright (c) 2012, Suryandaru Triandana <syndtr@gmail.com>
// All rights reserved.
//
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
unit Common.Db.XLevelDB.DB.Compaction;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  GoToDelphi.Helpers.TChannel,
  Common.Db.XLevelDB.Errors,
  Common.Db.XLevelDB.Opt,
  Common.Db.XLevelDB.Storage,
  Common.Db.XLevelDB.DB;

type
  EErrCompactionTransactExiting = class(Exception);

  TCStat = record
    Duration: TTimeSpan;
    Read, Write: Int64;
    procedure Add(const AStat: TCStatStaging);
    procedure Get(out ADuration: TTimeSpan; out ARead, AWrite: Int64);
  end;

  TCStatStaging = record
    Start: TDateTime;
    Duration: TTimeSpan;
    On: Boolean;
    Read, Write: Int64;
    procedure StartTimer;
    procedure StopTimer;
  end;

  TCStats = class
  private
    FLock: TCriticalSection;
    FStats: TArray<TCStat>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddStat(ALevel: Integer; const AStat: TCStatStaging);
    procedure GetStat(ALevel: Integer; out ADuration: TTimeSpan; out ARead, AWrite: Int64);
  end;

  TCompactionTransactCounter = Integer;

  ICompactionTransact = interface
    ['{B4B0E0A0-6B8A-4A6B-8E8E-0E0B4B0E0A00}']
    function Run(var ACnt: TCompactionTransactCounter): Exception;
    function Revert: Exception;
  end;

  TTableCompactionBuilder = class(TInterfacedObject, ICompactionTransact)
  private
    FDB: TDB;
    FS: TSession;
    FC: TCompaction;
    FRec: TSessionRecord;
    FStat0, FStat1: TCStatStaging;
    FSnapHasLastUkey: Boolean;
    FSnapLastUkey: TBytes;
    FSnapLastSeq: UInt64;
    FSnapIter: Integer;
    FSnapKerrCnt: Integer;
    FSnapDropCnt: Integer;
    FKerrCnt: Integer;
    FDropCnt: Integer;
    FMinSeq: UInt64;
    FStrict: Boolean;
    FTableSize: Integer;
    FTw: TTableWriter;
    procedure AppendKV(AKey, AValue: TBytes);
    function NeedFlush: Boolean;
    function Flush: Exception;
    procedure Cleanup;
  public
    constructor Create(ADB: TDB; AS: TSession; AC: TCompaction; ARec: TSessionRecord;
      AStat1: TCStatStaging; AMinSeq: UInt64; AStrict: Boolean; ATableSize: Integer);
    destructor Destroy; override;
    function Run(var ACnt: TCompactionTransactCounter): Exception;
    function Revert: Exception;
  end;

procedure CompactionError(ADB: TDB);
procedure CompactionTransact(ADB: TDB; const AName: string; ATransact: ICompactionTransact);
procedure MemCompaction(ADB: TDB);
procedure TableCompaction(ADB: TDB; AC: TCompaction; ANoTrivial: Boolean);
procedure TableRangeCompaction(ADB: TDB; ALevel: Integer; AUmin, AUmax: TBytes);
procedure TableAutoCompaction(ADB: TDB);
function TableNeedCompaction(ADB: TDB): Boolean;
procedure PauseCompaction(ADB: TDB; ACh: TChannel<Boolean>);
procedure MCompaction(ADB: TDB);
procedure TCompaction(ADB: TDB);

implementation

{ TCStat }

procedure TCStat.Add(const AStat: TCStatStaging);
begin
  Duration := Duration + AStat.Duration;
  Read := Read + AStat.Read;
  Write := Write + AStat.Write;
end;

procedure TCStat.Get(out ADuration: TTimeSpan; out ARead, AWrite: Int64);
begin
  ADuration := Duration;
  ARead := Read;
  AWrite := Write;
end;

{ TCStatStaging }

procedure TCStatStaging.StartTimer;
begin
  if not On then
  begin
    Start := Now;
    On := True;
  end;
end;

procedure TCStatStaging.StopTimer;
begin
  if On then
  begin
    Duration := Duration + (Now - Start);
    On := False;
  end;
end;

{ TCStats }

constructor TCStats.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
end;

destructor TCStats.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TCStats.AddStat(ALevel: Integer; const AStat: TCStatStaging);
begin
  FLock.Enter;
  try
    if ALevel >= Length(FStats) then
      SetLength(FStats, ALevel + 1);
    FStats[ALevel].Add(AStat);
  finally
    FLock.Leave;
  end;
end;

procedure TCStats.GetStat(ALevel: Integer; out ADuration: TTimeSpan; out ARead, AWrite: Int64);
begin
  FLock.Enter;
  try
    if ALevel < Length(FStats) then
      FStats[ALevel].Get(ADuration, ARead, AWrite)
    else
    begin
      ADuration := 0;
      ARead := 0;
      AWrite := 0;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure CompactionError(ADB: TDB);
var
  vErr: Exception;
begin
  while True do
  begin
    try
      vErr := ADB.FCompErrSetC.Receive;
      if vErr = nil then
        Continue;
      if (vErr is EReadOnly) or IsCorrupted(vErr) then
        Break;
      while True do
      begin
        TChannel.Select([ADB.FCompErrC, ADB.FCompErrSetC, ADB.FCloseC],
          procedure(c: TChannel; val: TValue)
          begin
            if c = ADB.FCompErrC then
              ADB.FCompErrC.Send(vErr)
            else if c = ADB.FCompErrSetC then
            begin
              vErr := val.AsType<Exception>;
              if vErr = nil then
                raise EAbort.Create('');
              if (vErr is EReadOnly) or IsCorrupted(vErr) then
                raise EAbort.Create('');
            end
            else if c = ADB.FCloseC then
              raise EAbort.Create('');
          end);
      end;
    except
      on E: EAbort do
        Break;
    end;
  end;
end;

procedure CompactionTransact(ADB: TDB; const AName: string; ATransact: ICompactionTransact);
const
  BackoffMin = 1000;
  BackoffMax = 8000;
  BackoffMul = 2000;
var
  vBackoff: Integer;
  vLastCnt: TCompactionTransactCounter;
  vDisableBackoff: Boolean;
  vN: Integer;
  vCnt: TCompactionTransactCounter;
  vErr: Exception;
  vPerr: Exception;
begin
  vBackoff := BackoffMin;
  vLastCnt := 0;
  vDisableBackoff := ADB.FS.Options.GetDisableCompactionBackoff;
  vN := 0;
  while True do
  begin
    if ADB.IsClosed then
    begin
      ADB.LogF('%s exiting', [AName]);
      raise EErrCompactionTransactExiting.Create('');
    end
    else if vN > 0 then
      ADB.LogF('%s retrying N·%d', [AName, vN]);

    vCnt := 0;
    vErr := ATransact.Run(vCnt);
    if vErr <> nil then
      ADB.LogF('%s error I·%d %q', [AName, vCnt, vErr.Message]);

    TChannel.Select([ADB.FCompErrSetC, ADB.FCompPerErrC, ADB.FCloseC],
      procedure(c: TChannel; val: TValue)
      begin
        if c = ADB.FCompErrSetC then
          ADB.FCompErrSetC.Send(vErr)
        else if c = ADB.FCompPerErrC then
        begin
          vPerr := val.AsType<Exception>;
          if vErr <> nil then
          begin
            ADB.LogF('%s exiting (persistent error %q)', [AName, vPerr.Message]);
            raise EErrCompactionTransactExiting.Create('');
          end;
        end
        else if c = ADB.FCloseC then
        begin
          ADB.LogF('%s exiting', [AName]);
          raise EErrCompactionTransactExiting.Create('');
        end;
      end);

    if vErr = nil then
      Exit;
    if IsCorrupted(vErr) then
    begin
      ADB.LogF('%s exiting (corruption detected)', [AName]);
      raise EErrCompactionTransactExiting.Create('');
    end;

    if not vDisableBackoff then
    begin
      if vCnt > vLastCnt then
      begin
        vBackoff := BackoffMin;
        vLastCnt := vCnt;
      end;

      Sleep(vBackoff);
      if vBackoff < BackoffMax then
      begin
        vBackoff := vBackoff * BackoffMul;
        if vBackoff > BackoffMax then
          vBackoff := BackoffMax;
      end;
    end;
    Inc(vN);
  end;
end;

procedure MemCompaction(ADB: TDB);
var
  vMdb: TMemDB;
  vResumeC: TChannel<Boolean>;
  vRec: TSessionRecord;
  vStats: TCStatStaging;
  vFlushLevel: Integer;
  vErr: Exception;
  vR: TTableRecord;
begin
  vMdb := ADB.GetFrozenMem;
  if vMdb = nil then
    Exit;
  try
    ADB.LogF('memdb@flush N·%d S·%s', [vMdb.Len, ShortenB(vMdb.Size)]);

    if vMdb.Len = 0 then
    begin
      ADB.LogF('memdb@flush skipping');
      ADB.DropFrozenMem;
      Exit;
    end;

    vResumeC := TChannel<Boolean>.Create;
    try
      TChannel.Select([ADB.FTCompPauseC, ADB.FCompPerErrC, ADB.FCloseC],
        procedure(c: TChannel; val: TValue)
        begin
          if c = ADB.FTCompPauseC then
            ADB.FTCompPauseC.Send(vResumeC)
          else if c = ADB.FCompPerErrC then
          begin
            vResumeC.Close;
            vResumeC := nil;
          end
          else if c = ADB.FCloseC then
            raise EErrCompactionTransactExiting.Create('');
        end);

      vRec := TSessionRecord.Create;
      try
        vStats.StartTimer;
        CompactionTransact(ADB, 'memdb@flush',
          TCompactionTransactFunc.Create(
            function(var ACnt: TCompactionTransactCounter): Exception
            begin
              vStats.StartTimer;
              Result := ADB.FS.FlushMemdb(vRec, vMdb, ADB.FMemDBMaxLevel, vFlushLevel);
              vStats.StopTimer;
            end,
            function: Exception
            var
              vR: TTableRecord;
            begin
              for vR in vRec.AddedTables do
              begin
                ADB.LogF('memdb@flush revert @%d', [vR.Num]);
                Result := ADB.FS.stor.Remove(TFileDesc.Create(TFileType.TypeTable, vR.Num));
                if Result <> nil then
                  Exit;
              end;
              Result := nil;
            end));
        vStats.StopTimer;

        vRec.SetJournalNum(ADB.FJournalFd.Num);
        vRec.SetSeqNum(ADB.FFrozenSeq);

        vStats.StartTimer;
        CompactionTransact(ADB, 'memdb@commit',
          TCompactionTransactFunc.Create(
            function(var ACnt: TCompactionTransactCounter): Exception
            begin
              Result := ADB.FS.Commit(vRec);
            end, nil));
        vStats.StopTimer;

        ADB.LogF('memdb@flush committed F·%d T·%v', [Length(vRec.AddedTables), vStats.Duration]);

        for vR in vRec.AddedTables do
          vStats.Write := vStats.Write + vR.Size;
        ADB.FCompStats.AddStat(vFlushLevel, vStats);

        ADB.DropFrozenMem;

        if vResumeC <> nil then
        begin
          TChannel.Select([vResumeC, ADB.FCloseC],
            procedure(c: TChannel; val: TValue)
            begin
              if c = vResumeC then
                vResumeC.Close
              else if c = ADB.FCloseC then
                raise EErrCompactionTransactExiting.Create('');
            end);
        end;

        ADB.CompTrigger(ADB.FTCompCmdC);
      finally
        vRec.Free;
      end;
    finally
      vResumeC.Free;
    end;
  finally
    vMdb.Decref;
  end;
end;

{ TTableCompactionBuilder }

constructor TTableCompactionBuilder.Create(ADB: TDB; AS: TSession; AC: TCompaction; ARec: TSessionRecord;
  AStat1: TCStatStaging; AMinSeq: UInt64; AStrict: Boolean; ATableSize: Integer);
begin
  inherited Create;
  FDB := ADB;
  FS := AS;
  FC := AC;
  FRec := ARec;
  FStat1 := AStat1;
  FMinSeq := AMinSeq;
  FStrict := AStrict;
  FTableSize := ATableSize;
end;

destructor TTableCompactionBuilder.Destroy;
begin
  Cleanup;
  inherited;
end;

procedure TTableCompactionBuilder.AppendKV(AKey, AValue: TBytes);
var
  vErr: Exception;
begin
  if FTw = nil then
  begin
    if FDB <> nil then
    begin
      TChannel.Select([FDB.FTCompPauseC, FDB.FCloseC],
        procedure(c: TChannel; val: TValue)
        begin
          if c = FDB.FTCompPauseC then
            FDB.PauseCompaction(val.AsType<TChannel<Boolean>>)
          else if c = FDB.FCloseC then
            raise EErrCompactionTransactExiting.Create('');
        end, False);
    end;

    FTw := FS.tops.Create(vErr);
    if vErr <> nil then
      raise vErr;
  end;
  vErr := FTw.Append(AKey, AValue);
  if vErr <> nil then
    raise vErr;
end;

function TTableCompactionBuilder.NeedFlush: Boolean;
begin
  Result := FTw.Tw.BytesLen >= FTableSize;
end;

function TTableCompactionBuilder.Flush: Exception;
var
  vT: TTable;
begin
  vT := FTw.Finish(Result);
  if Result <> nil then
    Exit;
  FRec.AddTableFile(FC.SourceLevel + 1, vT);
  FStat1.Write := FStat1.Write + vT.Size;
  FS.LogF('table@build created L%d@%d N·%d S·%s %q:%q', [FC.SourceLevel + 1, vT.Fd.Num, FTw.Tw.EntriesLen, ShortenB(vT.Size), vT.Imin, vT.Imax]);
  FTw := nil;
end;

procedure TTableCompactionBuilder.Cleanup;
begin
  if FTw <> nil then
  begin
    FTw.Drop;
    FTw := nil;
  end;
end;

function TTableCompactionBuilder.Run(var ACnt: TCompactionTransactCounter): Exception;
var
  vSnapResumed, vHasLastUkey: Boolean;
  vLastUkey: TBytes;
  vLastSeq: UInt64;
  vIter: IIterator;
  vI: Integer;
  vResumed: Boolean;
  vIkey, vUkey: TBytes;
  vSeq: UInt64;
  vKt: TKeyType;
  vKerr: Exception;
  vShouldStop: Boolean;
begin
  vSnapResumed := FSnapIter > 0;
  vHasLastUkey := FSnapHasLastUkey;
  vLastUkey := Copy(FSnapLastUkey);
  vLastSeq := FSnapLastSeq;
  FKerrCnt := FSnapKerrCnt;
  FDropCnt := FSnapDropCnt;
  FC.Restore;

  FStat1.StartTimer;
  try
    vIter := FC.NewIterator;
    try
      vI := 0;
      while vIter.Next do
      begin
        Inc(ACnt);

        if vI < FSnapIter then
        begin
          Inc(vI);
          Continue;
        end;

        vResumed := False;
        if vSnapResumed then
        begin
          vResumed := True;
          vSnapResumed := False;
        end;

        vIkey := vIter.Key;
        vKerr := ParseInternalKey(vIkey, vSeq, @vKt, vUkey);

        if vKerr = nil then
        begin
          vShouldStop := not vResumed and FC.ShouldStopBefore(vIkey);

          if not vHasLastUkey or (FS.icmp.UCompare(vLastUkey, vUkey) <> 0) then
          begin
            if (FTw <> nil) and (vShouldStop or NeedFlush) then
            begin
              Result := Flush;
              if Result <> nil then
                Exit;

              FC.Save;
              FSnapHasLastUkey := vHasLastUkey;
              FSnapLastUkey := Copy(vLastUkey);
              FSnapLastSeq := vLastSeq;
              FSnapIter := vI;
              FSnapKerrCnt := FKerrCnt;
              FSnapDropCnt := FDropCnt;
            end;

            vHasLastUkey := True;
            vLastUkey := Copy(vUkey);
            vLastSeq := KeyMaxSeq;
          end;

          if vLastSeq <= FMinSeq then
          begin
            vLastSeq := vSeq;
            Inc(FDropCnt);
            Continue;
          end
          else if (vKt = TKeyType.KeyTypeDel) and (vSeq <= FMinSeq) and FC.BaseLevelForKey(vLastUkey) then
          begin
            vLastSeq := vSeq;
            Inc(FDropCnt);
            Continue;
          end
          else
            vLastSeq := vSeq;
        end
        else
        begin
          if FStrict then
          begin
            Result := vKerr;
            Exit;
          end;

          vHasLastUkey := False;
          SetLength(vLastUkey, 0);
          vLastSeq := KeyMaxSeq;
          Inc(FKerrCnt);
        end;

        AppendKV(vIkey, vIter.Value);
        Inc(vI);
      end;

      Result := vIter.Error;
      if Result <> nil then
        Exit;

      if (FTw <> nil) and not FTw.Empty then
        Result := Flush;
    finally
      vIter.Release;
    end;
  finally
    FStat1.StopTimer;
  end;
end;

function TTableCompactionBuilder.Revert: Exception;
var
  vAt: TTableRecord;
begin
  for vAt in FRec.AddedTables do
  begin
    FS.LogF('table@build revert @%d', [vAt.Num]);
    Result := FS.stor.Remove(TFileDesc.Create(TFileType.TypeTable, vAt.Num));
    if Result <> nil then
      Exit;
  end;
  Result := nil;
end;

procedure TableCompaction(ADB: TDB; AC: TCompaction; ANoTrivial: Boolean);
var
  vRec: TSessionRecord;
  vT: TTable;
  vStats: array[0..1] of TCStatStaging;
  vI: Integer;
  vTables: TList<TTable>;
  vSourceSize: Int64;
  vMinSeq: UInt64;
  vB: TTableCompactionBuilder;
  vResultSize: Int64;
begin
  try
    vRec := TSessionRecord.Create;
    try
      vRec.AddCompPtr(AC.SourceLevel, AC.Imax);

      if not ANoTrivial and AC.Trivial then
      begin
        vT := AC.Levels[0][0];
        ADB.LogF('table@move L%d@%d -> L%d', [AC.SourceLevel, vT.Fd.Num, AC.SourceLevel + 1]);
        vRec.DelTable(AC.SourceLevel, vT.Fd.Num);
        vRec.AddTableFile(AC.SourceLevel + 1, vT);
        CompactionTransact(ADB, 'table-move@commit',
          TCompactionTransactFunc.Create(
            function(var ACnt: TCompactionTransactCounter): Exception
            begin
              Result := ADB.FS.Commit(vRec);
            end, nil));
        Exit;
      end;

      vSourceSize := 0;
      for vI := 0 to High(AC.Levels) do
      begin
        vTables := AC.Levels[vI];
        for vT in vTables do
        begin
          vStats[vI].Read := vStats[vI].Read + vT.Size;
          vRec.DelTable(AC.SourceLevel + vI, vT.Fd.Num);
        end;
        vSourceSize := vSourceSize + vStats[vI].Read;
      end;
      vMinSeq := ADB.MinSeq;
      ADB.LogF('table@compaction L%d·%d -> L%d·%d S·%s Q·%d', [AC.SourceLevel, Length(AC.Levels[0]), AC.SourceLevel + 1, Length(AC.Levels[1]), ShortenB(vSourceSize), vMinSeq]);

      vB := TTableCompactionBuilder.Create(ADB, ADB.FS, AC, vRec, vStats[1], vMinSeq,
        ADB.FS.Options.GetStrict(TStrict.StrictCompaction), ADB.FS.Options.GetCompactionTableSize(AC.SourceLevel + 1));
      try
        CompactionTransact(ADB, 'table@build', vB);
      finally
        vB.Free;
      end;

      vStats[1].StartTimer;
      CompactionTransact(ADB, 'table@commit',
        TCompactionTransactFunc.Create(
          function(var ACnt: TCompactionTransactCounter): Exception
          begin
            Result := ADB.FS.Commit(vRec);
          end, nil));
      vStats[1].StopTimer;

      vResultSize := vStats[1].Write;
      ADB.LogF('table@compaction committed F%s S%s Ke·%d D·%d T·%v', [IntToStr(Length(vRec.AddedTables) - Length(vRec.DeletedTables)),
        ShortenB(vResultSize - vSourceSize), vB.FKerrCnt, vB.FDropCnt, vStats[1].Duration]);

      for vI := 0 to High(vStats) do
        ADB.FCompStats.AddStat(AC.SourceLevel + 1, vStats[vI]);
    finally
      vRec.Free;
    end;
  finally
    AC.Release;
  end;
end;

procedure TableRangeCompaction(ADB: TDB; ALevel: Integer; AUmin, AUmax: TBytes);
var
  vC: TCompaction;
  vCompacted: Boolean;
  vV: TVersion;
  vM, vI: Integer;
  vTables: TList<TTable>;
begin
  ADB.LogF('table@compaction range L%d %q:%q', [ALevel, AUmin, AUmax]);
  if ALevel >= 0 then
  begin
    vC := ADB.FS.GetCompactionRange(ALevel, AUmin, AUmax, True);
    if vC <> nil then
      TableCompaction(ADB, vC, True);
  end
  else
  begin
    while True do
    begin
      vCompacted := False;

      vV := ADB.FS.Version;
      try
        vM := 1;
        for vI := vM to vV.Levels.Count - 1 do
        begin
          vTables := vV.Levels[vI];
          if vTables.Overlaps(ADB.FS.icmp, AUmin, AUmax, False) then
            vM := vI;
        end;
      finally
        vV.Release;
      end;

      for vI := 0 to vM - 1 do
      begin
        vC := ADB.FS.GetCompactionRange(vI, AUmin, AUmax, False);
        if vC <> nil then
        begin
          TableCompaction(ADB, vC, True);
          vCompacted := True;
        end;
      end;

      if not vCompacted then
        Break;
    end;
  end;
end;

procedure TableAutoCompaction(ADB: TDB);
var
  vC: TCompaction;
begin
  vC := ADB.FS.PickCompaction;
  if vC <> nil then
    TableCompaction(ADB, vC, False);
end;

function TableNeedCompaction(ADB: TDB): Boolean;
var
  vV: TVersion;
begin
  vV := ADB.FS.Version;
  try
    Result := vV.NeedCompaction;
  finally
    vV.Release;
  end;
end;

procedure PauseCompaction(ADB: TDB; ACh: TChannel<Boolean>);
begin
  TChannel.Select([ACh, ADB.FCloseC],
    procedure(c: TChannel; val: TValue)
    begin
      if c = ACh then
        ACh.Send(True)
      else if c = ADB.FCloseC then
        raise EErrCompactionTransactExiting.Create('');
    end);
end;

procedure MCompaction(ADB: TDB);
var
  vX: ICCmd;
begin
  try
    while True do
    begin
      vX := ADB.FMCompCmdC.Receive;
      if vX is TCAuto then
      begin
        MemCompaction(ADB);
        vX.ack(nil);
        vX := nil;
      end
      else
        raise Exception.Create('leveldb: unknown command');
    end;
  except
    on E: EErrCompactionTransactExiting do
    begin
      if vX <> nil then
        vX.ack(EClosed.Create);
    end;
  end;
  ADB.FCloseW.Done;
end;

procedure TCompaction(ADB: TDB);
var
  vX: ICCmd;
  vAckQ: TList<ICCmd>;
  vI: Integer;
  vCh: TChannel<Boolean>;
  vCmd: ICCmd;
begin
  vAckQ := TList<ICCmd>.Create;
  try
    while True do
    begin
      if TableNeedCompaction(ADB) then
      begin
        TChannel.Select([ADB.FTCompCmdC, ADB.FTCompPauseC, ADB.FCloseC],
          procedure(c: TChannel; val: TValue)
          begin
            if c = ADB.FTCompCmdC then
              vX := val.AsType<ICCmd>
            else if c = ADB.FTCompPauseC then
            begin
              vCh := val.AsType<TChannel<Boolean>>;
              PauseCompaction(ADB, vCh);
              Continue;
            end
            else if c = ADB.FCloseC then
              Exit;
          end, False);
      end
      else
      begin
        for vI := 0 to vAckQ.Count - 1 do
        begin
          vAckQ[vI].ack(nil);
          vAckQ[vI] := nil;
        end;
        vAckQ.Clear;
        TChannel.Select([ADB.FTCompCmdC, ADB.FTCompPauseC, ADB.FCloseC],
          procedure(c: TChannel; val: TValue)
          begin
            if c = ADB.FTCompCmdC then
              vX := val.AsType<ICCmd>
            else if c = ADB.FTCompPauseC then
            begin
              vCh := val.AsType<TChannel<Boolean>>;
              PauseCompaction(ADB, vCh);
              Continue;
            end
            else if c = ADB.FCloseC then
              Exit;
          end);
      end;

      if vX <> nil then
      begin
        vCmd := vX;
        if vCmd is TCAuto then
          vAckQ.Add(vCmd)
        else if vCmd is TCRange then
          vCmd.ack(TableRangeCompaction(ADB, (vCmd as TCRange).Level, (vCmd as TCRange).Min, (vCmd as TCRange).Max))
        else
          raise Exception.Create('leveldb: unknown command');
        vX := nil;
      end;
      TableAutoCompaction(ADB);
    end;
  except
    on E: EErrCompactionTransactExiting do
    begin
      for vI := 0 to vAckQ.Count - 1 do
        vAckQ[vI].ack(EClosed.Create);
      if vX <> nil then
        vX.ack(EClosed.Create);
    end;
  end;
  ADB.FCloseW.Done;
end;

end.