unit Common.Types.Address.Test;

interface

uses
	DUnitX.TestFramework,
	System.SysUtils,
	System.JSON,
	System.Classes,
	System.Net.Encoding,
	Common.Types.Address,
	Common.Bytes,
	Common.HexUtil,
	Crypto.Ed25519;

type
	[TestFixture]
	TCommonTypesAddressTests = class(TObject)
	public
		[Test]
		procedure TestCreateContractAddress;
		[Test]
		procedure TestCreateDAddress;
		[Test]
		procedure TestAddressValid;
		[Test]
		procedure TestAddress_UnmarshalJSON;
		[Test]
		procedure TestPubkeyToAddress;
		[Test]
		procedure TestPubkeyBytesToAddress;
		[Test]
		procedure TestAddress_IsContractAddr;
	end;

implementation

procedure TCommonTypesAddressTests.TestCreateContractAddress;
var
	vAddr: TAddress;
begin
	vAddr := CreateContractAddress([1, 2, 3], [1, 2, 3]);
	Assert.IsTrue(IsValidHexAddress(vAddr.ToString), 'Address should be valid');
end;

procedure TCommonTypesAddressTests.TestCreateDAddress;
var
	vZero: TBytes32;
	vRec1, vRec2: TAddressRec;
begin
	FillChar(vZero, SizeOf(vZero), 0);
	vRec1 := CreateAddressWithDeterministic(vZero);
	vRec2 := CreateAddressWithDeterministic(vZero);

	Assert.AreEqual(0, vRec1.Addr.Compare(vRec2.Addr), 'Address should be equal');
	Assert.AreEqual(0, CompareMem(@vRec1.Priv, @vRec2.Priv, SizeOf(TEd25519PrivateKey)), 'Private key should be equal');
end;

procedure TCommonTypesAddressTests.TestAddressValid;
var
	vFakeAddr, vRealAddr: string;
	vRealRec: TAddressRec;
begin
	vFakeAddr := '1231231';
	Assert.IsFalse(IsValidHexAddress(vFakeAddr));

	vFakeAddr := 'vite_bcdc5b9dd0ed0de7de2f0e97c36638e108aa64a2bedc22c0e7';
	Assert.IsFalse(IsValidHexAddress(vFakeAddr));

	vFakeAddr := 'vite_asdc5b9dd0ed0de7de2f0e97c36638e108aa64a2bedc22c0e6';
	Assert.IsFalse(IsValidHexAddress(vFakeAddr));

	vFakeAddr := 'aite_asdc5b9dd0ed0de7de2f0e97c36638e108aa64a2bedc22c0e6';
	Assert.IsFalse(IsValidHexAddress(vFakeAddr));

	vRealAddr := 'vite_bcdc5b9dd0ed0de7de2f0e97c36638e108aa64a2bedc22c0e6';
	Assert.IsTrue(IsValidHexAddress(vRealAddr));

	vRealRec := CreateAddress;
	Assert.IsTrue(IsValidHexAddress(vRealRec.Addr.ToString));

	Assert.IsTrue(IsValidHexAddress(AddressQuota.ToString));
	Assert.IsTrue(IsValidHexAddress(AddressGovernance.ToString));
	Assert.IsTrue(IsValidHexAddress(AddressAsset.ToString));
end;

procedure TCommonTypesAddressTests.TestAddress_UnmarshalJSON;
var
	vAddr0Rec, vAddrRec: TAddressRec;
	vAddr: TAddress;
	vMarshal: TBytes;
	vJsonStr: string;
begin
	vAddr0Rec := CreateAddress;
	vJsonStr := '"' + vAddr0Rec.Addr.ToString + '"';
	vMarshal := TEncoding.UTF8.GetBytes(vJsonStr);

	vAddr.UnmarshalJSON(vMarshal);
	Assert.AreEqual(vAddr0Rec.Addr.ToString, vAddr.ToString);
end;

procedure TCommonTypesAddressTests.TestPubkeyToAddress;
var
	vBytes: TBytes;
	vPublicKey: TEd25519PublicKey;
	vProducer: TAddress;
begin
	try
		vBytes := TBase64Encoding.Create.Decode('meHN+pdEEN1yp34IV8JZRFYqYMB+znhxvSTMRufmeoc=');
		Move(vBytes[0], vPublicKey[0], Length(vBytes));
		vProducer := PubkeyToAddress(vPublicKey);
		Assert.IsFalse(vProducer.IsZero, 'Address should not be zero');
	except
		on E: Exception do
			Assert.Fail('TestPubkeyToAddress failed with exception: ' + E.Message);
	end;
end;

procedure TCommonTypesAddressTests.TestPubkeyBytesToAddress;
var
	vBytes: TBytes;
	vProducer: TAddress;
	vPublicKey: TEd25519PublicKey;
begin
	vBytes := [63, 197, 34, 78, 89, 67, 59, 255, 79, 72, 200, 60, 14, 180, 237, 234, 14, 76, 66, 234, 105, 126, 4, 205, 236, 113, 125, 3, 229, 13, 82, 0];
	Move(vBytes[0], vPublicKey[0], Length(vBytes));
	vProducer := PubkeyToAddress(vPublicKey);
	Assert.IsFalse(IsContractAddr(vProducer));
end;

procedure TCommonTypesAddressTests.TestAddress_IsContractAddr;
var
	vAddr: TAddress;
begin
	vAddr := HexToAddressPanic('vite_42f9a5d93e1e392624b97dfa3d7cab057b79c2489d6bc13682');
	Assert.IsFalse(IsContractAddr(vAddr));
end;

initialization
	TDUnitX.RegisterTestFixture(TCommonTypesAddressTests);
end.
