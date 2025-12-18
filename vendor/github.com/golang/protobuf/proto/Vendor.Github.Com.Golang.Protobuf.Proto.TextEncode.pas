unit Vendor.Github.Com.Golang.Protobuf.Proto.TextEncode;

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
  Vendor.Github.Com.Golang.Protobuf.Proto.Proto,
  Vendor.Github.Com.Golang.Protobuf.Proto.Registry,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextDecode,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wire,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers;

type
	TTextMarshaler = class
	public
		mCompact   : Boolean;
		mExpandAny : Boolean;

		function Marshal( ParaM : IMessage ) : string;
	end;

function MarshalTextString( ParaM : IMessage ) : string;

implementation

function MarshalTextString( ParaM : IMessage ) : string;
var
	vM : TTextMarshaler;
begin
	vM := TTextMarshaler.Create;
	try
		Result := vM.Marshal( ParaM );
	finally
		vM.Free;
	end;
end;

{ TTextMarshaler }

function TTextMarshaler.Marshal( ParaM : IMessage ) : string;
begin
	if ParaM = nil then
		Exit( '<nil>' );
	Result := ParaM.String;
end;

end.
