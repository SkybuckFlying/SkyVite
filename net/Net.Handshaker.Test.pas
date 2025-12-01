unit handshaker_test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Threading,
	DUnitX.TestFramework,
	GoToDelphi.Helpers.Net,
	Handshaker,
	VNode,
	Types,
	Ed25519,
	Crypto,
	Peer,
	NetTool;

type
	[TestFixture]
	THandshakerTests = class
	public
		[Test]
		procedure TestHandshakeMsg_Serialize;
		[Test]
		procedure TestExtractFileAddress;
		[Test]
		procedure TestHandshake;
		[Test]
		procedure TestHandshaker_MakeHandshake;
		[Test]
		procedure TestHandshaker_VerifyHandshake;
	end;

implementation

uses
	System.Net.Sockets,
	Common.Bytes;

{ THandshakerTests }

procedure THandshakerTests.TestHandshakeMsg_Serialize;
var
	vMsg, vMsg2: THandshakeMsg;
	vData: TBytes;
begin
	vMsg.mVersion := 12;
	vMsg.mNetID := 76;
	vMsg.mName := 'vite';
	vMsg.mID := TNodeID.RandomNodeID;
	vMsg.mTimestamp := TTime.Now.ToUnix - 100;
	vMsg.mHeight := 9384;
	vMsg.mHead := THash.FromBytes(TBytes.Create(1, 2, 4));
	vMsg.mGenesis := THash.FromBytes(TBytes.Create(4, 5, 6));
	vMsg.mKey := TBytes.Create(1, 2, 3);
	vMsg.mToken := TBytes.Create(5, 6, 7);
	vMsg.mFileAddress := TBytes.Create(1, 2);
	vMsg.mPublicAddress := TBytes.Create(3, 4);

	vData := vMsg.Serialize;
	Assert.IsTrue(Length(vData) > 0, 'Serialize returned empty data');

	vMsg2.Deserialize(vData);

	Assert.AreEqual(vMsg.mVersion, vMsg2.mVersion, 'Different version');
	Assert.AreEqual(vMsg.mNetID, vMsg2.mNetID, 'Different net');
	Assert.AreEqual(vMsg.mName, vMsg2.mName, 'Different name');
	Assert.IsTrue(vMsg.mID.IsEqual(vMsg2.mID), 'Different id');
	Assert.AreEqual(vMsg.mTimestamp, vMsg2.mTimestamp, 'Different time');
	Assert.AreEqual(vMsg.mHeight, vMsg2.mHeight, 'Different height');
	Assert.IsTrue(vMsg.mHead.IsEqual(vMsg2.mHead), 'Different head');
	Assert.IsTrue(vMsg.mGenesis.IsEqual(vMsg2.mGenesis), 'Different genesis');
	Assert.IsTrue(TBytes.Equal(vMsg.mKey, vMsg2.mKey), 'Different key');
	Assert.IsTrue(TBytes.Equal(vMsg.mFileAddress, vMsg2.mFileAddress), 'Different fileAddress');
	Assert.IsTrue(TBytes.Equal(vMsg.mPublicAddress, vMsg2.mPublicAddress), 'Different publicAddress');
	Assert.IsTrue(TBytes.Equal(vMsg.mToken, vMsg2.mToken), 'Different token');
end;

procedure THandshakerTests.TestExtractFileAddress;
type
	TSample = record
		mSender: TTCPAddr;
		mBuffer: TBytes;
		mExpected: string;
	end;
var
	vEndPoint: TEndPoint;
	vBuffer: TBytes;
	vSamples: TArray<TSample>;
	vSample: TSample;
	vResult: string;
begin
	vEndPoint.mHost := TEncoding.ASCII.GetBytes('localhost');
	vEndPoint.mPort := 8484;
	vEndPoint.mTyp := htDomain;
	// This is a simplified serialization for the test
	vBuffer := TBytes.Create(Byte(htDomain), Length(vEndPoint.mHost)) + vEndPoint.mHost + TBytes.Create(Byte(vEndPoint.mPort shr 8), Byte(vEndPoint.mPort));


	vSamples := [
		TSample.Create(TTCPAddr.Create(TIPAddress.Create(192, 168, 0, 1), 8483), TBytes.Create(33, 36), '192.168.0.1:8484'),
		TSample.Create(TTCPAddr.Create(TIPAddress.Create(192, 168, 0, 1), 8483), vBuffer, '192.168.0.1:8484'),
		TSample.Create(TTCPAddr.Create(TIPAddress.Create(117, 0, 0, 3), 8483), vBuffer, '117.0.0.3:8484')
	];

	for vSample in vSamples do
	begin
		vResult := ExtractAddress(vSample.mSender, vSample.mBuffer, 8484);
		Assert.AreEqual(vSample.mExpected, vResult, 'Wrong fileAddress');
	end;
end;

procedure THandshakerTests.TestHandshake;
// This test requires a more complex setup with threading and mocking.
// It will be implemented in a future iteration.
begin
	Assert.Inconclusive('TestHandshake not implemented yet');
