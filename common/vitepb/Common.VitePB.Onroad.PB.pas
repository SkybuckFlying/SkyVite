unit Common.VitePb.Onroad;

interface

uses
  Common.VitePB.Account.Block.PB,
  Common.VitePB.Account.Blockmeta.PB,
  Common.VitePB.Account.PB,
  Common.VitePB.Consensus.Point.PB,
  Common.VitePB.Message.PB,
  Common.VitePB.Snapshot.Block.PB,
  Common.VitePB.Sync.Cache.PB,
  Common.VitePB.VM.Log.List.PB,
  System.SysUtils,
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
  {
    TOnroadMeta corresponds to the OnroadMeta message in onroad.proto
  }
  TOnroadMeta = class
  private
    mNum: UInt64;
    mAmount: TBytes;
    mXXX_NoUnkeyedLiteral: record end;
    mXXX_unrecognized: TBytes;
    mXXX_sizecache: Int32;
  public
    constructor Create;
    procedure Reset;
    procedure ProtoMessage; // Placeholder
    property Num: UInt64 read mNum write mNum;
    property Amount: TBytes read mAmount write mAmount;
  end;

implementation

{ TOnroadMeta }

constructor TOnroadMeta.Create;
begin
  inherited Create;
  Reset;
end;

procedure TOnroadMeta.Reset;
begin
  mNum := 0;
  mAmount := nil;
  mXXX_sizecache := 0;
  mXXX_unrecognized := nil;
end;

procedure TOnroadMeta.ProtoMessage;
begin
  // This method is a marker for protobuf messages.
end;

end.
