unit Common.VitePb.Message;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Common.VitePb.AccountBlock, Common.VitePb.SnapshotBlock;

type
  // Forward declarations for all message classes
  THandshake = class;
  TSyncConnHandshake = class;
  TChunkRequest = class;
  TChunkResponse = class;
  TState_Peer = class;
  TState = class;
  THashHeight = class;
  THashHeightPoint = class;
  THashHeightList = class;
  TGetHashHeightList = class;
  TGetSnapshotBlocks = class;
  TSnapshotBlocks = class;
  TGetAccountBlocks = class;
  TAccountBlocks = class;
  TNewSnapshotBlock = class;
  TNewAccountBlock = class;
  TNewAccountBlockBytes = class;
  TTrace = class;

  TState_PeerStatus = (psConnected, psDisconnected);

  THandshake = class
  private
    mVersion: Int64;
    mNetId: Int64;
    mName: string;
    mID: TBytes;
    mTimestamp: Int64;
    mGenesis: TBytes;
    mHeight: UInt64;
    mHead: TBytes;
    mFileAddress: TBytes;
    mKey: TBytes;
    mToken: TBytes;
    mPublicAddress: TBytes;
  public
    constructor Create;
    procedure Reset;
    property Version: Int64 read mVersion write mVersion;
    property NetId: Int64 read mNetId write mNetId;
    property Name: string read mName write mName;
    property ID: TBytes read mID write mID;
    property Timestamp: Int64 read mTimestamp write mTimestamp;
    property Genesis: TBytes read mGenesis write mGenesis;
    property Height: UInt64 read mHeight write mHeight;
    property Head: TBytes read mHead write mHead;
    property FileAddress: TBytes read mFileAddress write mFileAddress;
    property Key: TBytes read mKey write mKey;
    property Token: TBytes read mToken write mToken;
    property PublicAddress: TBytes read mPublicAddress write mPublicAddress;
  end;

  TSyncConnHandshake = class
  private
    mID: TBytes;
    mTimestamp: Int64;
    mKey: TBytes;
    mToken: TBytes;
  public
    constructor Create;
    procedure Reset;
    property ID: TBytes read mID write mID;
    property Timestamp: Int64 read mTimestamp write mTimestamp;
    property Key: TBytes read mKey write mKey;
    property Token: TBytes read mToken write mToken;
  end;

  TChunkRequest = class
  private
    mFrom: UInt64;
    mTo: UInt64;
    mPrevHash: TBytes;
    mEndHash: TBytes;
  public
    constructor Create;
    procedure Reset;
    property From: UInt64 read mFrom write mFrom;
    property To: UInt64 read mTo write mTo;
    property PrevHash: TBytes read mPrevHash write mPrevHash;
    property EndHash: TBytes read mEndHash write mEndHash;
  end;

  TChunkResponse = class
  private
    mFrom: UInt64;
    mTo: UInt64;
    mPrevHash: TBytes;
    mEndHash: TBytes;
    mSize: UInt64;
  public
    constructor Create;
    procedure Reset;
    property From: UInt64 read mFrom write mFrom;
    property To: UInt64 read mTo write mTo;
    property PrevHash: TBytes read mPrevHash write mPrevHash;
    property EndHash: TBytes read mEndHash write mEndHash;
    property Size: UInt64 read mSize write mSize;
  end;

  TState_Peer = class
  private
    mID: TBytes;
    mStatus: TState_PeerStatus;
  public
    constructor Create;
    procedure Reset;
    property ID: TBytes read mID write mID;
    property Status: TState_PeerStatus read mStatus write mStatus;
  end;

  TState = class
  private
    mPeers: TObjectList<TState_Peer>;
    mPatch: Boolean;
    mHead: TBytes;
    mHeight: UInt64;
    mTimestamp: Int64;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Peers: TObjectList<TState_Peer> read mPeers;
    property Patch: Boolean read mPatch write mPatch;
    property Head: TBytes read mHead write mHead;
    property Height: UInt64 read mHeight write mHeight;
    property Timestamp: Int64 read mTimestamp write mTimestamp;
  end;

  THashHeight = class
  private
    mHash: TBytes;
    mHeight: UInt64;
  public
    constructor Create;
    procedure Reset;
    property Hash: TBytes read mHash write mHash;
    property Height: UInt64 read mHeight write mHeight;
  end;

  THashHeightPoint = class
  private
    mPoint: THashHeight;
    mSize: UInt64;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Point: THashHeight read mPoint;
    property Size: UInt64 read mSize write mSize;
  end;

  THashHeightList = class
  private
    mPoints: TObjectList<THashHeightPoint>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Points: TObjectList<THashHeightPoint> read mPoints;
  end;

  TGetHashHeightList = class
  private
    mFrom: TObjectList<THashHeight>;
    mStep: UInt64;
    mTo: UInt64;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property From: TObjectList<THashHeight> read mFrom;
    property Step: UInt64 read mStep write mStep;
    property To: UInt64 read mTo write mTo;
  end;

  TGetSnapshotBlocks = class
  private
    mFrom: THashHeight;
    mCount: UInt64;
    mForward: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property From: THashHeight read mFrom;
    property Count: UInt64 read mCount write mCount;
    property Forward: Boolean read mForward write mForward;
  end;

  TSnapshotBlocks = class
  private
    mBlocks: TObjectList<TSnapshotBlock>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Blocks: TObjectList<TSnapshotBlock> read mBlocks;
  end;

  TGetAccountBlocks = class
  private
    mAddress: TBytes;
    mFrom: THashHeight;
    mCount: UInt64;
    mForward: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Address: TBytes read mAddress write mAddress;
    property From: THashHeight read mFrom;
    property Count: UInt64 read mCount write mCount;
    property Forward: Boolean read mForward write mForward;
  end;

  TAccountBlocks = class
  private
    mBlocks: TObjectList<TAccountBlock>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Blocks: TObjectList<TAccountBlock> read mBlocks;
  end;

  TNewSnapshotBlock = class
  private
    mBlock: TSnapshotBlock;
    mTTL: Int32;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Block: TSnapshotBlock read mBlock;
    property TTL: Int32 read mTTL write mTTL;
  end;

  TNewAccountBlock = class
  private
    mBlock: TAccountBlock;
    mTTL: Int32;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Block: TAccountBlock read mBlock;
    property TTL: Int32 read mTTL write mTTL;
  end;

  TNewAccountBlockBytes = class
  private
    mBlock: TBytes;
    mTTL: Int32;
  public
    constructor Create;
    procedure Reset;
    property Block: TBytes read mBlock write mBlock;
    property TTL: Int32 read mTTL write mTTL;
  end;

  TTrace = class
  private
    mHash: TBytes;
    mPath: TArray<TBytes>;
    mTTL: UInt32;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Hash: TBytes read mHash write mHash;
    property Path: TArray<TBytes> read mPath write mPath;
    property TTL: UInt32 read mTTL write mTTL;
  end;

