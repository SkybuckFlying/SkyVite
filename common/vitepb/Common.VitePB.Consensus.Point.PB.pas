unit Common.VitePb.ConsensusPoint;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TPointVoteContent = class; // Forward declaration
  TPointContent = class;     // Forward declaration
  TConsensusPoint = class;   // Forward declaration

  {
    TPointVoteContent corresponds to the PointVoteContent message in consensus_point.proto
  }
  TPointVoteContent = class
  private
    mVoteCnt: TBytes;
    mName: string;
    mXXX_NoUnkeyedLiteral: record end;
    mXXX_unrecognized: TBytes;
    mXXX_sizecache: Int32;
  public
    constructor Create;
    procedure Reset;
    property VoteCnt: TBytes read mVoteCnt write mVoteCnt;
    property Name: string read mName write mName;
  end;

  {
    TPointContent corresponds to the PointContent message in consensus_point.proto
  }
  TPointContent = class
  private
    mAddress: TBytes;
    mFNum: UInt32;
    mENum: UInt32;
    mXXX_NoUnkeyedLiteral: record end;
    mXXX_unrecognized: TBytes;
    mXXX_sizecache: Int32;
  public
    constructor Create;
    procedure Reset;
    property Address: TBytes read mAddress write mAddress;
    property FNum: UInt32 read mFNum write mFNum;
    property ENum: UInt32 read mENum write mENum;
  end;

  {
    TConsensusPoint corresponds to the ConsensusPoint message in consensus_point.proto
  }
  TConsensusPoint = class
  private
    mPrevHash: TBytes;
    mHash: TBytes;
    mContents: TObjectList<TPointContent>;
    mVotes: TObjectList<TPointVoteContent>;
    mXXX_NoUnkeyedLiteral: record end;
    mXXX_unrecognized: TBytes;
    mXXX_sizecache: Int32;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property PrevHash: TBytes read mPrevHash write mPrevHash;
    property Hash: TBytes read mHash write mHash;
    property Contents: TObjectList<TPointContent> read mContents;
    property Votes: TObjectList<TPointVoteContent> read mVotes;
  end;

implementation

{ TPointVoteContent }

constructor TPointVoteContent.Create;
begin
  inherited Create;
  Reset;
end;

procedure TPointVoteContent.Reset;
begin
  mVoteCnt := nil;
  mName := '';
  mXXX_sizecache := 0;
  mXXX_unrecognized := nil;
end;

{ TPointContent }

constructor TPointContent.Create;
begin
  inherited Create;
  Reset;
end;

procedure TPointContent.Reset;
begin
  mAddress := nil;
  mFNum := 0;
  mENum := 0;
  mXXX_sizecache := 0;
  mXXX_unrecognized := nil;
end;

{ TConsensusPoint }

constructor TConsensusPoint.Create;
begin
  inherited Create;
  try
    mContents := TObjectList<TPointContent>.Create(True);
    mVotes := TObjectList<TPointVoteContent>.Create(True);
  except
    on E: Exception do
    begin
      // Handle memory allocation failure
      FreeAndNil(mContents);
      FreeAndNil(mVotes);
      raise;
    end;
  end;
  Reset;
end;

destructor TConsensusPoint.Destroy;
begin
  mContents.Free;
  mVotes.Free;
  inherited Destroy;
end;

procedure TConsensusPoint.Reset;
begin
  mPrevHash := nil;
  mHash := nil;
  mContents.Clear;
  mVotes.Clear;
  mXXX_sizecache := 0;
  mXXX_unrecognized := nil;
end;

end.