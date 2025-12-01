unit Common.Db.Xleveldb.Memdb.Memdb;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Defaults,
  Common.Db.Xleveldb.Comparer,
  Common.Db.Xleveldb.Errors,
  Common.Db.Xleveldb.Iterator,
  Common.Db.Xleveldb.Util;

const
  tMaxHeight = 12;

  // Node data offsets.
  nKV = 0;
  nKey = 1;
  nVal = 2;
  nHeight = 3;
  nNext = 4;

type
  TDB = class; // Forward declaration

  TDBIter = class(TInterfacedObject, IIterator)
  private
    mBasicReleaser: TBasicReleaser;
    mDB: TDB;
    mSlice: PRange;
    mNode: Integer;
    mForward: Boolean;
    mKey, mValue: TBytes;
    mErr: Exception;
    function Fill(ParaCheckStart, ParaCheckLimit: Boolean): Boolean;
  public
    constructor Create(ParaDB: TDB; ParaSlice: PRange);
    destructor Destroy; override;
    procedure Release;
    function Valid: Boolean;
    function First: Boolean;
    function Last: Boolean;
    function Seek(const ParaKey: TBytes): Boolean;
    function Next: Boolean;
    function Prev: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    function Error: Exception;
    procedure SetReleaser(ParaReleaser: IReleaser);
  end;

  TDB = class
  private
    mCmp: IBasicComparer;
    mRnd: TRandom;
    mRndMu: TCriticalSection;
    mKVData: TBytes;
    mNodeData: TArray<Integer>;
    mPrevNode: array [0 .. tMaxHeight - 1] of Integer;
    mMaxHeight: Integer;
    mN: Integer;
    mKVSize: Integer;
    function RandHeight: Integer;
    function FindGE(const ParaKey: TBytes; ParaPrev: Boolean; out ParaExact: Boolean): Integer;
    function FindLT(const ParaKey: TBytes): Integer;
    function FindLast: Integer;
    function CopyInternal(ParaNewDB: TDB): TDB;
  public
    constructor Create(ParaCmp: IBasicComparer; ParaCapacity: Integer; ParaUseGlobalRnd: Boolean = False);
    destructor Destroy; override;
    function Copy: TDB;
    function Copy2(ParaBytesGetter: TFunc<Integer, TBytes>; ParaIntGetter: TFunc<Integer, TArray<Integer>>): TDB;
    procedure Destroy2(ParaPutter: TProc<TObject>);
    procedure Put(const ParaKey, ParaValue: TBytes);
    procedure Delete(const ParaKey: TBytes);
    function Contains(const ParaKey: TBytes): Boolean;
    function Get(const ParaKey: TBytes; out ParaValue: TBytes): Boolean;
    function Find(const ParaKey: TBytes; out ParaRKey, ParaValue: TBytes): Boolean;
    function NewIterator(ParaSlice: PRange): IIterator;
    function Capacity: Integer;
    function Size: Integer;
    function Free: Integer;
    function Len: Integer;
    procedure Reset;
    procedure AcquireLock;
    procedure ReleaseLock;
    function GetNodeData(ParaIndex: Integer): Integer;
    function GetKVData: TBytes;
  end;

function New(ParaCmp: IBasicComparer; ParaCapacity: Integer): TDB;
function New2(ParaCmp: IBasicComparer; ParaCapacity: Integer): TDB;

implementation

var
  gGlobalRnd: TRandom;
  gGlobalRndMu: TCriticalSection;

{ TDBIter }

constructor TDBIter.Create(ParaDB: TDB; ParaSlice: PRange);
begin
  inherited Create;
  mBasicReleaser := TBasicReleaser.Create;
  mDB := ParaDB;
  mSlice := ParaSlice;
end;

destructor TDBIter.Destroy;
begin
  mBasicReleaser.Free;
  inherited Destroy;
end;

procedure TDBIter.Release;
begin
  if not mBasicReleaser.Released then
  begin
    mDB := nil;
    mNode := 0;
    mKey := nil;
    mValue := nil;
    mBasicReleaser.Release;
  end;
end;

function TDBIter.Fill(ParaCheckStart, ParaCheckLimit: Boolean): Boolean;
var
  vN, vM: Integer;
  vKVData: TBytes;
