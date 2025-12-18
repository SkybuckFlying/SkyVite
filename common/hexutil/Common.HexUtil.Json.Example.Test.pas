unit Common.HexUtil.Json.Example.Test;

interface

uses
  Common.HexUtil,
  Common.HexUtil.HexUtil,
  Common.HexUtil.HexUtil.Test,
  Common.HexUtil.Json,
  Common.HexUtil.Json.Test,
  DUnitX.TestFramework;

type
  TMyType = array[0..4] of Byte;

  [TestFixture]
  TJsonExampleTest = class
  public
    [Test]
    procedure TestUnmarshalFixedText;
  end;

implementation

uses
  System.SysUtils,
  System.Json;

procedure TJsonExampleTest.TestUnmarshalFixedText;
var
  v1, v2: TMyType;
  vError: Exception;
begin
  vError := nil;
  try
    UnmarshalFixedText('MyType', TEncoding.UTF8.GetBytes('"0x01"'), v1);
  except
    on E: Exception do
    begin
      vError := E;
    end;
  end;
  Assert.IsNotNull(vError);
  Assert.AreEqual('hex string has length 2, want 10 for MyType', vError.Message);

  vError := nil;
  try
    UnmarshalFixedText('MyType', TEncoding.UTF8.GetBytes('"0x0101010101"'), v2);
  except
    on E: Exception do
    begin
      vError := E;
    end;
  end;
  Assert.IsNull(vError);
  Assert.AreEqual(TBytes.Create($1, $1, $1, $1, $1), TBytes(v2));
end;

initialization
  TDUnitX.RegisterTestFixture(TJsonExampleTest);
end.
