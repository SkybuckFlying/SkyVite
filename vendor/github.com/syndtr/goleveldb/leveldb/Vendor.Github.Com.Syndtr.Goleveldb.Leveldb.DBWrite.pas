unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DBWrite;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch;

type
  TWriteMerge = record
    Sync: Boolean;
    Batch: TBatch;
    KeyType: TKeyType;
    Key, Value: TBytes;
  end;

implementation

end.