begin
  Result := False;
  if mNode <> 0 then
  begin
    vKVData := mDB.GetKVData;
    vN := mDB.GetNodeData(mNode + nKV);
    vM := vN + mDB.GetNodeData(mNode + nKey);
    SetLength(mKey, vM - vN);
    System.Move(vKVData[vN], mKey[0], vM - vN);

    if mSlice <> nil then
    begin
      if ParaCheckLimit and (mSlice.Limit <> nil) and (mDB.mCmp.Compare(mKey, mSlice.Limit) >= 0) then
      begin
        mNode := 0;
        GoTo Bail;
      end;
      if ParaCheckStart and (mSlice.Start <> nil) and (mDB.mCmp.Compare(mKey, mSlice.Start) < 0) then
      begin
        mNode := 0;
        GoTo Bail;
      end;
    end;

    SetLength(mValue, mDB.GetNodeData(mNode + nVal));
    System.Move(vKVData[vM], mValue[0], Length(mValue));
    Result := True;
    Exit;
  end;

Bail:
  mKey := nil;
  mValue := nil;
end;

function TDBIter.Valid: Boolean;
begin
  Result := mNode <> 0;
end;

function TDBIter.First: Boolean;
var
  vExact: Boolean;
begin
  if mBasicReleaser.Released then
  begin
    mErr := EReleased.Create('leveldb/memdb: iterator released');
    Result := False;
    Exit;
  end;

  mForward := True;
  mDB.AcquireLock;
  try
    if (mSlice <> nil) and (mSlice.Start <> nil) then
    begin
      mNode := mDB.FindGE(mSlice.Start, False, vExact)
    end
    else
    begin
      mNode := mDB.GetNodeData(nNext);
    end;
    Result := Fill(False, True);
  finally
    mDB.ReleaseLock;
  end;
end;

function TDBIter.Last: Boolean;
begin
  if mBasicReleaser.Released then
  begin
    mErr := EReleased.Create('leveldb/memdb: iterator released');
    Result := False;
    Exit;
  end;

  mForward := False;
  mDB.AcquireLock;
  try
    if (mSlice <> nil) and (mSlice.Limit <> nil) then
    begin
      mNode := mDB.FindLT(mSlice.Limit)
    end
    else
    begin
      mNode := mDB.FindLast;
    end;
    Result := Fill(True, False);
  finally
    mDB.ReleaseLock;
  end;
end;

function TDBIter.Seek(const ParaKey: TBytes): Boolean;
var
  vExact: Boolean;
  vSeekKey: TBytes;
begin
  if mBasicReleaser.Released then
  begin
    mErr := EReleased.Create('leveldb/memdb: iterator released');
    Result := False;
    Exit;
  end;

  mForward := True;
  mDB.AcquireLock;
  try
    vSeekKey := ParaKey;
    if (mSlice <> nil) and (mSlice.Start <> nil) and (mDB.mCmp.Compare(ParaKey, mSlice.Start) < 0) then
    begin
      vSeekKey := mSlice.Start;
    end;
    mNode := mDB.FindGE(vSeekKey, False, vExact);
    Result := Fill(False, True);
  finally
    mDB.ReleaseLock;
  end;
end;

function TDBIter.Next: Boolean;
begin
  if mBasicReleaser.Released then
  begin
    mErr := EReleased.Create('leveldb/memdb: iterator released');
    Result := False;
    Exit;
  end;

  if mNode = 0 then
  begin
    if not mForward then
    begin
      Result := First
    end
    else
    begin
      Result := False;
    end;
    Exit;
  end;

  mForward := True;
  mDB.AcquireLock;
  try
    mNode := mDB.GetNodeData(mNode + nNext);
    Result := Fill(False, True);
  finally
    mDB.ReleaseLock;
  end;
end;

function TDBIter.Prev: Boolean;
begin
  if mBasicReleaser.Released then
  begin
    mErr := EReleased.Create('leveldb/memdb: iterator released');
    Result := False;
    Exit;
  end;

  if mNode = 0 then
  begin
    if mForward then
    begin
      Result := Last
    end
    else
    begin
      Result := False;
    end;
    Exit;
  end;

  mForward := False;
  mDB.AcquireLock;
  try
    mNode := mDB.FindLT(mKey);
    Result := Fill(True, False);
  finally
    mDB.ReleaseLock;
  end;
end;

function TDBIter.Key: TBytes;
begin
  Result := mKey;
end;

function TDBIter.Value: TBytes;
begin
  Result := mValue;
end;

function TDBIter.Error: Exception;
begin
  Result := mErr;
end;

procedure TDBIter.SetReleaser(ParaReleaser: IReleaser);
begin
  mBasicReleaser.SetReleaser(ParaReleaser);
end;

{ TDB }

