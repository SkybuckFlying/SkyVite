unit Vendor.Github.Com.Aead.Ecdh.Ecdh;

interface

uses
	System.SysUtils,
	System.Classes;

type
	TCurveParams = record
		Name    : string;
		BitSize : Integer;
	end;

	TPrivateKey = TArray<Byte>;
	TPublicKey = TArray<Byte>;
	
	TKeyPair = record
		Private : TPrivateKey;
		Public  : TPublicKey;
		Err     : Error;
	end;

	IKeyExchange = interface
		['{E9A8B6C1-72D4-4B8A-A2F3-C1B5A4D6E7F8}']
		function GenerateKey( ParaRand : IReader ) : TKeyPair;
		function Params : TCurveParams;
		function PublicKey( ParaPrivate : TPrivateKey ) : TPublicKey;
		function Check( ParaPeersPublic : TPublicKey ) : Error;
		function ComputeSecret( ParaPrivate : TPrivateKey; ParaPeersPublic : TPublicKey ) : TBytes;
	end;

implementation

end.