implementation

{ THandshake }
constructor THandshake.Create; begin inherited; Reset; end;
procedure THandshake.Reset;
begin
  mVersion := 0; mNetId := 0; mName := ''; mID := nil; mTimestamp := 0;
  mGenesis := nil; mHeight := 0; mHead := nil; mFileAddress := nil;
  mKey := nil; mToken := nil; mPublicAddress := nil;
end;

{ TSyncConnHandshake }
constructor TSyncConnHandshake.Create; begin inherited; Reset; end;
procedure TSyncConnHandshake.Reset;
begin
  mID := nil; mTimestamp := 0; mKey := nil; mToken := nil;
end;

{ TChunkRequest }
constructor TChunkRequest.Create; begin inherited; Reset; end;
procedure TChunkRequest.Reset;
begin
  mFrom := 0; mTo := 0; mPrevHash := nil; mEndHash := nil;
end;

{ TChunkResponse }
constructor TChunkResponse.Create; begin inherited; Reset; end;
procedure TChunkResponse.Reset;
begin
  mFrom := 0; mTo := 0; mPrevHash := nil; mEndHash := nil; mSize := 0;
end;

{ TState_Peer }
constructor TState_Peer.Create; begin inherited; Reset; end;
procedure TState_Peer.Reset;
begin
  mID := nil; mStatus := psConnected;
end;

{ TState }
constructor TState.Create;
begin
  inherited;
  try
    mPeers := TObjectList<TState_Peer>.Create(True);
  except on E: Exception do raise; end;
  Reset;
