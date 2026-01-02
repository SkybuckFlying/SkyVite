unit Vendor.Google.Golang.Org.Protobuf.Proto.Reset;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  Vendor.Google.Golang.Org.Protobuf.Proto.Proto,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Proto.ProtoMethods;

// Reset clears every field in the message.
procedure Reset(ParaM: IMessage);

implementation

procedure ResetMessage(ParaM: IProtoMessage); forward;

procedure Reset(ParaM: IMessage);
var
  vReseter: IInterface; // Placeholder for interface check
begin
  // Go logic:
  // if mr, ok := m.(interface{ Reset() }); ok && hasProtoMethods { mr.Reset(); return }
  
  // In Delphi, checking for implicit interface implementation is not standard.
  // We proceed to the generic implementation.
  if ParaM <> nil then
    ResetMessage(ParaM.ProtoReflect);
end;

procedure ResetMessage(ParaM: IProtoMessage);
var
  vFds: IFieldDescriptors;
  vI: Integer;
begin
  if not ParaM.IsValid then
    raise Exception.CreateFmt('cannot reset invalid %s message', [ParaM.Descriptor.FullName]);

  // Clear all known fields.
  vFds := ParaM.Descriptor.Fields;
  for vI := 0 to vFds.Len - 1 do
  begin
    ParaM.Clear(vFds.Get(vI));
  end;

  // Clear extension fields.
  ParaM.Range(
    function(ParaFd: IFieldDescriptor; ParaV: TValue): Boolean
    begin
      ParaM.Clear(ParaFd);
      Result := True;
    end
  );

  // Clear unknown fields.
  ParaM.SetUnknown(nil);
end;

end.
