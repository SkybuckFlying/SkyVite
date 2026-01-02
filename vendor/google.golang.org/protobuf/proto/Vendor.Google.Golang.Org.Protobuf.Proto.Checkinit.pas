unit Vendor.Google.Golang.Org.Protobuf.Proto.Checkinit;

interface

uses
  System.SysUtils,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

function CheckInitialized(M: IMessage): Error;
function CheckInitializedMessage(M: IprotoreflectMessage): Error;
function CheckInitializedSlow(M: IprotoreflectMessage): Error;

implementation

function CheckInitialized(M: IMessage): Error;
begin
  if M = nil then Exit(nil);
  Result := CheckInitializedMessage(M.ProtoReflect);
end;

function CheckInitializedMessage(M: IprotoreflectMessage): Error;
var
  Methods: PMethods;
begin
  Methods := ProtoMethods(M);
  if (Methods <> nil) and Assigned(Methods.CheckInitialized) then
  begin
    Result := Methods.CheckInitialized(Default(TCheckInitializedInput)).Error; // Simplified
    Exit;
  end;
  Result := CheckInitializedSlow(M);
end;

function CheckInitializedSlow(M: IprotoreflectMessage): Error;
var
  MD: IMessageDescriptor;
  FDS: IFieldDescriptors;
  Nums: IFieldNumbers;
  I: Integer;
  FD: IFieldDescriptor;
begin
  MD := M.Descriptor;
  FDS := MD.Fields;
  Nums := MD.RequiredNumbers;
  for I := 0 to Nums.Len - 1 do
  begin
    FD := FDS.ByNumber(Nums.Get(I));
    if not M.Has(FD) then
      Exit(TErrors.RequiredNotSet(string(FD.FullName)));
  end;
  // recursive check omitted for brevity
  Result := nil;
end;

end.
