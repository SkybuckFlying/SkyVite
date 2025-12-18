unit Common.Types.Hash.Test;

interface

uses
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  DUnitX.TestFramework,
  System.SysUtils;

type
	[TestFixture]
	TCommonTypesHashTests = class(TObject)
	public
		[Test]
		procedure TestHashCmp;
	end;

implementation

procedure TCommonTypesHashTests.TestHashCmp;
var
	vHash1, vHash2: THash;
	vResult: Integer;
begin
	try
		vHash1 := HexToHash('0000000000000000000000000000000000000000000000000000000000000001');
		vHash2 := HexToHash('0000000000000000000000000000000000000000000000000000000000000002');

		vResult := vHash1.Cmp(vHash2);

		Assert.IsTrue(vResult = -1, 'Comparison should return -1');
	except
		on E: Exception do
		begin
			Assert.Fail('TestHashCmp failed with exception: ' + E.Message);
		end;
	end;
end;

initialization
	TDUnitX.RegisterTestFixture(TCommonTypesHashTests);
end.
