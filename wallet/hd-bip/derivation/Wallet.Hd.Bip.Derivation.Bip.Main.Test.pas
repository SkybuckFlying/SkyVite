unit hd_bip.derivation.bip_main_test;

interface

uses
  DUnitX.TestFramework, hd_bip.derivation.bip_example, SysUtils;

type
  [TestFixture]
  TBipMainTest = class(TObject)
  public
    [Test]
    procedure TestExampleMnemonic12;
    [Test]
    procedure TestExampleMnemonic24;
  end;

implementation

procedure TBipMainTest.TestExampleMnemonic12;
var
  b: TBytes;
begin
  RandomMnemonic12('');
  RandomMnemonic12('123456');
  SetLength(b, 16);
  Menmonic(b, '');
end;

procedure TBipMainTest.TestExampleMnemonic24;
begin
  RandomMnemonic24('');
  RandomMnemonic24('123456');
end;

initialization
  TDUnitX.RegisterTestFixture(TBipMainTest);

end.
