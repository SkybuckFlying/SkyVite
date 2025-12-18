unit Ledger.Consensus.RollbackProof.Test;

interface

uses
  Delphi.Mocks,
  DUnitX.TestFramework,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Event,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Core,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.RollbackProof,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  V2.Interfaces.Core;

type
  [TestFixture]
  TRollbackProofTest = class(TObject)
  private
    FMockChain: TMock<IChain>;
    FProof: IRollbackProof;
    FNow: TDateTime;
    FTimeIndex: ITimeIndex;
    FSTime, FETime: TDateTime;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestProofEmpty_TimestampInsidePeriod;
    [Test]
    procedure TestProofEmpty_TimestampBeforePeriod;
    [Test]
    procedure TestProofEmpty_TimestampAtStart;
    [Test]
    procedure TestProofEmpty_TimestampAtEnd_ShouldError;
    [Test]
    procedure TestProofEmpty_TimestampAfterEnd_ShouldError;
    [Test]
    procedure TestProofEmpty_ChainError;
  end;

implementation

uses
  System.DateUtils;

{ TRollbackProofTest }

procedure TRollbackProofTest.Setup;
begin
  FMockChain := TMock<IChain>.Create;
  FProof := NewRollbackProof(FMockChain.Instance);
  FNow := Now;
  FTimeIndex := TTimeIndex.Create(FNow, 8 * 1000); // 8 seconds interval
  FSTime := FTimeIndex.Index2Time(9).STime;
  FETime := FTimeIndex.Index2Time(9).ETime;
end;

procedure TRollbackProofTest.TearDown;
begin
  FProof := nil;
  FMockChain := nil;
end;

procedure TRollbackProofTest.TestProofEmpty_TimestampInsidePeriod;
var
  T1: TDateTime;
  Result: Boolean;
  Err: Exception;
begin
  // Timestamp is after start time, so not empty
  T1 := IncSecond(FSTime, 1);
  FMockChain.Setup.WillReturn(TTuple<ISnapshotBlock, Exception>.Create(TSnapshotBlock.Create(T1), nil)).When.GetSnapshotHeaderBeforeTime(FETime);
  TValue.Make(FProof.ProofEmpty(FSTime, FETime), Result, Err);
  Assert.IsNull(Err);
  Assert.IsFalse(Result);
end;

procedure TRollbackProofTest.TestProofEmpty_TimestampBeforePeriod;
var
  T1: TDateTime;
  Result: Boolean;
  Err: Exception;
begin
  // Timestamp is before start time, so empty
  T1 := IncSecond(FSTime, -1);
  FMockChain.Setup.WillReturn(TTuple<ISnapshotBlock, Exception>.Create(TSnapshotBlock.Create(T1), nil)).When.GetSnapshotHeaderBeforeTime(FETime);
  TValue.Make(FProof.ProofEmpty(FSTime, FETime), Result, Err);
  Assert.IsNull(Err);
  Assert.IsTrue(Result);
end;

procedure TRollbackProofTest.TestProofEmpty_TimestampAtStart;
var
  T1: TDateTime;
  Result: Boolean;
  Err: Exception;
begin
  // Timestamp is exactly at start time, so not empty
  T1 := FSTime;
  FMockChain.Setup.WillReturn(TTuple<ISnapshotBlock, Exception>.Create(TSnapshotBlock.Create(T1), nil)).When.GetSnapshotHeaderBeforeTime(FETime);
  TValue.Make(FProof.ProofEmpty(FSTime, FETime), Result, Err);
  Assert.IsNull(Err);
  Assert.IsFalse(Result);
end;

procedure TRollbackProofTest.TestProofEmpty_TimestampAtEnd_ShouldError;
var
  T1: TDateTime;
  Result: Boolean;
  Err: Exception;
begin
  // Timestamp is at end time, which is an invalid state from GetSnapshotHeaderBeforeTime
  T1 := FETime;
  FMockChain.Setup.WillReturn(TTuple<ISnapshotBlock, Exception>.Create(TSnapshotBlock.Create(T1), nil)).When.GetSnapshotHeaderBeforeTime(FETime);
  TValue.Make(FProof.ProofEmpty(FSTime, FETime), Result, Err);
  Assert.IsNotNull(Err);
  Assert.IsFalse(Result);
end;

procedure TRollbackProofTest.TestProofEmpty_TimestampAfterEnd_ShouldError;
var
  T1: TDateTime;
  Result: Boolean;
  Err: Exception;
begin
  // Timestamp is after end time, also an invalid state
  T1 := IncSecond(FETime, 1);
  FMockChain.Setup.WillReturn(TTuple<ISnapshotBlock, Exception>.Create(TSnapshotBlock.Create(T1), nil)).When.GetSnapshotHeaderBeforeTime(FETime);
  TValue.Make(FProof.ProofEmpty(FSTime, FETime), Result, Err);
  Assert.IsNotNull(Err);
  Assert.IsFalse(Result);
end;

procedure TRollbackProofTest.TestProofEmpty_ChainError;
var
  Result: Boolean;
  Err: Exception;
begin
  // Mock the chain to return an error
  FMockChain.Setup.WillReturn(TTuple<ISnapshotBlock, Exception>.Create(nil, Exception.Create('mock error'))).When.GetSnapshotHeaderBeforeTime(FETime);
  TValue.Make(FProof.ProofEmpty(FSTime, FETime), Result, Err);
  Assert.IsNotNull(Err);
  Assert.IsFalse(Result);
end;

initialization
  TDUnitX.RegisterTestFixture(TRollbackProofTest);

end.
