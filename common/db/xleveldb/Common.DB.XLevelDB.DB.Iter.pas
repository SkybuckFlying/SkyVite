// Copyright (c) 2012, Suryandaru Triandana <syndtr@gmail.com>
// All rights reserved.
//
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
unit Common.Db.XLevelDB.DB.Iter;

interface

uses
  Common.DB.XLevelDB.Batch,
  Common.DB.XLevelDB.Comparer,
  Common.Db.XLevelDB.DB,
  Common.DB.XLevelDB.DB.Compaction,
  Common.DB.XLevelDB.DB.Snapshot,
  Common.DB.XLevelDB.DB.State,
  Common.DB.XLevelDB.DB.Transaction,
  Common.DB.XLevelDB.DB.Util,
  Common.DB.XLevelDB.DB.Write,
  Common.DB.XLevelDB.Doc,
  Common.Db.XLevelDB.Errors,
  Common.DB.XLevelDB.Filter,
  Common.Db.XLevelDB.Iterator,
  Common.Db.XLevelDB.Key,
  Common.Db.XLevelDB.MemDB,
  Common.Db.XLevelDB.Opt,
  Common.DB.XLevelDB.Options,
  Common.Db.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.Db.XLevelDB.Util,
  Common.DB.XLevelDB.Version,
  GoToDelphi.Helpers.TChannel,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils;

type
  EErrInvalidInternalKey = class(Exception);

  TMemdbReleaser = class(TInterfacedObject, IReleaser)
  private
    FOnce: TOnce;
    FM: TMemDB;
  public
    constructor Create(AM: TMemDB);
    procedure Release;
  end;

  TDir = (dirReleased = -1, dirSOI, dirEOI, dirBackward, dirForward);

  // dbIter represent an interator states over a database session.
  TDbIter = class(TInterfacedObject, IIterator)
  private
    FDb: TDB;
    FIcmp: IComparer;
    FIter: IIterator;
    FSeq: UInt64;
    FStrict: Boolean;
    FSamplingGap: Integer;
    FDir: TDir;
    FKey: TBytes;
    FValue: TBytes;
    FErr: Exception;
    FReleaser: IReleaser;
    procedure SampleSeek;
    procedure SetErr(AErr: Exception);
    procedure IterErr;
    function InternalNext: Boolean;
    function InternalPrev: Boolean;
  public
    constructor Create(ADB: TDB; AIcmp: IComparer; AIter: IIterator; ASeq: UInt64; AStrict: Boolean);
    destructor Destroy; override;
    function Valid: Boolean;
    function First: Boolean;
    function Last: Boolean;
    function Seek(AKey: TBytes): Boolean;
    function Next: Boolean;
    function Prev: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    procedure Release;
    procedure SetReleaser(AReleaser: IReleaser);
    function Error: Exception;
  end;

implementation

{ TMemdbReleaser }

constructor TMemdbReleaser.Create(AM: TMemDB);
begin
  inherited Create;
  FM := AM;
end;

procedure TMemdbReleaser.Release;
begin
  TInterlocked.Exchange(FM, nil);
end;

{ TDbIter }

constructor TDbIter.Create(ADB: TDB; AIcmp: IComparer; AIter: IIterator; ASeq: UInt64; AStrict: Boolean);
begin
  inherited Create;
  FDb := ADB;
  FIcmp := AIcmp;
  FIter := AIter;
  FSeq := ASeq;
  FStrict := AStrict;
  TInterlocked.Increment(FDb.FAliveIters);
end;

destructor TDbIter.Destroy;
begin
  Release;
  inherited;
end;

procedure TDbIter.SampleSeek;
var
  vIkey: TBytes;
begin
  vIkey := FIter.Key;
  FSamplingGap := FSamplingGap - (Length(vIkey) + Length(FIter.Value));
  while FSamplingGap < 0 do
  begin
    FSamplingGap := FSamplingGap + FDb.IterSamplingRate;
    FDb.SampleSeek(vIkey);
  end;
end;

procedure TDbIter.SetErr(AErr: Exception);
begin
  FErr := AErr;
  FKey := nil;
  FValue := nil;
end;

procedure TDbIter.IterErr;
var
  vErr: Exception;
begin
  vErr := FIter.Error;
  if vErr <> nil then
    SetErr(vErr);
end;

function TDbIter.Valid: Boolean;
begin
  Result := (FErr = nil) and (FDir > dirEOI);
end;

function TDbIter.First: Boolean;
begin
  if FErr <> nil then
    Exit(False);
  if FDir = dirReleased then
  begin
    FErr := ErrIterReleased;
    Exit(False);
  end;

  if FIter.First then
  begin
    FDir := dirSOI;
    Result := InternalNext;
  end
  else
  begin
    FDir := dirEOI;
    IterErr;
    Result := False;
  end;
end;

function TDbIter.Last: Boolean;
begin
  if FErr <> nil then
    Exit(False);
  if FDir = dirReleased then
  begin
    FErr := ErrIterReleased;
    Exit(False);
  end;

  if FIter.Last then
    Result := InternalPrev
  else
  begin
    FDir := dirSOI;
    IterErr;
    Result := False;
  end;
end;

function TDbIter.Seek(AKey: TBytes): Boolean;
var
  vIkey: TBytes;
