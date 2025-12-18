unit Interfaces.Core.Hash.Height.Test;

interface

uses
  DUnitX.TestFramework,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test;

type
  [TestFixture]
  THashHeightTests = class
  public
    [Test]
    procedure ExampleHashHeight;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Interfaces.Core.Hash.Height,
  Common.Types;

{ THashHeightTests }

procedure THashHeightTests.ExampleHashHeight;
var
  vPoints: TArray<TArray<THashHeight>>;
  vExpectedJSON: string;
  vJSONArray, vSubArray: TJSONArray;
  vJSONObject: TJSONObject;
  i, j: Integer;
begin
  SetLength(vPoints, 2);
  SetLength(vPoints[0], 2);
  vPoints[0][0] := THashHeight.Create(100, THash.Create);
  vPoints[0][1] := THashHeight.Create(200, THash.Create);

  SetLength(vPoints[1], 2);
  vPoints[1][0] := THashHeight.Create(201, THash.Create);
  vPoints[1][1] := THashHeight.Create(300, THash.Create);

  vJSONArray := TJSONArray.Create;
  try
    for i := 0 to High(vPoints) do
    begin
      vSubArray := TJSONArray.Create;
      for j := 0 to High(vPoints[i]) do
      begin
        vJSONObject := TJSONObject.Create;
        vJSONObject.AddPair('height', TJSONNumber.Create(vPoints[i][j].Height));
        vJSONObject.AddPair('hash', TJSONString.Create(vPoints[i][j].Hash.ToString));
        vSubArray.Add(vJSONObject);
      end;
      vJSONArray.Add(vSubArray);
    end;

    vExpectedJSON := '[[{"height":100,"hash":"0000000000000000000000000000000000000000000000000000000000000000"},{"height":200,"hash":"0000000000000000000000000000000000000000000000000000000000000000"}],[{"height":201,"hash":"0000000000000000000000000000000000000000000000000000000000000000"},{"height":300,"hash":"0000000000000000000000000000000000000000000000000000000000000000"}]]';
    Assert.AreEqual(vExpectedJSON, vJSONArray.ToString);
  finally
    vJSONArray.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(THashHeightTests);
end.
