unit Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers;

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
  Vendor.Github.Com.Golang.Protobuf.Proto.TextEncode,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wire;

type
	TDoubleValue = class( TInterfacedObject, IMessage )
	public
		mValue : Double;
		procedure Reset;
		function String : string;
		procedure ProtoMessage;
	end;

	TFloatValue = class( TInterfacedObject, IMessage )
	public
		mValue : Single;
		procedure Reset;
		function String : string;
		procedure ProtoMessage;
	end;

implementation

{ TDoubleValue }

procedure TDoubleValue.Reset; begin end;
function TDoubleValue.String : string; begin Result := FloatToStr( mValue ); end;
procedure TDoubleValue.ProtoMessage; begin end;

{ TFloatValue }

procedure TFloatValue.Reset; begin end;
function TFloatValue.String : string; begin Result := FloatToStr( mValue ); end;
procedure TFloatValue.ProtoMessage; begin end;

end.
