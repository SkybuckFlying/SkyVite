unit V2.Ledger.Verifier.SnapshotVerifier.Test;

interface

uses
  Ledger.Verifier.Account.Verifier,
  Ledger.Verifier.Common,
  Ledger.Verifier.Errors,
  Ledger.Verifier.Reader,
  Ledger.Verifier.Snapshot.Verifier,
  Ledger.Verifier.Verifier,
  Mock.V2.Interfaces   // Assuming mock consensus verifier,
  Mock.V2.Ledger.Chain // Assuming mock chain implementation,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  TestFramework,
  V2.Common.Types,
  V2.Crypto,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Ledger.Chain,
  V2.Ledger.Verifier;

type
  [TestFixture]
  TSnapshotVerifierTest = class(TObject)
  private
    FMockChain: TMockChain;
    FMockConsensus: TMockConsensusVerifier;
    FVerifier: TSnapshotVerifier;
    procedure SetupMocks;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVerifyNetSb_Valid;
    [Test]
    procedure TestVerifyNetSb_InvalidSignature;
    [Test]
    procedure TestVerifyNetSb_FutureTimestamp;
    [Test]
    procedure TestVerifySelf_Valid;
    [Test]
    procedure TestVerifySelf_InvalidPrevHash;
    [Test]
    procedure TestVerifyReferred_GoldenPath;
    [Test]
    procedure TestVerifyReferred_PendingAccount;
    [Test]
    procedure TestVerifyReferred_ForkedAccount;
    [Test]
    procedure TestVerifyReferred_InvalidProducer;
  end;

implementation

uses System.DateUtils;

{ TSnapshotVerifierTest }

procedure TSnapshotVerifierTest.Setup;
begin
  SetupMocks;
  FVerifier := TSnapshotVerifier.Create(FMockChain, FMockConsensus);
end;

procedure TSnapshotVerifierTest.TearDown;
begin
  FVerifier := nil;
  FMockChain := nil;
  FMockConsensus := nil;
end;

procedure TSnapshotVerifierTest.SetupMocks;
begin
  FMockChain := TMockChain.Create;
  FMockConsensus := TMockConsensusVerifier.Create;
end;

procedure TSnapshotVerifierTest.TestVerifyNetSb_Valid;
var
  Block: ISnapshotBlock;
  PrivKey: TBytes;
  PubKey: TBytes;
begin
  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.Timestamp := Now;
  // Sign the block
  PrivKey := TEd25519.NewKeyFromSeed(TEncoding.UTF8.GetBytes('test_seed'));
  PubKey := TEd25519.PublicKey(PrivKey);
  Block.PublicKey := PubKey;
  Block.Hash := Block.ComputeHash;
  Block.Signature := TEd25519.Sign(PrivKey, Block.Hash.Bytes);

  Assert.WillNotRaise(procedure
  begin
    FVerifier.VerifyNetSb(Block);
  end);
end;

procedure TSnapshotVerifierTest.TestVerifyNetSb_InvalidSignature;
var
  Block: ISnapshotBlock;
  PrivKey: TBytes;
  PubKey: TBytes;
begin
  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.Timestamp := Now;
  PrivKey := TEd25519.NewKeyFromSeed(TEncoding.UTF8.GetBytes('test_seed'));
  PubKey := TEd25519.PublicKey(PrivKey);
  Block.PublicKey := PubKey;
  Block.Hash := Block.ComputeHash;
  Block.Signature := TEncoding.UTF8.GetBytes('invalid_signature'); // Invalid signature

  Assert.WillRaise(procedure
  begin
    FVerifier.VerifyNetSb(Block);
  end, EVerifyError, 'Should fail with signature error');
end;

procedure TSnapshotVerifierTest.TestVerifyNetSb_FutureTimestamp;
var
  Block: ISnapshotBlock;
begin
  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.Timestamp := IncHour(Now, 2); // 2 hours in the future

  Assert.WillRaise(procedure
  begin
    FVerifier.VerifyNetSb(Block);
  end, EProgrammer, 'Should fail with future timestamp error');
end;

procedure TSnapshotVerifierTest.TestVerifySelf_Valid;
var
  Head, Block: ISnapshotBlock;
begin
  Head := TSnapshotBlock.Create;
  Head.Height := 9;
  Head.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes('head_hash'));
  FMockChain.Setup.WillReturn(Head).When.GetLatestSnapshotBlock;

  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.PrevHash := Head.Hash;

  var Stat := FVerifier.NewVerifyStat(Block);
  Assert.WillNotRaise(procedure
  begin
    FVerifier.VerifySelf(Block, Stat);
  end);
end;

procedure TSnapshotVerifierTest.TestVerifySelf_InvalidPrevHash;
var
  Head, Block: ISnapshotBlock;
