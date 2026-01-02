unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.Proto;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Types.Descriptorpb,
  Vendor.Google.Golang.Org.Protobuf.Proto.Proto;

// ToFileDescriptorProto copies a protoreflect.FileDescriptor into a
// google.protobuf.FileDescriptorProto message.
function ToFileDescriptorProto(ParaFile: IFileDescriptor): PFileDescriptorProto;
function ToDescriptorProto(ParaMessage: IMessageDescriptor): PDescriptorProto;
function ToFieldDescriptorProto(ParaField: IFieldDescriptor): PFieldDescriptorProto;
function ToOneofDescriptorProto(ParaOneof: IOneofDescriptor): POneofDescriptorProto;
function ToEnumDescriptorProto(ParaEnum: IEnumDescriptor): PEnumDescriptorProto;
function ToEnumValueDescriptorProto(ParaValue: IEnumValueDescriptor): PEnumValueDescriptorProto;
function ToServiceDescriptorProto(ParaService: IServiceDescriptor): PServiceDescriptorProto;
function ToMethodDescriptorProto(ParaMethod: IMethodDescriptor): PMethodDescriptorProto;

implementation

function ToFileDescriptorProto(ParaFile: IFileDescriptor): PFileDescriptorProto;
begin
  New(Result);
  // Logic to populate Result
end;

function ToDescriptorProto(ParaMessage: IMessageDescriptor): PDescriptorProto;
begin
  New(Result);
end;

function ToFieldDescriptorProto(ParaField: IFieldDescriptor): PFieldDescriptorProto;
begin
  New(Result);
end;

function ToOneofDescriptorProto(ParaOneof: IOneofDescriptor): POneofDescriptorProto;
begin
  New(Result);
end;

function ToEnumDescriptorProto(ParaEnum: IEnumDescriptor): PEnumDescriptorProto;
begin
  New(Result);
end;

function ToEnumValueDescriptorProto(ParaValue: IEnumValueDescriptor): PEnumValueDescriptorProto;
begin
  New(Result);
end;

function ToServiceDescriptorProto(ParaService: IServiceDescriptor): PServiceDescriptorProto;
begin
  New(Result);
end;

function ToMethodDescriptorProto(ParaMethod: IMethodDescriptor): PMethodDescriptorProto;
begin
  New(Result);
end;

end.