constructor TDB.Create(ParaCmp: IBasicComparer; ParaCapacity: Integer; ParaUseGlobalRnd: Boolean = False);
begin
  inherited Create;
  InitializeCriticalSection(mRndMu);
  mCmp := ParaCmp;
  if ParaUseGlobalRnd then
  begin
    mRnd := gGlobalRnd;
  end
  else
  begin
    mRnd := TRandom.Create(Integer($deadbeef));
  end;
  mMaxHeight := 1;
  SetLength(mKVData, 0, ParaCapacity);
  SetLength(mNodeData, nNext + tMaxHeight);
  mNodeData[nHeight] := tMaxHeight;
end;

destructor TDB.Destroy;
begin
  if mRnd <> gGlobalRnd then
  begin
    mRnd.Free;
  end;
  DeleteCriticalSection(mRndMu);
  inherited;
end;

function TDB.RandHeight: Integer;
const
  Branching = 4;
begin
  Result := 1;
  EnterCriticalSection(mRndMu);
  try
    while (Result < tMaxHeight) and (mRnd.Next(Branching) = 0) do
    begin
      Inc(Result);
    end;
  finally
    LeaveCriticalSection(mRndMu);
  end;
end;

function TDB.FindGE(const ParaKey: TBytes; ParaPrev: Boolean; out ParaExact: Boolean): Integer;
var
  vNode, vNext, vH, vCmp, vO: Integer;
  vNodeKey: TBytes;
begin
  vNode := 0;
  vH := mMaxHeight - 1;
  ParaExact := False;
  while True do
  begin
    vNext := mNodeData[vNode + nNext + vH];
    vCmp := 1;
    if vNext <> 0 then
    begin
      vO := mNodeData[vNext + nKV];
      SetLength(vNodeKey, mNodeData[vNext + nKey]);
      System.Move(mKVData[vO], vNodeKey[0], Length(vNodeKey));
      vCmp := mCmp.Compare(vNodeKey, ParaKey);
    end;

    if vCmp < 0 then
    begin
      vNode := vNext
    end
    else
    begin
      if ParaPrev then
      begin
        mPrevNode[vH] := vNode;
      end;
      if vCmp = 0 then
      begin
        Result := vNext;
        ParaExact := True;
        Exit;
      end;
      if vH = 0 then
      begin
        Result := vNext;
        Exit;
      end;
      Dec(vH);
    end;
  end;
end;

function TDB.FindLT(const ParaKey: TBytes): Integer;
var
  vNode, vNext, vH, vO: Integer;
  vNodeKey: TBytes;
begin
  vNode := 0;
  vH := mMaxHeight - 1;
  while True do
  begin
    vNext := mNodeData[vNode + nNext + vH];
    if vNext = 0 then
    begin
      if vH = 0 then
      begin
        Break;
      end;
      Dec(vH);
    end
    else
    begin
      vO := mNodeData[vNext + nKV];
      SetLength(vNodeKey, mNodeData[vNext + nKey]);
      System.Move(mKVData[vO], vNodeKey[0], Length(vNodeKey));
      if mCmp.Compare(vNodeKey, ParaKey) >= 0 then
      begin
        if vH = 0 then
        begin
          Break;
        end;
        Dec(vH);
      end
      else
      begin
        vNode := vNext;
      end;
    end;
  end;
  Result := vNode;
end;

function TDB.FindLast: Integer;
var
  vNode, vNext, vH: Integer;
begin
  vNode := 0;
  vH := mMaxHeight - 1;
  while True do
  begin
    vNext := mNodeData[vNode + nNext + vH];
    if vNext = 0 then
    begin
      if vH = 0 then
      begin
        Break;
      end;
      Dec(vH);
    end
    else
    begin
      vNode := vNext;
    end;
  end;
  Result := vNode;
end;

function TDB.CopyInternal(ParaNewDB: TDB): TDB;
begin
  ParaNewDB.mPrevNode := mPrevNode;
  ParaNewDB.mMaxHeight := mMaxHeight;
  ParaNewDB.mN := mN;
  ParaNewDB.mKVSize := mKVSize;
  Result := ParaNewDB;
end;

function TDB.Copy: TDB;
begin
  AcquireLock;
  try
    Result := New(mCmp, Capacity);
    SetLength(Result.mKVData, Length(mKVData));
    System.Move(mKVData[0], Result.mKVData[0], Length(mKVData));
    SetLength(Result.mNodeData, Length(mNodeData));
    System.Move(mNodeData[0], Result.mNodeData[0], Length(mNodeData) * SizeOf(Integer));
    Result := CopyInternal(Result);
  finally
    ReleaseLock;
  end;
