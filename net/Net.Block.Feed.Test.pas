unit Net.BlockFeed.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  Common.Types,
  Interfaces.Core,
  Net.BlockFeed;

type
  [TestFixture]
  TBlockFeedTest = class(TObject)
  public
    [Test]
    procedure TestBlockFeed_Black;
  end;

implementation

uses
  System.Generics.Collections;

type
  TMockSnapshotBlock = class(TInterfacedObject, ISnapshotBlock)
  private
    FHash: THash;
    FHeight: UInt64;
    function GetHash: THash;
    function GetHeight: UInt64;
  public
    property Hash: THash read GetHash write FHash;
    property Height: UInt64 read GetHeight write FHeight;
  end;

{ TMockSnapshotBlock }

function TMockSnapshotBlock.GetHash: THash;
begin
  Result := FHash;
end;

function TMockSnapshotBlock.GetHeight: UInt64;
begin
  Result := FHeight;
end;

{ TBlockFeedTest }

procedure TBlockFeedTest.TestBlockFeed_Black;
const
  Black = '6771bc124fed97302328c13fb9a97919c8963b7b1f79a431091c7ace00ec28f4';
var
  Feed: IBlockFeeder;
  BlackBlocks: TDictionary<THash, Boolean>;
  Failed: Boolean;
  BlackHash: THash;
  SnapshotBlock: ISnapshotBlock;
begin
  BlackBlocks := TDictionary<THash, Boolean>.Create;
  try
    Feed := NewBlockFeeder(BlackBlocks);

    Failed := False;
    Feed.SubscribeSnapshotBlock(
      procedure(Block: ISnapshotBlock; Source: TBlockSource)
      begin
        if Block.Hash.ToString = Black then
          Failed := True
        else
          WriteLn(Format('%s/%d', [Block.Hash.ToString, Block.Height]));
      end);

    BlackHash := THash.FromHex(Black);
    BlackBlocks.Add(BlackHash, True);

    SnapshotBlock := TMockSnapshotBlock.Create;
    SnapshotBlock.Hash := BlackHash;
    Feed.NotifySnapshotBlock(SnapshotBlock, bsRemoteCache);

    SnapshotBlock := TMockSnapshotBlock.Create;
    SnapshotBlock.Hash := THash.Empty;
    Feed.NotifySnapshotBlock(SnapshotBlock, bsRemoteCache);

    Assert.IsFalse(Failed);
  finally
    BlackBlocks.Free;
  end;
end;

initialization
  RegisterTestFixture(TBlockFeedTest);
end.