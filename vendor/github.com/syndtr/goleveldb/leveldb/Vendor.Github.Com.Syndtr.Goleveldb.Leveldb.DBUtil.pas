unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DBUtil;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter;

type
  IReader = interface
    ['{DA491E21-4CA1-4BA7-BC26-1E1C2D3E4F50}']
    function Get( const ParaKey : TBytes; ParaRO : TReadOptions; out ParaValue : TBytes ) : Exception;
    function NewIterator( ParaSlice : TRange; ParaRO : TReadOptions ) : IIterator;
  end;

  TSizes = TArray<Int64>;

  TSizesHelper = record helper for TSizes
    function Sum : Int64;
  end;

implementation

{ TSizesHelper }

function TSizesHelper.Sum : Int64;
var
  vSize : Int64;
begin
  Result := 0;
  for vSize in Self do
    Result := Result + vSize;
end;

end.
