unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.Types;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  // Resolver is the resolver used by NewFile to resolve dependencies.
  IResolver = interface
    ['{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}'] // Placeholder GUID
    function FindFileByPath(const ParaPath: string): IFileDescriptor;
    function FindDescriptorByName(const ParaFullName: string): IDescriptor;
  end;

  // Shared map types
  TImportSet = TDictionary<string, Boolean>;
  
  // descsByName map used in desc_init.go
  TDescsByName = TDictionary<string, IDescriptor>; 

implementation

end.
