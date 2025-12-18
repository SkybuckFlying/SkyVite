unit Ledger.Chain.State.TransformIterator;

interface

uses
  Common.DB.XLevelDB.Iterator,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Delete,
  Ledger.Chain.State.Interface,
  Ledger.Chain.State.Interface.Mock,
  Ledger.Chain.State.Iteration,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Redo.Cache,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.Round.Cache.Test,
  Ledger.Chain.State.State.DB,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Write,
  System.SysUtils;

type
  TTransformIterator = class(TInterfacedObject, IIterator)
  private
    mIter: IIterator;
    mKeyPrefixLength: Integer;
  public
    constructor Create(ParaIter: IIterator; ParaKeyPrefixLength: Integer);
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

{ TTransformIterator }

constructor TTransformIterator.Create(ParaIter: IIterator; ParaKeyPrefixLength: Integer);
begin
  inherited Create;
  mIter := ParaIter;
  mKeyPrefixLength := ParaKeyPrefixLength;
end;

function TTransformIterator.Last: Boolean;
begin
  Result := mIter.Last;
end;

function TTransformIterator.Prev: Boolean;
begin
  Result := mIter.Prev;
end;

function TTransformIterator.Seek(ParaKey: TBytes): Boolean;
begin
  Result := mIter.Seek(ParaKey);
end;

function TTransformIterator.Next: Boolean;
begin
  Result := mIter.Next;
end;

function TTransformIterator.Key: TBytes;
var
  vKey: TBytes;
begin
  vKey := mIter.Key;
  SetLength(Result, Length(vKey) - mKeyPrefixLength);
  System.Move(vKey[mKeyPrefixLength], Result[0], Length(Result));
end;

function TTransformIterator.Value: TBytes;
begin
  Result := mIter.Value;
end;

function TTransformIterator.GetError: Exception;
begin
  Result := mIter.GetError;
end;

procedure TTransformIterator.Release;
begin
  mIter.Release;
end;

end.
