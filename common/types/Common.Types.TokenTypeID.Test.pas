unit Common.Types.TokenTypeId.Test;

interface

uses
	System.SysUtils,
	DUnitX.TestFramework,
	Common.Types.TokenTypeId;

const
	ConstCorrectTTI = 'tti_2445f6e5cde8c2c70e446c83';
	ConstWrongTTICheckSum = 'tti_2445f6e5cde8c2c70e446c84';
	ConstWrongTTIMain = 'tti_2445f6e5cae8c2c70e446c83';
	ConstWrongTTILen = 'tti_2445f6e5cae8c2c70e446c8';
	ConstWrongTTIPre = '1tti_2445f6e5cae8c2c70e446c';

type
	[TestFixture]
	TTokenTypeIdTests = class(TObject)
	public
		[Test]
		procedure TestHexToTokenTypeId;
	end;

implementation

{ TTokenTypeIdTests }

procedure TTokenTypeIdTests.TestHexToTokenTypeId;
var
	vTti : TTokenTypeId;
	vRaisedException : Boolean;
begin
	// Test with correct TTI
	vTti := HexToTokenTypeId(ConstCorrectTTI);
	Assert.AreEqual(ConstCorrectTTI, vTti.Hex, 'Expected correct TTI hex representation');

	// Test with wrong checksum
	vRaisedException := False;
	try
		vTti := HexToTokenTypeId(ConstWrongTTICheckSum);
	except
		on E : Exception do
		begin
			vRaisedException := True;
		end;
	end;
	Assert.IsTrue(vRaisedException, 'Expected exception for wrong checksum');

	// Test with wrong main data
	vRaisedException := False;
	try
		vTti := HexToTokenTypeId(ConstWrongTTIMain);
	except
		on E : Exception do
		begin
			vRaisedException := True;
		end;
	end;
	Assert.IsTrue(vRaisedException, 'Expected exception for wrong main data');

	// Test with wrong length
	vRaisedException := False;
	try
		vTti := HexToTokenTypeId(ConstWrongTTILen);
	except
		on E : Exception do
		begin
			vRaisedException := True;
		end;
	end;
	Assert.IsTrue(vRaisedException, 'Expected exception for wrong length');

	// Test with wrong prefix
	vRaisedException := False;
	try
		vTti := HexToTokenTypeId(ConstWrongTTIPre);
	except
		on E : Exception do
		begin
			vRaisedException := True;
		end;
	end;
	Assert.IsTrue(vRaisedException, 'Expected exception for wrong prefix');
end;

end.
