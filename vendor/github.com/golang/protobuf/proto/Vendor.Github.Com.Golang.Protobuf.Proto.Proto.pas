unit Vendor.Github.Com.Golang.Protobuf.Proto.Proto;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Golang.Protobuf.Proto.Buffer,
  Vendor.Github.Com.Golang.Protobuf.Proto.Defaults,
  Vendor.Github.Com.Golang.Protobuf.Proto.Deprecated,
  Vendor.Github.Com.Golang.Protobuf.Proto.Discard,
  Vendor.Github.Com.Golang.Protobuf.Proto.Extensions,
  Vendor.Github.Com.Golang.Protobuf.Proto.Properties,
  Vendor.Github.Com.Golang.Protobuf.Proto.Registry,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextDecode,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextEncode,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wire,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers,
  Vendor.Google.Golang.Org.Protobuf.Proto.Checkinit,
  Vendor.Google.Golang.Org.Protobuf.Proto.Decode,
  Vendor.Google.Golang.Org.Protobuf.Proto.DecodeGen,
  Vendor.Google.Golang.Org.Protobuf.Proto.Doc,
  Vendor.Google.Golang.Org.Protobuf.Proto.Encode,
  Vendor.Google.Golang.Org.Protobuf.Proto.EncodeGen,
  Vendor.Google.Golang.Org.Protobuf.Proto.Equal,
  Vendor.Google.Golang.Org.Protobuf.Proto.Extension,
  Vendor.Google.Golang.Org.Protobuf.Proto.Merge,
  Vendor.Google.Golang.Org.Protobuf.Proto.Messageset,
  Vendor.Google.Golang.Org.Protobuf.Proto.Proto,
  Vendor.Google.Golang.Org.Protobuf.Proto.ProtoMethods,
  Vendor.Google.Golang.Org.Protobuf.Proto.ProtoReflect,
  Vendor.Google.Golang.Org.Protobuf.Proto.Reset,
  Vendor.Google.Golang.Org.Protobuf.Proto.Size,
  Vendor.Google.Golang.Org.Protobuf.Proto.SizeGen,
  Vendor.Google.Golang.Org.Protobuf.Proto.Wrappers;

type
	IMessage = interface
		['{B83F1D1E-109E-4F8B-BA7C-402877D41E24}']
		procedure Reset;
		function String : string;
		procedure ProtoMessage;
	end;

	TRequiredNotSetError = class( Exception )
	public
		constructor Create;
	end;

function Clone( ParaSrc : IMessage ) : IMessage;
procedure Merge( ParaDst, ParaSrc : IMessage );
function Equal( ParaX, ParaY : IMessage ) : Boolean;

implementation

function Clone( ParaSrc : IMessage ) : IMessage;
begin
	// Simplified Clone
	Result := nil;
end;

procedure Merge( ParaDst, ParaSrc : IMessage );
begin
	// Simplified Merge
end;

function Equal( ParaX, ParaY : IMessage ) : Boolean;
begin
	// Simplified Equal
	Result := False;
end;

{ TRequiredNotSetError }

constructor TRequiredNotSetError.Create;
begin
	inherited Create( 'proto: required field not set' );
end;

end.
