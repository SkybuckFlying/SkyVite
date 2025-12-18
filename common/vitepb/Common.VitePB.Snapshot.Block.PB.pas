unit Common.VitePb.SnapshotBlock;

interface

uses
  Common.VitePB.Account.Block.PB,
  Common.VitePB.Account.Blockmeta.PB,
  Common.VitePB.Account.PB,
  Common.VitePB.Consensus.Point.PB,
  Common.VitePB.Message.PB,
  Common.VitePB.Onroad.PB,
  Common.VitePB.Sync.Cache.PB,
  Common.VitePB.VM.Log.List.PB,
  System.SysUtils System.Classes;

type
  {
    TSnapshotBlock corresponds to the SnapshotBlock message in snapshot_block.proto
  }
  TSnapshotBlock = class
  private
    mHash: TBytes;
    mPrevHash: TBytes;
    mHeight: UInt64;
    mPublicKey: TBytes;
    mSignature: TBytes;
    mTimestamp: Int64;
    mSeed: UInt64;
    mSeedHash: TBytes;
    mSnapshotContent: TBytes;
    mVersion: UInt32;
    mXXX_NoUnkeyedLiteral: record end;
    mXXX_unrecognized: TBytes;
    mXXX_sizecache: Int32;
  public
    constructor Create;
    procedure Reset;
    procedure ProtoMessage; // Placeholder
    property Hash: TBytes read mHash write mHash;
    property PrevHash: TBytes read mPrevHash write mPrevHash;
    property Height: UInt64 read mHeight write mHeight;
    property PublicKey: TBytes read mPublicKey write mPublicKey;
    property Signature: TBytes read mSignature write mSignature;
    property Timestamp: Int64 read mTimestamp write mTimestamp;
    property Seed: UInt64 read mSeed write mSeed;
    property SeedHash: TBytes read mSeedHash write mSeedHash;
    property SnapshotContent: TBytes read mSnapshotContent write mSnapshotContent;
    property Version: UInt32 read mVersion write mVersion;
  end;

implementation

{ TSnapshotBlock }

constructor TSnapshotBlock.Create;
begin
  inherited Create;
  Reset;
end;

procedure TSnapshotBlock.Reset;
begin
  mHash := nil;
  mPrevHash := nil;
  mHeight := 0;
  mPublicKey := nil;
  mSignature := nil;
  mTimestamp := 0;
  mSeed := 0;
  mSeedHash := nil;
  mSnapshotContent := nil;
  mVersion := 0;
  mXXX_sizecache := 0;
  mXXX_unrecognized := nil;
end;

procedure TSnapshotBlock.ProtoMessage;
begin
  // This method is a marker for protobuf messages.
end;

end.
