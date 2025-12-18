unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DBUtil;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Db,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbSnapshot,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbState,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbTransaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbWrite,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Doc,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Session,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Version;

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
