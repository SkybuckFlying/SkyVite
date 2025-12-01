unit V2.Ledger.OnRoad.Manager.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  V2.Common.Config,
  V2.Common.Types,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Ledger.OnRoad,
  V2.Ledger.Test_Tools,
  V2.Producer.ProduceEvent,
  V2.Net;

type
  // Mock producer to simulate events
  TMockProducer = class(TInterfacedObject, IProducer)
  private
    FAddr: TAddress;
    FEventFunc: TAccountEventFunc;
  public
    procedure SetAccountEventFunc(AFunc: TAccountEventFunc);
    procedure ProduceEvent(ADuration: TTime);
  end;

  // Mock Vite environment
  TMockVite = class
  private
    FChain: IChain;
    FNet: INetReader;
    FPool: IPool;
    FProducer: IProducer;
  public
    constructor Create(AChain: IChain);
    property Chain: IChain read FChain;
    property Net: INetReader read FNet;
    property Pool: IPool read FPool;
    property Producer: IProducer read FProducer;
  end;


  [TestFixture]
  TManagerTest = class(TObject)
  public
    [Test]
    procedure TestManager_ContractWorker;
  end;

implementation

uses System.DateUtils;

{ TMockProducer }

procedure TMockProducer.SetAccountEventFunc(AFunc: TAccountEventFunc);
begin
  FEventFunc := AFunc;
end;

procedure TMockProducer.ProduceEvent(ADuration: TTime);
var
  Event: TAccountStartEvent;
begin
  if Assigned(FEventFunc) then
  begin
    Event := TAccountStartEvent.Create;
    Event.Gid := DELEGATE_GID;
    Event.Address := FAddr;
    Event.STime := Now;
    Event.ETime := IncSecond(Now, Round(ADuration * 24 * 60 * 60));
    FEventFunc(Event);
  end;
end;

{ TMockVite }

constructor TMockVite.Create(AChain: IChain);
begin
  FChain := AChain;
  // For this test, we can use nil or simple mock objects for Net and Pool
  // as they are not directly involved in the tested logic path.
  FNet := nil; // Or a mock INetReader if needed
  FPool := nil; // Or a mock IPool if needed
  FProducer := TMockProducer.Create;
end;

{ TManagerTest }

procedure TManagerTest.TestManager_ContractWorker;
var
  Chain: IChain;
  TempDir: string;
  Vite: TMockVite;
  Manager: TManager;
  Addr: TAddress;
begin
  Chain := NewTestChainInstance('TestManager_ContractWorker', True, MockGenesis, TempDir);
  try
    Vite := TMockVite.Create(Chain);
    Addr := TAddress.Create; // generateUnlockAddress
    (Vite.Producer as TMockProducer).FAddr := Addr;

    Manager := TManager.Create(Vite.Net, Vite.Pool, Vite.Producer, nil, nil);
    Manager.Init(Vite.Chain);
    Manager.Start;
    try
      // Simulate net state change to done
      (Manager.Net as TMockNetReader).SetSyncState(SyncDone); // Assuming a mock net with this capability

      TThread.CreateAnonymousThread(procedure
      begin
        TThread.Sleep(1000); // time.AfterFunc(1*time.Second, ...)
        WriteLn('test c produceEvent');
        (Vite.Producer as TMockProducer).ProduceEvent(1 / (24*60*60)); // 1 second
      end).Start;

      TThread.Sleep(3000); // time.Sleep(3 * time.Second)
    finally
      Manager.Stop;
    end;
  finally
    ClearChain(Chain, TempDir);
  end;
end;

initialization
  RegisterTest(TManagerTest.Suite);
end.
