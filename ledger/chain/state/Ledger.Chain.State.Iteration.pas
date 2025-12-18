unit Ledger.Chain.State.Iteration;

interface

uses
  Common.DB.XLevelDB,
  Common.Types,
  Interfaces,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Delete,
  Ledger.Chain.State.Interface,
  Ledger.Chain.State.Interface.Mock,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Redo.Cache,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.Round.Cache.Test,
  Ledger.Chain.State.State.DB,
  Ledger.Chain.State.StateDB,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Transform.Iterator,
  Ledger.Chain.State.Write,
  System.SysUtils;

type
  TStateDBIterationHelper = class helper for TStateDB
  public
    function NewStorageIterator(ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
    function NewSnapshotStorageIteratorByHeight(ParaSnapshotHeight: TUInt64; ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
    function NewSnapshotStorageIterator(ParaSnapshotHash: THash; ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
    function NewRawSnapshotStorageIteratorByHeight(ParaSnapshotHeight: TUInt64; ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
  end;

  TStateStorageIterator = class(TInterfacedObject, IStorageIterator)
  private
    mIter: IStorageIterator;
    mSnapshotHeight: TUInt64;
    mAddr: TAddress;
  public
    constructor Create(ParaIter: IStorageIterator; ParaAddr: TAddress; ParaSnapshotHeight: TUInt64);
    function Last: Boolean;
    function Prev: Boolean;
    function Seek(ParaKey: TBytes): Boolean;
    function Next: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    function GetError: Exception;
    procedure Release;
  end;

  TSnapshotStorageIterator = class(TInterfacedObject, IStorageIterator)
  private
    mIter: IStorageIterator;
    mIterOk: Boolean;
    mSnapshotHeight: TUInt64;
    mLastKey: TBytes;
    function Step(ParaIsNext: Boolean): Boolean;
    function SetCorrectPointer(ParaKey: TBytes): Boolean;
    function IsBeforeOrEqualHeight(ParaKey: TBytes): Boolean;
    procedure SetLastKey(ParaKey: TBytes);
  public
    constructor Create(ParaIter: IStorageIterator; ParaHeight: TUInt64);
    function Last: Boolean;
    function Prev: Boolean;
    function Seek(ParaKey: TBytes): Boolean;
    function Next: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    function GetError: Exception;
    procedure Release;
  end;

implementation

uses
  System.Classes,
  Common.DB.XLevelDB.Util,
  Ledger.Chain.Utils,
  Common.Binary,
  Common.Helper;

{ TStateDBIterationHelper }

function TStateDBIterationHelper.NewStorageIterator(ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
var
  vSlice: TBytesPrefix;
begin
  vSlice := TBytesPrefix.Create(TChainUtils.CreateStorageValueKeyPrefix(ParaAddr, ParaPrefix));
  Result := TStateStorageIterator.Create(Self.Store.NewIterator(vSlice), ParaAddr, 0);
end;

function TStateDBIterationHelper.NewSnapshotStorageIteratorByHeight(ParaSnapshotHeight: TUInt64; ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
begin
  Result := TStateStorageIterator.Create(Self.NewRawSnapshotStorageIteratorByHeight(ParaSnapshotHeight, ParaAddr, ParaPrefix), ParaAddr, ParaSnapshotHeight);
end;

function TStateDBIterationHelper.NewSnapshotStorageIterator(ParaSnapshotHash: THash; ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
var
  vHeight: TUInt64;
  vErr: Exception;
begin
  try
    vHeight := Self.Chain.GetSnapshotHeightByHash(ParaSnapshotHash);
    if vHeight <= 0 then
    begin
      Result := nil;
      Exit;
    end;
    Result := Self.NewSnapshotStorageIteratorByHeight(vHeight, ParaAddr, ParaPrefix);
  except
    on E: Exception do
    begin
      vErr := Exception.Create(Format('sDB.chain.GetSnapshotHeightByHash failed, hash is %s. Error: %s', [ParaSnapshotHash.ToString, E.Message]));
      raise vErr;
    end;
  end;
end;

function TStateDBIterationHelper.NewRawSnapshotStorageIteratorByHeight(ParaSnapshotHeight: TUInt64; ParaAddr: TAddress; ParaPrefix: TBytes): IStorageIterator;
var
  vStoreIterator: IStorageIterator;
begin
  vStoreIterator := Self.Store.NewIterator(TBytesPrefix.Create(TChainUtils.CreateHistoryStorageValueKeyPrefix(ParaAddr, ParaPrefix)));
  Result := TSnapshotStorageIterator.Create(vStoreIterator, ParaSnapshotHeight);
end;

{ TStateStorageIterator }

constructor TStateStorageIterator.Create(ParaIter: IStorageIterator; ParaAddr: TAddress; ParaSnapshotHeight: TUInt64);
begin
  inherited Create;
  mIter := ParaIter;
  mAddr := ParaAddr;
  mSnapshotHeight := ParaSnapshotHeight;
end;

function TStateStorageIterator.Last: Boolean;
begin
  Result := mIter.Last;
end;

function TStateStorageIterator.Prev: Boolean;
begin
  Result := mIter.Prev;
end;

function TStateStorageIterator.Seek(ParaKey: TBytes): Boolean;
var
  vSeekKey: TBytes;
begin
  if mSnapshotHeight > 0 then
  begin
    vSeekKey := TChainUtils.CreateHistoryStorageValueKey(mAddr, ParaKey, 0).Bytes
  end
  else
  begin
    vSeekKey := TChainUtils.CreateStorageValueKey(mAddr, ParaKey).Bytes;
  end;
  Result := mIter.Seek(vSeekKey);
end;

function TStateStorageIterator.Next: Boolean;
begin
  Result := mIter.Next;
end;

function TStateStorageIterator.Key: TBytes;
var
  vKey: TBytes;
  vKeySize: Byte;
begin
  vKey := mIter.Key;
  if Length(vKey) > 0 then
  begin
    vKeySize := vKey[1 + SizeOf(TAddress) + SizeOf(THash)];
    SetLength(Result, vKeySize);
    System.Move(vKey[1 + SizeOf(TAddress)], Result[0], vKeySize);
  end
  else
  begin
    Result := nil;
  end;
end;

function TStateStorageIterator.Value: TBytes;
begin
  Result := mIter.Value;
end;

function TStateStorageIterator.GetError: Exception;
var
  vErr: Exception;
begin
  vErr := mIter.GetError;
  if (vErr <> nil) and (vErr is ELevelDBNotFound) then
  begin
    Result := nil
  end
  else
  begin
    Result := vErr;
  end;
end;

procedure TStateStorageIterator.Release;
begin
  mIter.Release;
end;

{ TSnapshotStorageIterator }

constructor TSnapshotStorageIterator.Create(ParaIter: IStorageIterator; ParaHeight: TUInt64);
begin
  inherited Create;
  mIter := ParaIter;
  mSnapshotHeight := ParaHeight;
  mIterOk := True;
end;

function TSnapshotStorageIterator.Last: Boolean;
begin
  mIterOk := mIter.Last;
  if mIterOk then
  begin
    SetLastKey(mIter.Key);
    if not SetCorrectPointer(mLastKey) then
    begin
      Result := Prev
    end
    else
    begin
      Result := mIterOk;
    end;
  end
  else
  begin
    Result := mIterOk;
  end;
end;

function TSnapshotStorageIterator.Prev: Boolean;
begin
  Result := Step(False);
end;

function TSnapshotStorageIterator.Next: Boolean;
begin
  Result := Step(True);
end;

function TSnapshotStorageIterator.Seek(ParaKey: TBytes): Boolean;
begin
  mIterOk := mIter.Seek(ParaKey);
  if mIterOk then
  begin
    SetLastKey(mIter.Key);
    if not SetCorrectPointer(mLastKey) then
    begin
      Result := Next
    end
    else
    begin
      Result := mIterOk;
    end;
  end
  else
  begin
    Result := mIterOk;
  end;
end;

function TSnapshotStorageIterator.Key: TBytes;
begin
  Result := mIter.Key;
end;

function TSnapshotStorageIterator.Value: TBytes;
begin
  Result := mIter.Value;
end;

function TSnapshotStorageIterator.GetError: Exception;
begin
  Result := mIter.GetError;
end;

procedure TSnapshotStorageIterator.Release;
begin
  mIter.Release;
end;

function TSnapshotStorageIterator.Step(ParaIsNext: Boolean): Boolean;
begin
  while mIterOk do
  begin
    if Length(mLastKey) > 0 then
    begin
      if ParaIsNext then
      begin
        TBigEndian.PutUInt64(mLastKey, TMath.MaxUInt64, Length(mLastKey) - 8);
        mIterOk := mIter.Seek(mLastKey);
      end
      else
      begin
        TBigEndian.PutUInt64(mLastKey, 0, Length(mLastKey) - 8);
        mIterOk := mIter.Seek(mLastKey);
        if mIterOk then
        begin
          mIterOk := mIter.Prev;
        end;
      end;
    end
    else
    begin
      if ParaIsNext then
      begin
        mIterOk := mIter.Next
      end
      else
      begin
        mIterOk := mIter.Prev;
      end;
    end;

    if not mIterOk then
    begin
      Break;
    end;

    SetLastKey(mIter.Key);

    if SetCorrectPointer(mLastKey) then
    begin
      Break;
    end;
  end;
  Result := mIterOk;
end;

function TSnapshotStorageIterator.SetCorrectPointer(ParaKey: TBytes): Boolean;
var
  vSeekKey, vPrevKey, vLastKey: TBytes;
begin
  SetLength(vSeekKey, Length(ParaKey));
  System.Move(ParaKey[0], vSeekKey[0], Length(ParaKey) - 8);
  TBigEndian.PutUInt64(vSeekKey, mSnapshotHeight, Length(vSeekKey) - 8);

  if mIter.Seek(vSeekKey) then
  begin
    vSeekKey := mIter.Key;
    if SameBytes(Copy(vSeekKey, 0, Length(vSeekKey) - 8), Copy(ParaKey, 0, Length(ParaKey) - 8)) and IsBeforeOrEqualHeight(vSeekKey) then
    begin
      Exit(True);
    end;

    if mIter.Prev then
    begin
      vPrevKey := mIter.Key;
      if SameBytes(Copy(vPrevKey, 0, Length(vPrevKey) - 8), Copy(ParaKey, 0, Length(ParaKey) - 8)) then
      begin
        Exit(True);
      end;
    end;
  end
  else if mIter.Last then
  begin
    vLastKey := mIter.Key;
    if SameBytes(Copy(vLastKey, 0, Length(vLastKey) - 8), Copy(ParaKey, 0, Length(ParaKey) - 8)) then
    begin
      Exit(True);
    end;
  end;
  Result := False;
end;

function TSnapshotStorageIterator.IsBeforeOrEqualHeight(ParaKey: TBytes): Boolean;
begin
  Result := TBigEndian.ToUInt64(ParaKey, Length(ParaKey) - 8) <= mSnapshotHeight;
end;

procedure TSnapshotStorageIterator.SetLastKey(ParaKey: TBytes);
var
  vIterKeyLen: Integer;
begin
  // copy is important
  vIterKeyLen := Length(ParaKey);
  if Length(mLastKey) <> vIterKeyLen then
  begin
    SetLength(mLastKey, vIterKeyLen);
  end;
  // copy is important
  System.Move(ParaKey[0], mLastKey[0], vIterKeyLen);
end;

end.
