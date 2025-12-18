unit common.db.xleveldb.iterator.array_iter;

interface

uses
  Common.DB.XLevelDB.Iterator.Indexed.Iter,
  common.db.xleveldb.iterator.iter,
  Common.DB.XLevelDB.Iterator.Merged.Iter,
  common.db.xleveldb.util // For IBasicReleaser EErrIterReleased,
  System.Classes,
  System.SysUtils;

type
  // BasicArray is the interface that wraps basic Len and Search method.
  IBasicArray = interface
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    // Len returns length of the array.
    function Len: Integer;

    // Search finds smallest index that point to a key that is greater
    // than or equal to the given key.
    function Search(const Key: TBytes): Integer;
  end;

  // Array is the interface that wraps IBasicArray and basic Index method.
  IArray = interface(IBasicArray)
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    // Index returns key/value pair with index of i.
    function Index(I: Integer; out Key, Value: TBytes): Boolean;
  end;

  // ArrayIndexer is the interface that wraps IBasicArray and basic Get method.
  IArrayIndexer = interface(IBasicArray)
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    // Get returns a new data iterator with index of i.
    function Get(I: Integer): IIterator;
  end;

type
  TBasicArrayIterator = class(TInterfacedObject, IIterator)
  protected
    FBasicReleaser: TBasicReleaser;
    FArray: IBasicArray;
    FPos: Integer;
    FErr: Exception;
  public
    constructor Create(AArray: IBasicArray);
    function Valid: Boolean; override;
    function First: Boolean; override;
    function Last: Boolean; override;
    function Seek(const Key: TBytes): Boolean; override;
    function Next: Boolean; override;
    function Prev: Boolean; override;
    function Key: TBytes; virtual; abstract;
    function Value: TBytes; virtual; abstract;
    procedure Release; override;
    procedure SetReleaser(Releaser: IReleaser); override;
    function Error: Exception; override;
  end;

  TArrayIterator = class(TBasicArrayIterator)
  private
    FArray: IArray;
    FPrevPos: Integer;
    FKey, FValue: TBytes;
    procedure UpdateKV;
  public
    constructor Create(AArray: IArray);
    function Key: TBytes; override;
    function Value: TBytes; override;
  end;

  TArrayIndexerIterator = class(TBasicArrayIterator, IIteratorIndexer)
  private
    FArray: IArrayIndexer;
  public
    constructor Create(AArray: IArrayIndexer);
    function Get: IIterator; override;
    function Key: TBytes; override;
    function Value: TBytes; override;
  end;

function NewArrayIterator(Array: IArray): IIterator;
function NewArrayIndexer(Array: IArrayIndexer): IIteratorIndexer;

implementation

{ TBasicArrayIterator }

constructor TBasicArrayIterator.Create(AArray: IBasicArray);
begin
  FBasicReleaser := TBasicReleaser.Create;
  FArray := AArray;
  FPos := -1;
  FErr := nil;
end;

function TBasicArrayIterator.Valid: Boolean;
begin
  Result := (FPos >= 0) and (FPos < FArray.Len) and (not FBasicReleaser.Released);
end;

function TBasicArrayIterator.First: Boolean;
begin
  if FBasicReleaser.Released then
  begin
    FErr := EErrIterReleased.Create('');
    Exit(False);
  end;

  if FArray.Len = 0 then
  begin
    FPos := -1;
    Exit(False);
  end;
  FPos := 0;
  Result := True;
end;

function TBasicArrayIterator.Last: Boolean;
var
  N: Integer;
begin
  if FBasicReleaser.Released then
  begin
    FErr := EErrIterReleased.Create('');
    Exit(False);
  end;

  N := FArray.Len;
  if N = 0 then
  begin
    FPos := -1;
    Exit(False);
  end;
  FPos := N - 1;
  Result := True;
end;

function TBasicArrayIterator.Seek(const Key: TBytes): Boolean;
var
  N: Integer;
begin
  if FBasicReleaser.Released then
  begin
    FErr := EErrIterReleased.Create('');
    Exit(False);
  end;

  N := FArray.Len;
  if N = 0 then
  begin
    FPos := -1;
    Exit(False);
  end;
  FPos := FArray.Search(Key);
  if FPos >= N then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
end;

function TBasicArrayIterator.Next: Boolean;
var
  N: Integer;
begin
  if FBasicReleaser.Released then
  begin
    FErr := EErrIterReleased.Create('');
    Exit(False);
  end;

  Inc(FPos);
  N := FArray.Len;
  if FPos >= N then
  begin
    FPos := N; // Set to end-of-iteration marker
    Result := False;
    Exit;
  end;
  Result := True;
end;

function TBasicArrayIterator.Prev: Boolean;
begin
  if FBasicReleaser.Released then
  begin
    FErr := EErrIterReleased.Create('');
    Exit(False);
  end;

  Dec(FPos);
  if FPos < 0 then
  begin
    FPos := -1; // Set to start-of-iteration marker
    Result := False;
    Exit;
  end;
  Result := True;
end;

procedure TBasicArrayIterator.Release;
begin
  FBasicReleaser.Release;
end;

procedure TBasicArrayIterator.SetReleaser(Releaser: IReleaser);
begin
  FBasicReleaser.SetReleaser(Releaser);
end;

function TBasicArrayIterator.Error: Exception;
begin
  Result := FErr;
end;

{ TArrayIterator }

constructor TArrayIterator.Create(AArray: IArray);
begin
  inherited Create(AArray);
  FArray := AArray;
  FPrevPos := -1;
  SetLength(FKey, 0);
  SetLength(FValue, 0);
end;

procedure TArrayIterator.UpdateKV;
begin
  if FPos = FPrevPos then
    Exit;
  FPrevPos := FPos;
  if Valid then
    FArray.Index(FPos, FKey, FValue)
  else
  begin
    SetLength(FKey, 0);
    SetLength(FValue, 0);
  end;
end;

function TArrayIterator.Key: TBytes;
begin
  UpdateKV;
  Result := FKey;
end;

function TArrayIterator.Value: TBytes;
begin
  UpdateKV;
  Result := FValue;
end;

{ TArrayIndexerIterator }

constructor TArrayIndexerIterator.Create(AArray: IArrayIndexer);
begin
  inherited Create(AArray);
  FArray := AArray;
end;

function TArrayIndexerIterator.Get: IIterator;
begin
  if Valid then
    Result := FArray.Get(FPos)
  else
    Result := nil;
end;

function TArrayIndexerIterator.Key: TBytes;
begin
  // This iterator doesn't directly expose keys/values, it returns other iterators.
  // So, this method should ideally not be called or return nil/raise error.
  // For now, returning nil as per Go's `IteratorIndexer` not having Key/Value methods.
  Result := nil;
end;

function TArrayIndexerIterator.Value: TBytes;
begin
  // Same as Key, this iterator doesn't directly expose values.
  Result := nil;
end;

function NewArrayIterator(Array: IArray): IIterator;
begin
  Result := TArrayIterator.Create(Array);
end;

function NewArrayIndexer(Array: IArrayIndexer): IIteratorIndexer;
begin
  Result := TArrayIndexerIterator.Create(Array);
end;

end.
