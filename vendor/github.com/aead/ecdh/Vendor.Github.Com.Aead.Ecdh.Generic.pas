unit Vendor.Github.Com.Aead.Ecdh.Generic;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Math.Vectors,
	Vendor.Github.Com.Aead.Ecdh.Ecdh;

type
	TPoint = record
		X, Y : TBigInt;
	end;

	TgenericCurve = class(TInterfacedObject, IKeyExchange)
	private
		mCurve : ICurve;
	public
		constructor Create( ParaCurve : ICurve );
		function GenerateKey( ParaRandom : IReader ) : TKeyPair;
		function Params : TCurveParams;
		function PublicKey( ParaPrivate : TPrivateKey ) : TPublicKey;
		function Check( ParaPeersPublic : TPublicKey ) : Error;
		function ComputeSecret( ParaPrivate : TPrivateKey; ParaPeersPublic : TPublicKey ) : TBytes;
	end;

function Generic( ParaC : ICurve ) : IKeyExchange;

implementation

function Generic( ParaC : ICurve ) : IKeyExchange;
begin
	if ParaC = nil then
	begin
		panic( 'ecdh: curve is nil' );
	end;
	
	try
		Result := TgenericCurve.Create( ParaC );
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed for TgenericCurve' );
		end;
	end;
end;

{ TgenericCurve }

constructor TgenericCurve.Create( ParaCurve : ICurve );
begin
	inherited Create;
	mCurve := ParaCurve;
end;

function TgenericCurve.GenerateKey( ParaRandom : IReader ) : TKeyPair;
var
	vPrivate : TPrivateKey;
	vX, vY : TBigInt;
	vErr : Error;
begin
	if ParaRandom = nil then
	begin
		ParaRandom := TRand.Reader;
	end;

	try
		vErr := TCurve.GenerateKey( mCurve, ParaRandom, vPrivate, vX, vY );
		if vErr <> nil then
		begin
			Result.Private := nil;
			Result.Err := vErr;
			Exit;
		end;
		
		Result.Private := vPrivate;
		Result.Public := TPoint.Create( vX, vY );
		Result.Err := nil;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed during GenerateKey' );
		end;
	end;
end;

function TgenericCurve.Params : TCurveParams;
var
	vP : ICurveParams;
begin
	vP := mCurve.Params;
	Result.Name := vP.Name;
	Result.BitSize := vP.BitSize;
end;

function TgenericCurve.PublicKey( ParaPrivate : TPrivateKey ) : TPublicKey;
var
	vKey : TBytes;
	vX, vY : TBigInt;
	vN : TBigInt;
begin
	if not TCheck.CheckPrivateKey( ParaPrivate, vKey ) then
	begin
		panic( 'ecdh: unexpected type of private key' );
	end;

	vN := mCurve.Params.N;
	if TBigInt.SetBytes( vKey ).Cmp( vN ) >= 0 then
	begin
		panic( 'ecdh: private key cannot used with given curve' );
	end;

	mCurve.ScalarBaseMult( vKey, vX, vY );
	Result := TPoint.Create( vX, vY );
end;

function TgenericCurve.Check( ParaPeersPublic : TPublicKey ) : Error;
var
	vKey : TPoint;
begin
	if not TCheck.CheckPublicKey( ParaPeersPublic, vKey ) then
	begin
		Result := TError.New( 'unexpected type of peers public key' );
		Exit;
	end;
	
	if not mCurve.IsOnCurve( vKey.X, vKey.Y ) then
	begin
		Result := TError.New( 'peer''s public key is not on curve' );
		Exit;
	end;
	
	Result := nil;
end;

function TgenericCurve.ComputeSecret( ParaPrivate : TPrivateKey; ParaPeersPublic : TPublicKey ) : TBytes;
var
	vPriKey : TBytes;
	vPubKey : TPoint;
	vSX, vSY : TBigInt;
begin
	if not TCheck.CheckPrivateKey( ParaPrivate, vPriKey ) then
	begin
		panic( 'ecdh: unexpected type of private key' );
	end;
	
	if not TCheck.CheckPublicKey( ParaPeersPublic, vPubKey ) then
	begin
		panic( 'ecdh: unexpected type of peers public key' );
	end;

	mCurve.ScalarMult( vPubKey.X, vPubKey.Y, vPriKey, vSX, vSY );

	Result := vSX.Bytes;
end;

end.
