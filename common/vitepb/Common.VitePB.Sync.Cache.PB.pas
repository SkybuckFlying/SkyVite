unit Common.VitePb.SyncCache;

interface

uses
  Common.VitePB.Account.Block.PB,
  Common.VitePB.Account.Blockmeta.PB,
  Common.VitePB.Account.PB,
  Common.VitePB.Consensus.Point.PB,
  Common.VitePb.Message,
  Common.VitePB.Message.PB,
  Common.VitePB.Onroad.PB,
  Common.VitePB.Snapshot.Block.PB,
  Common.VitePB.VM.Log.List.PB,
  System.SysUtils System.Classes System.Generics.Collections,
  Vendor.Github.Com.Golang.Protobuf.Proto.Buffer,
  Vendor.Github.Com.Golang.Protobuf.Proto.Defaults,
  Vendor.Github.Com.Golang.Protobuf.Proto.Deprecated,
  Vendor.Github.Com.Golang.Protobuf.Proto.Discard,
  Vendor.Github.Com.Golang.Protobuf.Proto.Extensions,
  Vendor.Github.Com.Golang.Protobuf.Proto.Properties,
  Vendor.Github.Com.Golang.Protobuf.Proto.Proto,
  Vendor.Github.Com.Golang.Protobuf.Proto.Registry,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextDecode,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextEncode,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wire,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers;

type
  TCacheItem = class;   // Forward declaration
  TCacheItems = class;  // Forward declaration

  {
    TCacheItem corresponds to the cacheItem message in sync_cache.proto
  }
  TCacheItem = class
  private
    mFrom: UInt64;
    mTo: UInt64;
    mPrevHash: TBytes;
    mHash: TBytes;
    mPoints: TObjectList<THashHeight>;
    mVerified: Boolean;
    mFilename: string;
    mDone: Boolean;
    mSize: Int64;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property From: UInt64 read mFrom write mFrom;
    property To: UInt64 read mTo write mTo;
    property PrevHash: TBytes read mPrevHash write mPrevHash;
    property Hash: TBytes read mHash write mHash;
    property Points: TObjectList<THashHeight> read mPoints;
    property Verified: Boolean read mVerified write mVerified;
    property Filename: string read mFilename write mFilename;
    property Done: Boolean read mDone write mDone;
    property Size: Int64 read mSize write mSize;
  end;

  {
    TCacheItems corresponds to the cacheItems message in sync_cache.proto
  }
  TCacheItems = class
  private
    mItems: TObjectList<TCacheItem>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Items: TObjectList<TCacheItem> read mItems;
  end;

implementation

{ TCacheItem }

constructor TCacheItem.Create;
begin
  inherited Create;
  try
    mPoints := TObjectList<THashHeight>.Create(True);
  except
    on E: Exception do
    begin
      raise;
    end;
  end;
  Reset;
end;

destructor TCacheItem.Destroy;
begin
  mPoints.Free;
  inherited Destroy;
end;

procedure TCacheItem.Reset;
begin
  mFrom := 0;
  mTo := 0;
  mPrevHash := nil;
  mHash := nil;
  mPoints.Clear;
  mVerified := False;
  mFilename := '';
  mDone := False;
  mSize := 0;
end;

{ TCacheItems }

constructor TCacheItems.Create;
begin
  inherited Create;
  try
    mItems := TObjectList<TCacheItem>.Create(True);
  except
    on E: Exception do
    begin
      raise;
    end;
  end;
  Reset;
end;

destructor TCacheItems.Destroy;
begin
  mItems.Free;
  inherited Destroy;
end;

procedure TCacheItems.Reset;
begin
  mItems.Clear;
end;

end.