end;

function TDB.Copy2(ParaBytesGetter: TFunc<Integer, TBytes>; ParaIntGetter: TFunc<Integer, TArray<Integer>>): TDB;
var
  vIter: IIterator;
begin
  AcquireLock;
  try
    Result := New2(mCmp, 0);
    if Length(mKVData) >= Size + Trunc(0.2 * Size) then
    begin
      Result.mKVData := ParaBytesGetter(0);
      vIter := NewIterator(nil);
      while vIter.Next do
      begin
        Result.Put(vIter.Key, vIter.Value);
      end;
      vIter.Release;
    end
    else
    begin
      Result.mKVData := ParaBytesGetter(Length(mKVData));
      System.Move(mKVData[0], Result.mKVData[0], Length(mKVData));
      Result.mNodeData := ParaIntGetter(Length(mNodeData));
      System.Move(mNodeData[0], Result.mNodeData[0], Length(mNodeData) * SizeOf(Integer));
      Result := CopyInternal(Result);
    end;
  finally
    ReleaseLock;
  end;
end;

procedure TDB.Destroy2(ParaPutter: TProc<TObject>);
var
  vStream: TBytesStream;
  vIntStream: TMemoryStream;
begin
  AcquireLock;
  try
    vStream := TBytesStream.Create(mKVData);
    ParaPutter(vStream); // The receiver of the putter is responsible for freeing the stream
    vIntStream := TMemoryStream.Create;
    try
      vIntStream.Write(mNodeData[0], Length(mNodeData) * SizeOf(Integer));
      vIntStream.Position := 0;
      ParaPutter(vIntStream); // The receiver of the putter is responsible for freeing the stream
    except
      vIntStream.Free;
      raise;
    end;
  finally
    ReleaseLock;
  end;
end;

procedure TDB.Put(const ParaKey, ParaValue: TBytes);
var
  vNode, vKVOffset, vM, vH, vI, vN: Integer;
  vExact: Boolean;
begin
  AcquireLock;
  try
    vNode := FindGE(ParaKey, True, vExact);
    if vExact then
    begin
      vKVOffset := Length(mKVData);
      SetLength(mKVData, vKVOffset + Length(ParaKey) + Length(ParaValue));
      System.Move(ParaKey[0], mKVData[vKVOffset], Length(ParaKey));
      System.Move(ParaValue[0], mKVData[vKVOffset + Length(ParaKey)], Length(ParaValue));
      mNodeData[vNode + nKV] := vKVOffset;
      vM := mNodeData[vNode + nVal];
      mNodeData[vNode + nVal] := Length(ParaValue);
      Inc(mKVSize, Length(ParaValue) - vM);
      Exit;
    end;

    vH := RandHeight;
    if vH > mMaxHeight then
    begin
      for vI := mMaxHeight to vH - 1 do
      begin
        mPrevNode[vI] := 0;
      end;
      mMaxHeight := vH;
    end;

    vKVOffset := Length(mKVData);
    SetLength(mKVData, vKVOffset + Length(ParaKey) + Length(ParaValue));
    System.Move(ParaKey[0], mKVData[vKVOffset], Length(ParaKey));
    System.Move(ParaValue[0], mKVData[vKVOffset + Length(ParaKey)], Length(ParaValue));

    vNode := Length(mNodeData);
    SetLength(mNodeData, vNode + nNext + vH);
    mNodeData[vNode + nKV] := vKVOffset;
    mNodeData[vNode + nKey] := Length(ParaKey);
    mNodeData[vNode + nVal] := Length(ParaValue);
    mNodeData[vNode + nHeight] := vH;

    for vI := 0 to vH - 1 do
    begin
      vN := mPrevNode[vI];
      vM := vN + nNext + vI;
      mNodeData[vNode + nNext + vI] := mNodeData[vM];
      mNodeData[vM] := vNode;
    end;

    Inc(mKVSize, Length(ParaKey) + Length(ParaValue));
    Inc(mN);
  finally
    ReleaseLock;
  end;
end;

procedure TDB.Delete(const ParaKey: TBytes);
var
  vNode, vH, vI, vN, vM: Integer;
  vExact: Boolean;
begin
  AcquireLock;
  try
    vNode := FindGE(ParaKey, True, vExact);
    if not vExact then
    begin
      raise ENotFound.Create('leveldb/memdb: not found');
    end;

    vH := mNodeData[vNode + nHeight];
    for vI := 0 to vH - 1 do
    begin
      vN := mPrevNode[vI];
      vM := vN + nNext + vI;
      mNodeData[vM] := mNodeData[mNodeData[vM] + nNext + vI];
    end;

    Dec(mKVSize, mNodeData[vNode + nKey] + mNodeData[vNode + nVal]);
    Dec(mN);
  finally
    ReleaseLock;
  end;
