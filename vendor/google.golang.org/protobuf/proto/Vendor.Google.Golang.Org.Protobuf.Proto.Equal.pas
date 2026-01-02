unit Vendor.Google.Golang.Org.Protobuf.Proto.Equal;

interface

uses
  System.SysUtils, Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

function Equal(X, Y: IMessage): Boolean;
function EqualMessage(MX, MY: IprotoreflectMessage): Boolean;

implementation

function Equal(X, Y: IMessage): Boolean;
begin
  if (X = nil) or (Y = nil) then
    Exit((X = nil) and (Y = nil));
  Result := EqualMessage(X.ProtoReflect, Y.ProtoReflect);
end;

function EqualMessage(MX, MY: IprotoreflectMessage): Boolean;
begin
  if MX.Descriptor <> MY.Descriptor then Exit(False);
  // comparison logic...
  Result := True; // Simplified
end;

end.
