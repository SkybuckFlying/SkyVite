unit V2.Ledger.OnRoad.PendingCache.Test;

interface

uses
  Ledger.Onroad.Access,
  Ledger.Onroad.Access.Test,
  Ledger.Onroad.Chain.Events,
  Ledger.Onroad.ChainDB.Test,
  Ledger.Onroad.Contract,
  Ledger.Onroad.Contract.Test,
  Ledger.Onroad.Manager,
  Ledger.Onroad.Manager.Test,
  Ledger.Onroad.Pending.Cache,
  Ledger.Onroad.Reader,
  Ledger.Onroad.Reader.Test,
  Ledger.Onroad.Task.Pqueue,
  Ledger.Onroad.Task.Pqueue.Test,
  Ledger.Onroad.TaskProcessor,
  Ledger.Onroad.TaskProcessor.Test,
  Ledger.Onroad.Utils,
  Ledger.Onroad.Utils.Test,
  Ledger.Onroad.Worker,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading,
  TestFramework,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.OnRoad;

type
  [TestFixture]
  TPendingCacheTest = class(TObject)
  private
    FCaller1, FCaller2: TAddress;
    function CreateBlock(AFrom: TAddress; AHeight: TUInt64): IAccountBlock;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestAddAndGet;
    [Test]
    procedure TestIsPendingMapNotSufficient;
    [Test]
    procedure TestInferiorList;
    [Test]
    procedure TestConcurrency;
  end;

implementation

{ TPendingCacheTest }

function TPendingCacheTest.CreateBlock(AFrom: TAddress; AHeight: TUInt64): IAccountBlock;
begin
  Result := TAccountBlock.Create;
  Result.AccountAddress := AFrom;
  Result.Height := AHeight;
  Result.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes(AFrom.ToString + IntToStr(AHeight)));
end;

procedure TPendingCacheTest.Setup;
begin
  FCaller1 := BytesToAddress(TEncoding.UTF8.GetBytes('caller1'));
  FCaller2 := BytesToAddress(TEncoding.UTF8.GetBytes('caller2'));
end;

procedure TPendingCacheTest.TestAddAndGet;
var
  Cache: TCallerPendingMap;
  Block1, Block2, Block3, GotBlock: IAccountBlock;
begin
  Cache := TCallerPendingMap.Create;
  try
    Assert.AreEqual(0, Cache.Len);

    // Add two blocks from caller 1
    Block1 := CreateBlock(FCaller1, 1);
    Block2 := CreateBlock(FCaller1, 2);
    Cache.AddPendingMap(Block1);
    Cache.AddPendingMap(Block2);
    Assert.AreEqual(2, Cache.Len);

    // Add one block from caller 2
    Block3 := CreateBlock(FCaller2, 1);
    Cache.AddPendingMap(Block3);
    Assert.AreEqual(3, Cache.Len);

    // Get blocks - should get one from either caller1 or caller2
    GotBlock := Cache.GetOnePending;
    Assert.IsNotNull(GotBlock);
    Assert.AreEqual(2, Cache.Len);

    GotBlock := Cache.GetOnePending;
    Assert.IsNotNull(GotBlock);
    Assert.AreEqual(1, Cache.Len);

    GotBlock := Cache.GetOnePending;
    Assert.IsNotNull(GotBlock);
    Assert.AreEqual(0, Cache.Len);

    GotBlock := Cache.GetOnePending;
    Assert.IsNull(GotBlock);

  finally
    Cache.Free;
  end;
end;

procedure TPendingCacheTest.TestIsPendingMapNotSufficient;
var
  Cache: TCallerPendingMap;
  I: Integer;
begin
  Cache := TCallerPendingMap.Create;
  try
    Assert.IsTrue(Cache.IsPendingMapNotSufficient);

    for I := 1 to 4 do
      Cache.AddPendingMap(CreateBlock(FCaller1, TUInt64(I)));

    Assert.IsTrue(Cache.IsPendingMapNotSufficient, 'Cache should be not sufficient with 4 items');

    Cache.AddPendingMap(CreateBlock(FCaller1, 5));
    Assert.IsFalse(Cache.IsPendingMapNotSufficient, 'Cache should be sufficient with 5 items');

  finally
    Cache.Free;
  end;
end;

procedure TPendingCacheTest.TestInferiorList;
var
  Cache: TCallerPendingMap;
  Block1: IAccountBlock;
begin
  Cache := TCallerPendingMap.Create;
  try
    Block1 := CreateBlock(FCaller1, 1);
    Cache.AddPendingMap(Block1);
    Assert.AreEqual(1, Cache.Len);
    Assert.IsFalse(Cache.ExistInInferiorList(FCaller1));

    // Add caller1 to inferior list, which should remove its pending blocks
    Cache.AddIntoInferiorList(FCaller1, OUT);
    Assert.AreEqual(0, Cache.Len, 'Pending map should be empty after adding to inferior list');
    Assert.IsTrue(Cache.ExistInInferiorList(FCaller1));

    // Adding a block from an inferior caller should be ignored
    Cache.AddPendingMap(CreateBlock(FCaller1, 2));
    Assert.AreEqual(0, Cache.Len);

    // Release caller
    Assert.AreEqual(1, Cache.ReleaseCallerByState(OUT));
    Assert.IsFalse(Cache.ExistInInferiorList(FCaller1));

    // Now we can add blocks again
    Cache.AddPendingMap(CreateBlock(FCaller1, 3));
    Assert.AreEqual(1, Cache.Len);

  finally
    Cache.Free;
  end;
end;

procedure TPendingCacheTest.TestConcurrency;
var
  Cache: TCallerPendingMap;
  Tasks: TArray<ITask>;
  I: Integer;
  FinalCount: Integer;
begin
  Cache := TCallerPendingMap.Create;
  try
    SetLength(Tasks, 4); // 2 writers, 2 readers

    // Writer tasks
    for I := 0 to 1 do
    begin
      Tasks[I] := TTask.Run(procedure(Index: Integer)
      var
        J: Integer;
        Caller: TAddress;
      begin
        for J := 1 to 100 do
        begin
          if Index = 0 then Caller := FCaller1 else Caller := FCaller2;
          Cache.AddPendingMap(CreateBlock(Caller, TUInt64(J)));
          TThread.Sleep(1);
        end;
      end, I);
    end;

    // Reader tasks
    for I := 2 to 3 do
    begin
      Tasks[I] := TTask.Run(procedure
      var
        Block: IAccountBlock;
      begin
        for var J := 1 to 50 do
        begin
          Block := Cache.GetOnePending;
          TThread.Sleep(2);
        end;
      end);
    end;

    TTask.WaitForAll(Tasks);

    // Total added = 200. Total removed = 100.
    FinalCount := Cache.Len;
    Assert.AreEqual(100, FinalCount, 'Final count should be 100');

  finally
    Cache.Free;
  end;
end;

initialization
  RegisterTest(TPendingCacheTest.Suite);
end.
