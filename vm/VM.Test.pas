unit VM.Test;

interface

procedure RunVMTests;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Ledger, GoVite.VM, GoVite.Common, GoVite.Upgrade, // Assumed units
  DUnitX.TestFramework;

// Forward declaration for the mock DB defined in VM.Database.Memory.Test
type TMemoryDatabase = class;

procedure InitForks;
begin
  TUpgradeBox.CleanupUpgradeBox;
  var Points := TDictionary<string, TUpgradePoint>.Create;
  Points.Add('SeedFork', TUpgradePoint.Create(100, 1));
  Points.Add('DexFork', TUpgradePoint.Create(200, 2));
  // ... add other forks as needed
  TUpgradeBox.InitUpgradeBox(TUpgradeBox.NewCustomUpgradeBox(Points));
end;

function PrepareDb(const ATotalSupply: TBigInteger): TTuple<TMemoryDatabase, TAddress, TAddress, THash, TSnapshotBlock, TAccountBlock>;
var
  LDB: TMemoryDatabase;
  LAddr1, LAddr2: TAddress;
  LHash11, LHash12: THash;
  LSnapshot: TSnapshotBlock;
  LBlock12: TAccountBlock;
begin
  // Simplified setup based on Go's prepareDb
  LAddr1 := TAddress.FromHexString('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');
  LAddr2 := TAddress.FromHexString('vite_a3ab3f8ce81936636af4c6f4da41612f11136d71f53bf8fa86');
  
  LSnapshot := TSnapshotBlock.Create;
  LSnapshot.Height := 2;
  LSnapshot.Timestamp := TDateTime.Now;
  
  LDB := TMemoryDatabase.Create(LAddr1, LSnapshot);
  LDB.SetBalance(TViteTokenId, ATotalSupply);

  LHash12 := THash.DataHash(TBytes.Create(1, 2));
  LBlock12 := TAccountBlock.Create;
  LBlock12.Hash := LHash12;
  LBlock12.Height := 2;

  Result := TTuple<TMemoryDatabase, TAddress, TAddress, THash, TSnapshotBlock, TAccountBlock>.Create(LDB, LAddr1, LAddr2, LHash12, LSnapshot, LBlock12);
end;


procedure TestVmRun;
var
  DB: TMemoryDatabase;
  Addr1, Addr2: TAddress;
  Hash12, Hash13, Hash14, Hash15, Hash21, Hash22, Hash23: THash;
  Snapshot: TSnapshotBlock;
  Block12: TAccountBlock;
  ViteTotalSupply, Balance1, Balance2, CreateContractFee: TBigInteger;
  Data13, Data14: TBytes;
  Block13, Block14, Block15, Block21, Block22, Block23: TAccountBlock;
  VM: TVM;
  SendCreateBlock, SendCallBlock, SendCallBlock2, ReceiveCreateBlock, ReceiveCallBlock, ReceiveCallBlock2: IVmAccountBlock;
  IsRetry: Boolean;
  Err: Exception;
begin
  InitForks;
  CreateContractFee := TBigInteger.Parse('10000000000000000000'); // 10 VITE
  ViteTotalSupply := TBigInteger.Multiply(TBigInteger.Create(1e9), TAttovPerVite);
  
  var PrepResult := PrepareDb(ViteTotalSupply);
  DB := PrepResult.Item1;
  Addr1 := PrepResult.Item2;
  Hash12 := PrepResult.Item4;
  Snapshot := PrepResult.Item5;

  Balance1 := ViteTotalSupply.Copy;

  // Send Create
  Data13 := THex.Decode('608060405260858060116000396000f300608060405260043610603e5763ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663f021ab8f81146043575b600080fd5b604c600435604e565b005b6000805490910190555600a165627a7a72305820b8d8d60a46c6ac6569047b17b012aa1ea458271f9bc8078ef0cff9208999d0900029');
  Hash13 := THash.DataHash(TBytes.Create(1, 3));
  Block13 := TAccountBlock.Create;
  Block13.Height := 3;
  Block13.AccountAddress := Addr1;
  Block13.BlockType := TBlockType.SendCreate;
  Block13.PrevHash := Hash12;
  Block13.Amount := TBigInteger.Create(1e18);
  Block13.TokenId := TViteTokenId;
  Block13.Data := Data13;
  Block13.Hash := Hash13;

  VM := TVM.Create(nil);
  try
    DB.Addr := Addr1;
    SendCreateBlock := VM.RunV2(DB, Block13, nil, nil, IsRetry, Err);
  finally
    VM.Free;
  end;

  Balance1 := Balance1 - Block13.Amount - CreateContractFee;
  Assert.IsNotNull(SendCreateBlock, 'SendCreateBlock should not be nil');
  Assert.IsFalse(IsRetry, 'SendCreate should not be a retry');
  Assert.IsNull(Err, 'SendCreate should not produce an error');
  Assert.AreEqual(UInt64(32084), SendCreateBlock.AccountBlock.Quota, 'SendCreate quota mismatch');
  Assert.AreEqual(0, SendCreateBlock.AccountBlock.Fee.CompareTo(CreateContractFee), 'SendCreate fee mismatch');
  Assert.AreEqual(0, DB.GetBalance(TViteTokenId).CompareTo(Balance1), 'Sender balance after create is wrong');
  
  Addr2 := SendCreateBlock.AccountBlock.ToAddress;
  DB.AddAccountBlock(Addr1, Hash13, SendCreateBlock.AccountBlock);

  // Receive Create
  Balance2 := TBigInteger.Zero;
  Hash21 := THash.DataHash(TBytes.Create(2, 1));
  Block21 := TAccountBlock.Create;
  Block21.Height := 1;
  Block21.AccountAddress := Addr2;
  Block21.FromBlockHash := Hash13;
  Block21.BlockType := TBlockType.Receive;
  Block21.Hash := Hash21;

  VM := TVM.Create(nil);
  try
    DB.Addr := Addr2;
    ReceiveCreateBlock := VM.RunV2(DB, Block21, SendCreateBlock.AccountBlock, nil, IsRetry, Err);
  finally
    VM.Free;
  end;

  Balance2 := Balance2 + Block13.Amount;
  Assert.IsNotNull(ReceiveCreateBlock, 'ReceiveCreateBlock should not be nil');
  Assert.AreEqual(0, Length(ReceiveCreateBlock.AccountBlock.SendBlockList), 'ReceiveCreate should not generate send blocks');
  Assert.AreEqual(0, DB.GetBalance(Addr2, TViteTokenId).CompareTo(Balance2), 'Contract balance after create is wrong');

  // ... further tests for call, error handling etc. would follow this pattern.
  
end;

procedure RunVMTests;
begin
  TestVmRun;
  // Other tests from vm_test.go would be added here
end;

end.