end;
destructor TState.Destroy; begin mPeers.Free; inherited; end;
procedure TState.Reset;
begin
  mPeers.Clear; mPatch := False; mHead := nil; mHeight := 0; mTimestamp := 0;
end;

{ THashHeight }
constructor THashHeight.Create; begin inherited; Reset; end;
procedure THashHeight.Reset; begin mHash := nil; mHeight := 0; end;

{ THashHeightPoint }
constructor THashHeightPoint.Create;
begin inherited; try mPoint := THashHeight.Create; except on E: Exception do raise; end; Reset; end;
destructor THashHeightPoint.Destroy; begin mPoint.Free; inherited; end;
procedure THashHeightPoint.Reset; begin mPoint.Reset; mSize := 0; end;

{ THashHeightList }
constructor THashHeightList.Create;
begin inherited; try mPoints := TObjectList<THashHeightPoint>.Create(True); except on E: Exception do raise; end; Reset; end;
destructor THashHeightList.Destroy; begin mPoints.Free; inherited; end;
procedure THashHeightList.Reset; begin mPoints.Clear; end;

{ TGetHashHeightList }
constructor TGetHashHeightList.Create;
begin inherited; try mFrom := TObjectList<THashHeight>.Create(True); except on E: Exception do raise; end; Reset; end;
destructor TGetHashHeightList.Destroy; begin mFrom.Free; inherited; end;
procedure TGetHashHeightList.Reset; begin mFrom.Clear; mStep := 0; mTo := 0; end;

{ TGetSnapshotBlocks }
constructor TGetSnapshotBlocks.Create;
begin inherited; try mFrom := THashHeight.Create; except on E: Exception do raise; end; Reset; end;
destructor TGetSnapshotBlocks.Destroy; begin mFrom.Free; inherited; end;
procedure TGetSnapshotBlocks.Reset; begin mFrom.Reset; mCount := 0; mForward := False; end;

{ TSnapshotBlocks }
constructor TSnapshotBlocks.Create;
begin inherited; try mBlocks := TObjectList<TSnapshotBlock>.Create(True); except on E: Exception do raise; end; Reset; end;
destructor TSnapshotBlocks.Destroy; begin mBlocks.Free; inherited; end;
procedure TSnapshotBlocks.Reset; begin mBlocks.Clear; end;

{ TGetAccountBlocks }
constructor TGetAccountBlocks.Create;
begin inherited; try mFrom := THashHeight.Create; except on E: Exception do raise; end; Reset; end;
destructor TGetAccountBlocks.Destroy; begin mFrom.Free; inherited; end;
procedure TGetAccountBlocks.Reset; begin mAddress := nil; mFrom.Reset; mCount := 0; mForward := False; end;

{ TAccountBlocks }
constructor TAccountBlocks.Create;
begin inherited; try mBlocks := TObjectList<TAccountBlock>.Create(True); except on E: Exception do raise; end; Reset; end;
destructor TAccountBlocks.Destroy; begin mBlocks.Free; inherited; end;
procedure TAccountBlocks.Reset; begin mBlocks.Clear; end;

{ TNewSnapshotBlock }
constructor TNewSnapshotBlock.Create;
begin inherited; try mBlock := TSnapshotBlock.Create; except on E: Exception do raise; end; Reset; end;
destructor TNewSnapshotBlock.Destroy; begin mBlock.Free; inherited; end;
procedure TNewSnapshotBlock.Reset; begin mBlock.Reset; mTTL := 0; end;

{ TNewAccountBlock }
constructor TNewAccountBlock.Create;
begin inherited; try mBlock := TAccountBlock.Create; except on E: Exception do raise; end; Reset; end;
destructor TNewAccountBlock.Destroy; begin mBlock.Free; inherited; end;
procedure TNewAccountBlock.Reset; begin mBlock.Reset; mTTL := 0; end;

{ TNewAccountBlockBytes }
constructor TNewAccountBlockBytes.Create; begin inherited; Reset; end;
procedure TNewAccountBlockBytes.Reset; begin mBlock := nil; mTTL := 0; end;

{ TTrace }
constructor TTrace.Create; begin inherited; Reset; end;
destructor TTrace.Destroy; begin mPath := nil; inherited; end;
procedure TTrace.Reset; begin mHash := nil; SetLength(mPath, 0); mTTL := 0; end;

end.