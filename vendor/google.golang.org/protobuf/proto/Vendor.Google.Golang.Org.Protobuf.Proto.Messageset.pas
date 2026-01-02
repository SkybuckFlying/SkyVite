unit Vendor.Google.Golang.Org.Protobuf.Proto.Messageset;

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Proto.Encode,
  Vendor.Google.Golang.Org.Protobuf.Proto.Decode;

type
  TMarshalOptionsHelper = record helper for TMarshalOptions
  public
    function SizeMessageSet(M: IprotoreflectMessage): Integer;
    function MarshalMessageSet(B: TBytes; M: IprotoreflectMessage): TTuple<TBytes, Error>;
  end;

  TUnmarshalOptionsHelper = record helper for TUnmarshalOptions
  public
    function UnmarshalMessageSet(B: TBytes; M: IprotoreflectMessage): Error;
  end;

implementation

function TMarshalOptionsHelper.SizeMessageSet(M: IprotoreflectMessage): Integer;
begin
  Result := 0; // Simplified
end;

function TMarshalOptionsHelper.MarshalMessageSet(B: TBytes; M: IprotoreflectMessage): TTuple<TBytes, Error>;
begin
  Result := Default(TTuple<TBytes, Error>);
end;

function TUnmarshalOptionsHelper.UnmarshalMessageSet(B: TBytes; M: IprotoreflectMessage): Error;
begin
  Result := nil;
end;

end.