begin
  if FErr <> nil then
    Exit(False);
  if FDir = dirReleased then
  begin
    FErr := ErrIterReleased;
    Exit(False);
  end;

  vIkey := MakeInternalKey(nil, AKey, FSeq, KeyTypeSeek);
  if FIter.Seek(vIkey) then
  begin
    FDir := dirSOI;
    Result := InternalNext;
  end
  else
  begin
    FDir := dirEOI;
    IterErr;
    Result := False;
  end;
end;

function TDbIter.InternalNext: Boolean;
var
  vUkey: TBytes;
  vSeq: UInt64;
  vKt: TKeyType;
  vKerr: Exception;
begin
  Result := False;
  while True do
  begin
    vKerr := ParseInternalKey(FIter.Key, vUkey, vSeq, vKt);
    if vKerr = nil then
    begin
      SampleSeek;
      if vSeq <= FSeq then
      begin
        case vKt of
          KeyTypeDel:
            begin
              FKey := Copy(vUkey);
              FDir := dirForward;
            end;
          KeyTypeVal:
            begin
              if (FDir = dirSOI) or (FIcmp.UCompare(vUkey, FKey) > 0) then
              begin
                FKey := Copy(vUkey);
                FValue := Copy(FIter.Value);
                FDir := dirForward;
                Result := True;
                Exit;
              end;
            end;
        end;
      end;
    end
    else if FStrict then
    begin
      SetErr(vKerr);
      Break;
    end;
    if not FIter.Next then
    begin
      FDir := dirEOI;
      IterErr;
      Break;
    end;
  end;
end;

function TDbIter.Next: Boolean;
begin
  if (FDir = dirEOI) or (FErr <> nil) then
    Exit(False);
  if FDir = dirReleased then
  begin
    FErr := ErrIterReleased;
    Exit(False);
  end;

  if not FIter.Next or ((FDir = dirBackward) and not FIter.Next) then
  begin
    FDir := dirEOI;
    IterErr;
    Result := False;
    Exit;
  end;
  Result := InternalNext;
end;

function TDbIter.InternalPrev: Boolean;
var
  vDel: Boolean;
  vUkey: TBytes;
  vSeq: UInt64;
  vKt: TKeyType;
  vKerr: Exception;
begin
  FDir := dirBackward;
  vDel := True;
  if FIter.Valid then
  begin
    while True do
    begin
      vKerr := ParseInternalKey(FIter.Key, vUkey, vSeq, vKt);
      if vKerr = nil then
      begin
        SampleSeek;
        if vSeq <= FSeq then
        begin
          if not vDel and (FIcmp.UCompare(vUkey, FKey) < 0) then
          begin
            Result := True;
            Exit;
          end;
          vDel := (vKt = KeyTypeDel);
          if not vDel then
          begin
            FKey := Copy(vUkey);
            FValue := Copy(FIter.Value);
          end;
        end;
      end
      else if FStrict then
      begin
        SetErr(vKerr);
        Result := False;
        Exit;
      end;
      if not FIter.Prev then
        Break;
    end;
  end;
  if vDel then
  begin
    FDir := dirSOI;
    IterErr;
    Result := False;
    Exit;
  end;
  Result := True;
end;

function TDbIter.Prev: Boolean;
var
  vUkey: TBytes;
  vKerr: Exception;
begin
  if (FDir = dirSOI) or (FErr <> nil) then
    Exit(False);
  if FDir = dirReleased then
  begin
    FErr := ErrIterReleased;
    Exit(False);
  end;

  case FDir of
    dirEOI:
      Result := Last;
    dirForward:
      begin
        while FIter.Prev do
        begin
          vKerr := ParseInternalKey(FIter.Key, vUkey, nil, nil);
          if vKerr = nil then
          begin
            SampleSeek;
            if FIcmp.UCompare(vUkey, FKey) < 0 then
            begin
              Result := InternalPrev;
              Exit;
            end;
          end
          else if FStrict then
          begin
            SetErr(vKerr);
            Result := False;
            Exit;
          end;
        end;
        FDir := dirSOI;
        IterErr;
        Result := False;
      end;
  else
    Result := InternalPrev;
  end;
end;

function TDbIter.Key: TBytes;
begin
  if (FErr <> nil) or (FDir <= dirEOI) then
    Result := nil
  else
    Result := FKey;
end;

function TDbIter.Value: TBytes;
begin
  if (FErr <> nil) or (FDir <= dirEOI) then
    Result := nil
  else
    Result := FValue;
end;

procedure TDbIter.Release;
begin
  if FDir <> dirReleased then
  begin
    if FReleaser <> nil then
    begin
      FReleaser.Release;
      FReleaser := nil;
    end;

    FDir := dirReleased;
    FKey := nil;
    FValue := nil;
    FIter.Release;
    FIter := nil;
    TInterlocked.Decrement(FDb.FAliveIters);
    FDb := nil;
  end;
end;

procedure TDbIter.SetReleaser(AReleaser: IReleaser);
begin
  if FDir = dirReleased then
    raise EErrReleased.Create('');
  if (FReleaser <> nil) and (AReleaser <> nil) then
    raise EErrHasReleaser.Create('');
  FReleaser := AReleaser;
end;

function TDbIter.Error: Exception;
begin
  Result := FErr;
end;

end.
