unit V2.Ledger.OnRoad.Access.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  V2.Common.Config,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.Test_Tools;

type
  [TestFixture]
  TOnRoadAccessTest = class(TObject)
  private
    FChain: IChain;
    FTempDir: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestOnRoad;
  end;

implementation

{ TOnRoadAccessTest }

procedure TOnRoadAccessTest.Setup;
begin
  FChain := NewTestChainInstance('TestOnRoadAccess', True, MockGenesis, FTempDir);
end;

procedure TOnRoadAccessTest.TearDown;
begin
  ClearChain(FChain, FTempDir);
end;

procedure TOnRoadAccessTest.TestOnRoad;
var
  PageNum: Integer;
  Addr: TAddress;
  BlockList: TArray<IAccountBlock>;
  Block: IAccountBlock;
begin
  PageNum := 0;
  Addr := HexToAddress('vite_0000000000000000000000000000000000000003f6af7459b9');
  while True do
  begin
    BlockList := FChain.GetOnRoadBlocksByAddr(Addr, PageNum, 100);
    if Length(BlockList) <= 0 then
      Break;

    WriteLn(Format('Found %d blocks', [Length(BlockList)]));
    for Block in BlockList do
    begin
      WriteLn(Format('hash: %s, height: %d', [Block.Hash.ToString, Block.Height]));
    end;
    Inc(PageNum);
  end;
end;

initialization
  RegisterTest(TOnRoadAccessTest.Suite);

end.
