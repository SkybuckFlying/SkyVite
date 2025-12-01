unit Common.Mock.Test;

interface

uses
	System.SysUtils,
	DUnitX.TestFramework,
	Common.Mock,
	Common.Types.Address,
	Common.Types.Hash,
	System.Generics.Defaults;

type
	[TestFixture]
	TMockTests = class(TObject)
	public
		[Test]
		procedure TestMockAddress;
		[Test]
		procedure TestMockHash;
		[Test]
		procedure TestMockHashBy;
	end;

implementation

{ TMockTests }

procedure TMockTests.TestMockAddress;
var
	vAddr1, vAddr2, vEmptyAddr : TAddress;
	vComparer : IEqualityComparer<TAddress>;
begin
	// Arrange
	vComparer := TEqualityComparer<TAddress>.Default;
	vEmptyAddr := Default(TAddress);

	// Act
	vAddr1 := MockAddress(1);
	vAddr2 := MockAddress(2);

	// Assert
	Assert.IsFalse(vComparer.Equals(vEmptyAddr, vAddr1), 'MockAddress(1) should not be an empty address.');
	Assert.IsFalse(vComparer.Equals(vEmptyAddr, vAddr2), 'MockAddress(2) should not be an empty address.');
	Assert.IsFalse(vComparer.Equals(vAddr1, vAddr2), 'MockAddress(1) and MockAddress(2) should be different.');
end;

procedure TMockTests.TestMockHash;
var
	vHash1, vHash2, vEmptyHash : THash;
	vComparer : IEqualityComparer<THash>;
begin
	// Arrange
	vComparer := TEqualityComparer<THash>.Default;
	vEmptyHash := Default(THash);

	// Act
	vHash1 := MockHash(1);
	vHash2 := MockHash(2);

	// Assert
	Assert.IsFalse(vComparer.Equals(vEmptyHash, vHash1), 'MockHash(1) should not be an empty hash.');
	Assert.IsFalse(vComparer.Equals(vEmptyHash, vHash2), 'MockHash(2) should not be an empty hash.');
	Assert.IsFalse(vComparer.Equals(vHash1, vHash2), 'MockHash(1) and MockHash(2) should be different.');
end;

procedure TMockTests.TestMockHashBy;
var
	vHash1, vHash2, vHash3, vEmptyHash : THash;
	vComparer : IEqualityComparer<THash>;
begin
	// Arrange
	vComparer := TEqualityComparer<THash>.Default;
	vEmptyHash := Default(THash);

	// Act
	vHash1 := MockHashBy(1, 1);
	vHash2 := MockHashBy(1, 2);
	vHash3 := MockHashBy(2, 1);

	// Assert
	Assert.IsFalse(vComparer.Equals(vEmptyHash, vHash1), 'MockHashBy(1, 1) should not be an empty hash.');
	Assert.IsFalse(vComparer.Equals(vHash1, vHash2), 'MockHashBy(1, 1) and MockHashBy(1, 2) should be different.');
	Assert.IsFalse(vComparer.Equals(vHash1, vHash3), 'MockHashBy(1, 1) and MockHashBy(2, 1) should be different.');
end;

initialization
	TDUnitX.RegisterTestFixture(TMockTests);
end.