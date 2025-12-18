unit Ledger.Chain.State.Interface.Mock;

interface

uses
  Common.DB.XLevelDB,
  Common.DB.XLevelDB.MemDB,
  Common.Types,
  GoMock,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Delete,
  Ledger.Chain.State.Interface,
  Ledger.Chain.State.Iteration,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Redo.Cache,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.Round.Cache.Test,
  Ledger.Chain.State.State.DB,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Transform.Iterator,
  Ledger.Chain.State.Write,
  Ledger.Consensus.Core,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  System.SysUtils;

type
  TMockConsensus = class(TInterfacedObject, IConsensus)
  private
    FCtrl: TMockController;
    FRecorder: TMockConsensusMockRecorder;
  public
    constructor Create(ACtrl: TMockController);
    function EXPECT: TMockConsensusMockRecorder;
    function VerifyAccountProducer(ABlock: TAccountBlock): Boolean;
    function SBPReader: ISBPStatReader;
  end;

  TMockConsensusMockRecorder = class
  private
    FMock: TMockConsensus;
  public
    constructor Create(AMock: TMockConsensus);
    function VerifyAccountProducer(ABlock: TAccountBlock): TMockCall;
    function SBPReader: TMockCall;
  end;

  TMockTimeIndex = class(TInterfacedObject, ITimeIndex)
  private
    FCtrl: TMockController;
    FRecorder: TMockTimeIndexMockRecorder;
  public
    constructor Create(ACtrl: TMockController);
    function EXPECT: TMockTimeIndexMockRecorder;
    function Index2Time(AIndex: UInt64; out AStartTime, AEndTime: TDateTime): void;
    function Time2Index(ATime: TDateTime): UInt64;
  end;

  TMockTimeIndexMockRecorder = class
  private
    FMock: TMockTimeIndex;
  public
    constructor Create(AMock: TMockTimeIndex);
    function Index2Time(AIndex: UInt64): TMockCall;
    function Time2Index(ATime: TDateTime): TMockCall;
  end;

// ... Similar mock implementations for IChain, IRoundCache, IStateDB, IStorageDatabase, IRedo ...

implementation

{ TMockConsensus }

constructor TMockConsensus.Create(ACtrl: TMockController);
begin
  inherited Create;
  FCtrl := ACtrl;
  FRecorder := TMockConsensusMockRecorder.Create(Self);
end;

function TMockConsensus.EXPECT: TMockConsensusMockRecorder;
begin
  Result := FRecorder;
end;

function TMockConsensus.VerifyAccountProducer(ABlock: TAccountBlock): Boolean;
var
  ret: TArray<TValue>;
begin
  FCtrl.T.Helper;
  ret := FCtrl.Call(Self, 'VerifyAccountProducer', [TValue.From<TAccountBlock>(ABlock)]);
  Result := ret[0].AsBoolean;
end;

function TMockConsensus.SBPReader: ISBPStatReader;
var
  ret: TArray<TValue>;
begin
  FCtrl.T.Helper;
  ret := FCtrl.Call(Self, 'SBPReader', []);
  Result := ret[0].AsInterface as ISBPStatReader;
end;

{ TMockConsensusMockRecorder }

constructor TMockConsensusMockRecorder.Create(AMock: TMockConsensus);
begin
  inherited Create;
  FMock := AMock;
end;

function TMockConsensusMockRecorder.VerifyAccountProducer(ABlock: TAccountBlock): TMockCall;
begin
  FMock.FCtrl.T.Helper;
  Result := FMock.FCtrl.RecordCallWithMethodType(FMock, 'VerifyAccountProducer', [TValue.From<TAccountBlock>(ABlock)]);
end;

function TMockConsensusMockRecorder.SBPReader: TMockCall;
begin
  FMock.FCtrl.T.Helper;
  Result := FMock.FCtrl.RecordCallWithMethodType(FMock, 'SBPReader', []);
end;

{ TMockTimeIndex }

constructor TMockTimeIndex.Create(ACtrl: TMockController);
begin
  inherited Create;
  FCtrl := ACtrl;
  FRecorder := TMockTimeIndexMockRecorder.Create(Self);
end;

function TMockTimeIndex.EXPECT: TMockTimeIndexMockRecorder;
begin
  Result := FRecorder;
end;

function TMockTimeIndex.Index2Time(AIndex: UInt64; out AStartTime, AEndTime: TDateTime): void;
var
  ret: TArray<TValue>;
begin
  FCtrl.T.Helper;
  ret := FCtrl.Call(Self, 'Index2Time', [TValue.From<UInt64>(AIndex)]);
  AStartTime := ret[0].AsType<TDateTime>;
  AEndTime := ret[1].AsType<TDateTime>;
end;

function TMockTimeIndex.Time2Index(ATime: TDateTime): UInt64;
var
  ret: TArray<TValue>;
begin
  FCtrl.T.Helper;
  ret := FCtrl.Call(Self, 'Time2Index', [TValue.From<TDateTime>(ATime)]);
  Result := ret[0].AsUInt64;
end;

{ TMockTimeIndexMockRecorder }

constructor TMockTimeIndexMockRecorder.Create(AMock: TMockTimeIndex);
begin
  inherited Create;
  FMock := AMock;
end;

function TMockTimeIndexMockRecorder.Index2Time(AIndex: UInt64): TMockCall;
begin
  FMock.FCtrl.T.Helper;
  Result := FMock.FCtrl.RecordCallWithMethodType(FMock, 'Index2Time', [TValue.From<UInt64>(AIndex)]);
end;

function TMockTimeIndexMockRecorder.Time2Index(ATime: TDateTime): TMockCall;
begin
  FMock.FCtrl.T.Helper;
  Result := FMock.FCtrl.RecordCallWithMethodType(FMock, 'Time2Index', [TValue.From<TDateTime>(ATime)]);
end;

end.
