unit V2.Ledger.Pool.ChainPool.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  V2.Ledger.Pool.ChainPool,
  V2.Ledger.Pool.Tree,
  V2.Log15;

type
  [TestFixture]
  TChainPoolTest = class(TObject)
  public
    [Test]
    procedure Test_Forkable;
    [Test]
    procedure Test_Forkable2;
  end;

implementation

uses V2.Ledger.Pool.Mock; // Assuming mock objects are here

{ TChainPoolTest }

procedure TChainPoolTest.Test_Forkable;
var
  Tree: ITree;
  DiskChain: IBranchRoot;
  I: Integer;
  Height: TUInt64;
  Hash: THash;
  CP: TChainPool;
  Main: IBranch;
  Knot: IKnot;
  Block: ICommonBlock;
  Snp: TSnippetChain;
  Branches: TDictionary<string, IBranch>;
  Forky, Insertable: Boolean;
  C: IBranch;
begin
  Tree := TTree.Create;
  DiskChain := TMockBranchRoot.Create;

  // Init root
  for I := 0 to 4 do
  begin
    Height := DiskChain.HeadHH.Height;
    Hash := DiskChain.HeadHH.Hash;
    DiskChain.AddHead(TMockCommonBlock.CreateByHH(Height, Hash, 'root'));
  end;
  Assert.AreEqual(TUInt64(5), DiskChain.HeadHH.Height);

  CP := TChainPool.Create('unittest', TLogger.Create('module', 'unittest'));
  CP.Init(Tree, DiskChain);

  Main := Tree.Main;
  Assert.AreEqual(TUInt64(5), Main.HeadHH.Height);
  Assert.AreEqual(TUInt64(5), Main.TailHH.Height);

  for I := 0 to 5 do
  begin
    Height := Main.HeadHH.Height;
    Hash := Main.HeadHH.Hash;
    Tree.AddHead(Main, TMockCommonBlock.CreateByHH(Height, Hash, 'main'));
  end;

  Assert.AreEqual(TUInt64(11), Main.HeadHH.Height);
  Assert.AreEqual(TUInt64(5), Main.TailHH.Height);

  Knot := Main.GetKnot(5, True);

  Block := TMockCommonBlock.CreateByHH(Knot.Height, Knot.Hash, 'snippet');
  Snp := TSnippetChain.Create(Block, 'snippet1');

  Branches := Tree.Branches;
  Forky, Insertable, C := CP.Fork2(Snp, Branches, nil);

  Assert.IsNotNull(C, 'Fork2 should return a branch');
  Assert.AreEqual(Main.ID, C.ID);
  Assert.IsFalse(Insertable);
  Assert.IsTrue(Forky);
end;

procedure TChainPoolTest.Test_Forkable2;
var
  Tree: ITree;
  DiskChain: IBranchRoot;
  Height: TUInt64;
  Hash: THash;
  CP: TChainPool;
  Main: IBranch;
  Block: ICommonBlock;
  Snp: TSnippetChain;
  Branches: TDictionary<string, IBranch>;
  Forky, Insertable: Boolean;
  C: IBranch;
begin
  Tree := TTree.Create;
  DiskChain := TMockBranchRoot.Create;

  Height := DiskChain.HeadHH.Height;
  Hash := DiskChain.HeadHH.Hash;
  DiskChain.AddHead(TMockCommonBlock.CreateByHH(Height, Hash, 'root'));
  Assert.AreEqual(TUInt64(1), DiskChain.HeadHH.Height);

  CP := TChainPool.Create('unittest', TLogger.Create('module', 'unittest'));
  CP.Init(Tree, DiskChain);

  Main := Tree.Main;
  Assert.AreEqual(TUInt64(1), Main.HeadHH.Height);
  Assert.AreEqual(TUInt64(1), Main.TailHH.Height);

  Block := TMockCommonBlock.CreateByHH(1, Main.HeadHH.Hash, 'snippet');
  Snp := TSnippetChain.Create(Block, 'snippet1');

  Branches := Tree.Branches;
  Forky, Insertable, C := CP.Fork2(Snp, Branches, nil);

  Assert.IsNotNull(C, 'Fork2 should return a branch');
  Assert.AreEqual(Main.ID, C.ID);
  Assert.IsTrue(Insertable);
  Assert.IsFalse(Forky);
end;

initialization
  RegisterTest(TChainPoolTest.Suite);
end.