begin
  Head := TSnapshotBlock.Create;
  Head.Height := 9;
  Head.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes('head_hash'));
  FMockChain.Setup.WillReturn(Head).When.GetLatestSnapshotBlock;

  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.PrevHash := TDataHash.Create(TEncoding.UTF8.GetBytes('wrong_hash'));

  var Stat := FVerifier.NewVerifyStat(Block);
  Assert.WillRaise(procedure
  begin
    FVerifier.VerifySelf(Block, Stat);
  end, EProgrammer, 'Should fail with previous hash mismatch');
end;

procedure TSnapshotVerifierTest.TestVerifyReferred_GoldenPath;
var
  Block: ISnapshotBlock;
  Stat: ISnapshotBlockVerifyStat;
begin
  // Setup for a completely valid block
  var Head := TSnapshotBlock.Create;
  Head.Height := 9;
  Head.Timestamp := IncSecond(Now, -5);
  FMockChain.Setup.WillReturn(Head).When.GetLatestSnapshotBlock;

  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.Timestamp := Now;
  Block.PrevHash := Head.Hash;
  // ... setup accounts and producer ...
  FMockConsensus.Setup.WillReturn(True).When.VerifySnapshotProducer(Block);

  Stat := FVerifier.VerifyReferred(Block);
  Assert.AreEqual(SUCCESS, Stat.VerifyResult);
end;

procedure TSnapshotVerifierTest.TestVerifyReferred_PendingAccount;
var
  Block: ISnapshotBlock;
  Stat: ISnapshotBlockVerifyStat;
  AccAddr: TAddress;
begin
  // Setup for a block with a missing account reference
  var Head := TSnapshotBlock.Create;
  Head.Height := 9;
  Head.Timestamp := IncSecond(Now, -5);
  FMockChain.Setup.WillReturn(Head).When.GetLatestSnapshotBlock;

  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.Timestamp := Now;
  Block.PrevHash := Head.Hash;
  AccAddr := TAddress.Create;
  Block.SnapshotContent.Add(AccAddr, THashHeight.Create(TDataHash.Create, 1));

  // Mock chain to return nil for the account block
  FMockChain.Setup.WillReturn(nil).When.GetAccountBlockByHeight(AccAddr, 1);

  Stat := FVerifier.VerifyReferred(Block);
  Assert.AreEqual(PENDING, Stat.VerifyResult);
  Assert.AreEqual(PENDING, Stat.Results[AccAddr]);
end;

procedure TSnapshotVerifierTest.TestVerifyReferred_ForkedAccount;
var
  Block, ForkedBlock: ISnapshotBlock;
  Stat: ISnapshotBlockVerifyStat;
  AccAddr: TAddress;
begin
  // Setup for a block with a mismatched account hash
  var Head := TSnapshotBlock.Create;
  Head.Height := 9;
  Head.Timestamp := IncSecond(Now, -5);
  FMockChain.Setup.WillReturn(Head).When.GetLatestSnapshotBlock;

  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.Timestamp := Now;
  Block.PrevHash := Head.Hash;
  AccAddr := TAddress.Create;
  Block.SnapshotContent.Add(AccAddr, THashHeight.Create(TDataHash.Create(TEncoding.UTF8.GetBytes('correct_hash')), 1));

  // Mock chain to return a block with a different hash
  ForkedBlock := TAccountBlock.Create;
  ForkedBlock.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes('wrong_hash'));
  FMockChain.Setup.WillReturn(ForkedBlock).When.GetAccountBlockByHeight(AccAddr, 1);

  Stat := FVerifier.VerifyReferred(Block);
  Assert.AreEqual(FAIL, Stat.VerifyResult);
  Assert.AreEqual(FAIL, Stat.Results[AccAddr]);
end;

procedure TSnapshotVerifierTest.TestVerifyReferred_InvalidProducer;
var
  Block: ISnapshotBlock;
  Stat: ISnapshotBlockVerifyStat;
begin
  // Setup for a block with an invalid producer
  var Head := TSnapshotBlock.Create;
  Head.Height := 9;
  Head.Timestamp := IncSecond(Now, -5);
  FMockChain.Setup.WillReturn(Head).When.GetLatestSnapshotBlock;

  Block := TSnapshotBlock.Create;
  Block.Height := 10;
  Block.Timestamp := Now;
  Block.PrevHash := Head.Hash;

  // Mock consensus to fail producer verification
  FMockConsensus.Setup.WillReturn(False).When.VerifySnapshotProducer(Block);

  Stat := FVerifier.VerifyReferred(Block);
  Assert.AreEqual(FAIL, Stat.VerifyResult);
end;

initialization
  RegisterTest(TSnapshotVerifierTest.Suite);
end.
