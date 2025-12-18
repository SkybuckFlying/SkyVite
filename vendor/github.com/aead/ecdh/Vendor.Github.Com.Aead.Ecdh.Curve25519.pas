unit Vendor.Github.Com.Aead.Ecdh.Curve25519;

interface

uses
	System.SysUtils,
	System.Classes,
	Vendor.Github.Com.Aead.Ecdh.Ecdh,
	Vendor.Golang.Org.X.Crypto.Curve25519;

type
	Tecdh25519 = class(TInterfacedObject, IKeyExchange)
	public
		function GenerateKey( ParaRandom : IReader ) : TKeyPair;
		function Params : TCurveParams;
		function PublicKey( ParaPrivate : TPrivateKey ) : TPublicKey;
		function Check( ParaPeersPublic : TPublicKey ) : Error;
		function ComputeSecret( ParaPrivate : TPrivateKey; ParaPeersPublic : TPublicKey ) : TBytes;
	end;

function X25519 : IKeyExchange;

implementation

var
	mCurve25519Params : TCurveParams;

function X25519 : IKeyExchange;
begin
	try
		Result := Tecdh25519.Create;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed for Tecdh25519' );
		end;
		on E: Exception do
		begin
			raise Exception.Create( 'Unexpected error during Tecdh25519 creation: ' + E.Message );
		end;
	end;
end;

{ Tecdh25519 }

function Tecdh25519.GenerateKey( ParaRandom : IReader ) : TKeyPair;
var
	vPri, vPub : TArray<Byte>;
	vErr : Error;
begin
	if ParaRandom = nil then
	begin
		ParaRandom := TRand.Reader;
	end;

	vPri := nil;
	vPub := nil;
	try
		SetLength( vPri, 32 );
		SetLength( vPub, 32 );
		
		vErr := TIO.ReadFull( ParaRandom, vPri );
		if vErr <> nil then
		begin
			Result.Err := vErr;
			Exit;
		end;

		// From https://cr.yp.to/ecdh.html
		vPri[0] := vPri[0] and 248;
		vPri[31] := vPri[31] and 127;
		vPri[31] := vPri[31] or 64;

		TCurve25519.ScalarBaseMult( vPub, vPri );

		Result.Private := vPri;
		Result.Public := vPub;
		Result.Err := nil;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed during GenerateKey' );
		end;
	end;
end;

function Tecdh25519.Params : TCurveParams;
begin
	Result := mCurve25519Params;
end;

function Tecdh25519.PublicKey( ParaPrivate : TPrivateKey ) : TPublicKey;
var
	vPri, vPub : TArray<Byte>;
begin
	vPri := nil;
	vPub := nil;
	try
		SetLength( vPri, 32 );
		SetLength( vPub, 32 );
		
		if not TCheck.CheckType( vPri, ParaPrivate ) then
		begin
			panic( 'ecdh: unexpected type of private key' );
		end;

		TCurve25519.ScalarBaseMult( vPub, vPri );

		Result := vPub;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed during PublicKey derivation' );
		end;
	end;
end;

function Tecdh25519.Check( ParaPeersPublic : TPublicKey ) : Error;
var
	vDummy : TArray<Byte>;
begin
	vDummy := nil;
	try
		SetLength( vDummy, 32 );
		if not TCheck.CheckType( vDummy, ParaPeersPublic ) then
		begin
			Result := TError.New( 'unexpected type of peers public key' );
		end else
		begin
			Result := nil;
		end;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed during Check' );
		end;
	end;
end;

function Tecdh25519.ComputeSecret( ParaPrivate : TPrivateKey; ParaPeersPublic : TPublicKey ) : TBytes;
var
	vSec, vPri, vPub : TArray<Byte>;
begin
	vSec := nil;
	vPri := nil;
	vPub := nil;
	try
		SetLength( vSec, 32 );
		SetLength( vPri, 32 );
		SetLength( vPub, 32 );
		
		if not TCheck.CheckType( vPri, ParaPrivate ) then
		begin
			panic( 'ecdh: unexpected type of private key' );
		end;
		if not TCheck.CheckType( vPub, ParaPeersPublic ) then
		begin
			panic( 'ecdh: unexpected type of peers public key' );
		end;

		TCurve25519.ScalarMult( vSec, vPri, vPub );

		Result := vSec;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed during ComputeSecret' );
		end;
	end;
end;

initialization
begin
	mCurve25519Params.Name := 'Curve25519';
	mCurve25519Params.BitSize := 255;
end;

end.