end;

function TDB.Contains(const ParaKey: TBytes): Boolean;
var
  vExact: Boolean;
begin
  AcquireLock;
  try
    FindGE(ParaKey, False, vExact);
    Result := vExact;
  finally
    ReleaseLock;
  end;
end;

function TDB.Get(const ParaKey: TBytes; out ParaValue: TBytes): Boolean;
var
  vNode, vO: Integer;
  vExact: Boolean;
begin
  Result := False;
  AcquireLock;
  try
    vNode := FindGE(ParaKey, False, vExact);
    if vExact then
    begin
      vO := mNodeData[vNode + nKV] + mNodeData[vNode + nKey];
      SetLength(ParaValue, mNodeData[vNode + nVal]);
      System.Move(mKVData[vO], ParaValue[0], Length(ParaValue));
      Result := True;
    end;
  finally
    ReleaseLock;
  end;
end;

function TDB.Find(const ParaKey: TBytes; out ParaRKey, ParaValue: TBytes): Boolean;
var
  vNode, vN, vM: Integer;
  vExact: Boolean;
begin
  Result := False;
  AcquireLock;
  try
    vNode := FindGE(ParaKey, False, vExact);
    if vNode <> 0 then
    begin
      vN := mNodeData[vNode + nKV];
      vM := vN + mNodeData[vNode + nKey];
      SetLength(ParaRKey, vM - vN);
      System.Move(mKVData[vN], ParaRKey[0], Length(ParaRKey));
      SetLength(ParaValue, mNodeData[vNode + nVal]);
      System.Move(mKVData[vM], ParaValue[0], Length(ParaValue));
      Result := True;
    end;
  finally
    ReleaseLock;
  end;
end;

function TDB.NewIterator(ParaSlice: PRange): IIterator;
begin
  Result := TDBIter.Create(Self, ParaSlice);
end;

function TDB.Capacity: Integer;
begin
  AcquireLock;
  try
    Result := System.Capacity(mKVData);
  finally
    ReleaseLock;
  end;
end;

function TDB.Size: Integer;
begin
  AcquireLock;
  try
    Result := mKVSize;
  finally
    ReleaseLock;
  end;
end;

function TDB.Free: Integer;
begin
  AcquireLock;
  try
    Result := System.Capacity(mKVData) - Length(mKVData);
  finally
    ReleaseLock;
  end;
end;

function TDB.Len: Integer;
begin
  AcquireLock;
  try
    Result := mN;
  finally
    ReleaseLock;
  end;
end;

procedure TDB.Reset;
var
  vN: Integer;
begin
  AcquireLock;
  try
    mRnd.RandSeed := $deadbeef;
    mMaxHeight := 1;
    mN := 0;
    mKVSize := 0;
    SetLength(mKVData, 0);
    SetLength(mNodeData, nNext + tMaxHeight);
    mNodeData[nKV] := 0;
    mNodeData[nKey] := 0;
    mNodeData[nVal] := 0;
    mNodeData[nHeight] := tMaxHeight;
    for vN := 0 to tMaxHeight - 1 do
    begin
      mNodeData[nNext + vN] := 0;
      mPrevNode[vN] := 0;
    end;
  finally
    ReleaseLock;
  end;
end;

procedure TDB.AcquireLock;
begin
  EnterCriticalSection(mRndMu);
end;

procedure TDB.ReleaseLock;
begin
  LeaveCriticalSection(mRndMu);
end;

function TDB.GetNodeData(ParaIndex: Integer): Integer;
begin
  Result := mNodeData[ParaIndex];
end;

function TDB.GetKVData: TBytes;
begin
  Result := mKVData;
end;

function New(ParaCmp: IBasicComparer; ParaCapacity: Integer): TDB;
begin
  Result := TDB.Create(ParaCmp, ParaCapacity);
end;

function New2(ParaCmp: IBasicComparer; ParaCapacity: Integer): TDB;
begin
  Result := TDB.Create(ParaCmp, ParaCapacity, True);
end;

initialization
  gGlobalRnd := TRandom.Create($deadbeef);
  InitializeCriticalSection(gGlobalRndMu);

finalization
  gGlobalRnd.Free;
  DeleteCriticalSection(gGlobalRndMu);

end.