end;

procedure THandshakerTests.TestHandshaker_MakeHandshake;
var
	vPriv1, vPriv2, vPriv3: TPrivateKey;
	vHandshaker: THandshaker;
	vMockChain: IMockChainReader;
	vTheirId: TNodeID;
	vSecret: TBytes;
	vOur: THandshakeMsg;
begin
	vPriv1 := TEd25519.GenerateKey;
	vPriv2 := TEd25519.GenerateKey;
	vPriv3 := TEd25519.GenerateKey;

	vMockChain := TMockChainReader.Create(111);
	vHandshaker := THandshaker.Create(0, 0, '', TNodeID.FromBytes(vPriv1.PublicKey.Bytes), THash.Empty, nil, nil, vPriv1, vPriv3, nil, nil, nil);
	vHandshaker.SetChain(vMockChain);

	vTheirId := TNodeID.FromBytes(vPriv2.PublicKey.Bytes);
	vSecret := vHandshaker.GetSecret(vTheirId);
	Assert.IsTrue(Length(vSecret) > 0, 'GetSecret failed');

	vOur := vHandshaker.MakeHandshake(vSecret);
	Assert.AreEqual(peNoError, vHandshaker.VerifyHandshake(vOur, vSecret), 'VerifyHandshake failed for signed handshake');

	// Test with nil key (unsigned)
	vHandshaker := THandshaker.Create(0, 0, '', TNodeID.FromBytes(vPriv1.PublicKey.Bytes), THash.Empty, nil, nil, vPriv1, nil, nil, nil, nil);
	vHandshaker.SetChain(vMockChain);
	vOur := vHandshaker.MakeHandshake(vSecret);
	Assert.AreEqual(peNoError, vHandshaker.VerifyHandshake(vOur, vSecret), 'VerifyHandshake failed for unsigned handshake');
end;

procedure THandshakerTests.TestHandshaker_VerifyHandshake;
var
	vPriv1, vPriv2, vPriv3, vPriv4: TPrivateKey;
	vHandshaker: THandshaker;
	vMockChain: IMockChainReader;
	vSecret: TBytes;
	vOur: THandshakeMsg;
	vTheirId: TNodeID;
begin
	vPriv1 := TEd25519.GenerateKey;
	vPriv2 := TEd25519.GenerateKey;
	vPriv3 := TEd25519.GenerateKey;
	vPriv4 := TEd25519.GenerateKey;

	vMockChain := TMockChainReader.Create(111);
	vHandshaker := THandshaker.Create(0, 0, '', TNodeID.FromBytes(vPriv1.PublicKey.Bytes), THash.Empty, nil, nil, vPriv1, vPriv3, nil, nil, nil);
	vHandshaker.SetChain(vMockChain);

	// Helper to create a handshake message
	var MakeTestHandshake := function(ParaPeerKey, ParaMineKey: TPrivateKey; ParaTheirId: TNodeID): THandshakeMsg
	var
		vSecret, vToken, vTimestampBytes: TBytes;
		vHash: THash;
	begin
		Result.mID := TNodeID.FromBytes(ParaPeerKey.PublicKey.Bytes);
		Result.mVersion := 2;
		Result.mNetID := 3;
		Result.mName := 'hello';
		Result.mTimestamp := 1000;
		// ... other fields ...

		vSecret := vHandshaker.GetSecret(ParaTheirId);

		SetLength(vTimestampBytes, 8);
		TBigEndian.PutUint64(vTimestampBytes, Result.mTimestamp);
		vHash := TCrypto.Hash256(vTimestampBytes);
		vToken := TXOR.XOR(vHash.Bytes, vSecret);

		if ParaMineKey <> nil then
		begin
			Result.mKey := ParaMineKey.PublicKey.Bytes;
			Result.mToken := TEd25519.Sign(ParaMineKey, vToken);
		end
		else
		begin
			Result.mToken := vToken;
		end;
	end;

	vTheirId := TNodeID.FromBytes(vPriv1.PublicKey.Bytes);
	vOur := MakeTestHandshake(vPriv2, vPriv4, vTheirId);
	vSecret := vHandshaker.GetSecret(vOur.mID);
	Assert.AreEqual(peNoError, vHandshaker.VerifyHandshake(vOur, vSecret), 'Verification should pass');

	// Test with wrong timestamp
	vOur.mTimestamp := TTime.Now.ToUnix;
	Assert.AreNotEqual(peNoError, vHandshaker.VerifyHandshake(vOur, vSecret), 'Verification should fail with wrong timestamp');

	// Test with nil key
	vOur := MakeTestHandshake(vPriv2, nil, vTheirId);
	Assert.AreEqual(peNoError, vHandshaker.VerifyHandshake(vOur, vSecret), 'Verification should pass for unsigned handshake');
end;

initialization
	RegisterTestFixture(THandshakerTests);
end.
