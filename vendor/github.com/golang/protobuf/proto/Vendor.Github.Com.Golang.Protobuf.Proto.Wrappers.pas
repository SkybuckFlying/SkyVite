unit Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.Golang.Protobuf.Proto.Proto;

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
