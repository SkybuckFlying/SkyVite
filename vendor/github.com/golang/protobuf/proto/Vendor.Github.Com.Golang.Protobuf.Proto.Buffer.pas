unit Vendor.Github.Com.Golang.Protobuf.Proto.Buffer;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Golang.Protobuf.Proto.Defaults,
  Vendor.Github.Com.Golang.Protobuf.Proto.Deprecated,
  Vendor.Github.Com.Golang.Protobuf.Proto.Discard,
  Vendor.Github.Com.Golang.Protobuf.Proto.Extensions,
  Vendor.Github.Com.Golang.Protobuf.Proto.Properties,
  Vendor.Github.Com.Golang.Protobuf.Proto.Proto,
  Vendor.Github.Com.Golang.Protobuf.Proto.Registry,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextDecode,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextEncode,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wire,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers;

type
	TBuffer = class
	private
		mBuf : TBytes;
		mIdx : Integer;
		mDeterministic : Boolean;
	public
		constructor Create( ParaBuf : TBytes );
		procedure SetDeterministic( ParaDeterministic : Boolean );
		procedure SetBuf( ParaBuf : TBytes );
		procedure Reset;
		function Bytes : TBytes;

		procedure EncodeVarint( ParaV : UInt64 );
		function DecodeVarint : UInt64;

		procedure Marshal( ParaM : IMessage );
		procedure Unmarshal( ParaM : IMessage );
	end;

function EncodeVarint( ParaV : UInt64 ) : TBytes;
function DecodeVarint( ParaB : TBytes; out ParaN : Integer ) : UInt64;

implementation

function EncodeVarint( ParaV : UInt64 ) : TBytes;
var
	vI : Integer;
begin
	SetLength( Result, 10 );
	vI := 0;
	while ParaV >= $80 do
	begin
		Result[ vI ] := Byte( ( ParaV and $7F ) or $80 );
		ParaV := ParaV shr 7;
		Inc( vI );
	end;
	Result[ vI ] := Byte( ParaV );
	SetLength( Result, vI + 1 );
end;

function DecodeVarint( ParaB : TBytes; out ParaN : Integer ) : UInt64;
var
	vI : Integer;
	vB : Byte;
begin
	Result := 0;
	ParaN := 0;
	for vI := 0 to Length( ParaB ) - 1 do
	begin
		vB := ParaB[ vI ];
		Result := Result or ( UInt64( vB and $7F ) shl ( vI * 7 ) );
		if ( vB and $80 ) = 0 then
		begin
			ParaN := vI + 1;
			Exit;
		end;
	end;
end;

{ TBuffer }

constructor TBuffer.Create( ParaBuf : TBytes );
begin
	inherited Create;
	mBuf := ParaBuf;
end;

procedure TBuffer.SetDeterministic( ParaDeterministic : Boolean );
begin
	mDeterministic := ParaDeterministic;
end;

procedure TBuffer.SetBuf( ParaBuf : TBytes );
begin
	mBuf := ParaBuf;
	mIdx := 0;
end;

procedure TBuffer.Reset;
begin
	SetLength( mBuf, 0 );
	mIdx := 0;
end;

function TBuffer.Bytes : TBytes;
begin
	Result := mBuf;
end;

procedure TBuffer.EncodeVarint( ParaV : UInt64 );
var
	vData : TBytes;
begin
	vData := Vendor.Github.Com.Golang.Protobuf.Proto.Buffer.EncodeVarint( ParaV );
	mBuf := mBuf + vData;
end;

function TBuffer.DecodeVarint : UInt64;
var
	vN : Integer;
begin
	Result := Vendor.Github.Com.Golang.Protobuf.Proto.Buffer.DecodeVarint( mBuf, vN );
	Inc( mIdx, vN );
end;

procedure TBuffer.Marshal( ParaM : IMessage );
begin
	// Simplified Marshal
end;

procedure TBuffer.Unmarshal( ParaM : IMessage );
begin
	// Simplified Unmarshal
end;

end.
