unit Vendor.Google.Golang.Org.Protobuf.Proto.Proto;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors, 
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  // Message is the top-level interface that all messages must implement.
  // It provides access to a reflective view of a message.
  IMessage = IProtoMessage;

var
  // Error matches all errors produced by packages in the protobuf module.
  vError: Exception;

// MessageName returns the full name of m.
// If m is nil, it returns an empty string.
function MessageName(ParaM: IMessage): string;

implementation

uses
  System.Classes;

function MessageName(ParaM: IMessage): string;
begin
  if ParaM = nil then
  begin
    Result := '';
    Exit;
  end;
  Result := ParaM.ProtoReflect.Descriptor.FullName;
end;

initialization
  // Error = errors.Error
  vError := Vendor.Google.Golang.Org.Protobuf.Internal.Errors.Error;

end.
