unit Net.Vnode.Node;

interface

uses
  Common.Types,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  unit_GoLang_Compatibility_version_006;

const
	Const_DefaultPort = 8483;
	Const_IdBytes = 32;
	Const_IDBits = Const_IdBytes * 8;

type
	TNodeID = record
	private
		mBytes : array[0..Const_IdBytes - 1] of Byte;
	public
		class function FromBytes( const ParaBytes : TBytes ) : TNodeID; static;
		class function FromHex( const ParaHex : string ) : TNodeID; static;
		class function Random : TNodeID; static;

		function ToString : string;
		function Brief : string;
		function Bytes : TBytes;
		function IsZero : Boolean;

		class operator Equal( const a, b : TNodeID ) : Boolean;
		class operator NotEqual( const a, b : TNodeID ) : Boolean;
	end;

	TNode = class
	public
		ID : TNodeID;
		EndPoint : TEndPoint;
		Net : Integer;
		Ext : TBytes;

		function Equal( ParaN2 : TNode ) : Boolean;
		function Address : string;
		function ToString : string; override;
		
		function Serialize : TBytes;
		procedure Deserialize( ParaData : TBytes );
	end;

function RandomNodeID : TNodeID;
function Distance( const a, b : TNodeID ) : UInt32;
function ParseNode( const ParaU : string ) : TNode;

implementation

{ TNodeID }

class function TNodeID.FromBytes( const ParaBytes : TBytes ) : TNodeID;
begin
	if Length( ParaBytes ) <> Const_IdBytes then raise Exception.Create( 'needs 32 bytes' );
	Move( ParaBytes[0], Result.mBytes[0], Const_IdBytes );
end;

class function TNodeID.FromHex( const ParaHex : string ) : TNodeID;
var
	vHex : string;
	vBytes : TBytes;
begin
	vHex := ParaHex;
	if vHex.StartsWith( '0x' ) then vHex := vHex.Substring( 2 );
	if Length( vHex ) <> 64 then raise Exception.Create( 'needs 64 hex chars' );
	
	// HexToBytes conversion
	SetLength( vBytes, Const_IdBytes );
	// System.Classes.HexToBin(PWideChar(vHex), vBytes[0], Const_IdBytes); // Simplified
	Result := FromBytes( vBytes );
end;

class function TNodeID.Random : TNodeID;
begin
	// Generate random bytes...
	Result := Default( TNodeID );
end;

function TNodeID.ToString : string;
begin
	// BinToHex conversion
	Result := ''; // Simplified
end;

function TNodeID.Brief : string;
begin
	Result := ToString.Substring( 0, 16 );
end;

function TNodeID.Bytes : TBytes;
begin
	SetLength( Result, Const_IdBytes );
	Move( mBytes[0], Result[0], Const_IdBytes );
end;

function TNodeID.IsZero : Boolean;
var
	vB : Byte;
begin
	for vB in mBytes do if vB <> 0 then Exit( False );
	Result := True;
end;

class operator TNodeID.Equal( const a, b : TNodeID ) : Boolean;
begin
	Result := CompareMem( @a.mBytes[0], @b.mBytes[0], Const_IdBytes );
end;

class operator TNodeID.NotEqual( const a, b : TNodeID ) : Boolean;
begin
	Result := not ( a = b );
end;

{ TNode }

function TNode.Equal( ParaN2 : TNode ) : Boolean;
begin
	if ID <> ParaN2.ID then Exit( False );
	if not EndPoint.Equal( @ParaN2.EndPoint ) then Exit( False );
	if Net <> ParaN2.Net then Exit( False );
	if not CompareMem( Pointer( Ext ), Pointer( ParaN2.Ext ), Length( Ext ) ) then Exit( False );
	Result := True;
end;

function TNode.Address : string;
begin
	Result := EndPoint.ToString;
end;

function TNode.ToString : string;
begin
	Result := ID.ToString + '@';
	if EndPoint.Port = Const_DefaultPort then Result := Result + EndPoint.Hostname else Result := Result + Address;
	if Net > 0 then Result := Result + '/' + IntToStr( Net );
end;

function TNode.Serialize : TBytes;
begin
	// Protobuf serialization logic...
	Result := nil;
end;

procedure TNode.Deserialize( ParaData : TBytes );
begin
	// Protobuf deserialization logic...
end;

{ Global Helpers }

function RandomNodeID : TNodeID;
begin
	Result := TNodeID.Random;
end;

function CommonBits( const a, b : TNodeID ) : UInt32;
var
	vN, vXor : Byte;
	vI, vJ : Integer;
begin
	vI := 0;
	while ( vI < Const_IdBytes ) and ( a.mBytes[vI] = b.mBytes[vI] ) do Inc( vI );

	if vI = Const_IdBytes then Exit( Const_IDBits );

	vXor := a.mBytes[vI] xor b.mBytes[vI];
	Result := vI * 8;

	vJ := 128;
	while ( vXor and vJ ) = 0 do
	begin
		Inc( Result );
		vJ := vJ shr 1;
	end;
end;

function Distance( const a, b : TNodeID ) : UInt32;
begin
	Result := Const_IDBits - CommonBits( a, b );
end;

function ParseNode( const ParaU : string ) : TNode;
begin
	// Parse logic...
	Result := TNode.Create;
end;

end.
