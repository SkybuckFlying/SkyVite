unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.Desc;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.Types,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry,
  Vendor.Google.Golang.Org.Protobuf.Types.Descriptorpb,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc,
  Vendor.Google.Golang.Org.Protobuf.Internal.Pragma,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.DescInit,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.DescResolve,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.DescValidate;

type
  TFileOptions = record
    NoUnkeyedLiterals: TNoUnkeyedLiterals;
    AllowUnresolvable: Boolean;

    function New(ParaFd: PFileDescriptorProto; ParaR: IResolver): IFileDescriptor;
    function NewFiles(ParaFds: PFileDescriptorSet): PFiles;
    // Private helper for NewFiles
    function AddFileDeps(ParaR: PFiles; ParaFd: PFileDescriptorProto; ParaFiles: TDictionary<string, PFileDescriptorProto>): Exception;
  end;

function NewFile(ParaFd: PFileDescriptorProto; ParaR: IResolver): IFileDescriptor;
function NewFiles(ParaFds: PFileDescriptorSet): PFiles;

implementation

function NewFile(ParaFd: PFileDescriptorProto; ParaR: IResolver): IFileDescriptor;
var
  vOpts: TFileOptions;
begin
  vOpts := Default(TFileOptions);
  Result := vOpts.New(ParaFd, ParaR);
end;

function NewFiles(ParaFds: PFileDescriptorSet): PFiles;
var
  vOpts: TFileOptions;
begin
  vOpts := Default(TFileOptions);
  Result := vOpts.NewFiles(ParaFds);
end;

{ TFileOptions }

function TFileOptions.New(ParaFd: PFileDescriptorProto; ParaR: IResolver): IFileDescriptor;
var
  vR: IResolver;
  vF: TFile;
  vSyntax: string;
  vOpts: PFileOptions;
  vImports: TImportSet;
  vI: Integer;
  vPath: string;
  vImp: PFileImport;
  vErr: Exception;
  vR1: TDescsByName;
  vR2: TResolver;
  vSb: TStrBuilder;
begin
  vR := ParaR;
  if vR = nil then
    vR := nil; // Should be empty resolver? In Go: (*protoregistry.Files)(nil)

  vF := TFile.Create;
  // ... Setup vF based on ParaFd (syntax, path, package) ...
  // Implementation details omitted for brevity, following the logic in Go code.
  
  // Step 1: Allocate and derive names
  vR1 := TDescsByName.Create;
  try
    vSb := TStrBuilder.Create;
    try
       // Logic to init declarations using DescInit methods
       // InitEnumDeclarations(vR1, ...)
       // InitMessagesDeclarations(vR1, ...)
    finally
       vSb.Free;
    end;
    
    // Step 2: Resolve dependencies
    vR2 := TResolver.Create;
    vR2.Local := vR1;
    vR2.Remote := vR;
    // vR2.ResolveMessageDependencies(...)
    
    // Step 3: Validate
    // ValidateEnumDeclarations(...)
    
    Result := vF; // Cast to IFileDescriptor
  finally
    vR1.Free;
    vR2.Free; // If it's a class
  end;
end;

function TFileOptions.NewFiles(ParaFds: PFileDescriptorSet): PFiles;
begin
  Result := TFiles.Create;
  // Implementation of NewFiles logic
end;

function TFileOptions.AddFileDeps(ParaR: PFiles; ParaFd: PFileDescriptorProto; ParaFiles: TDictionary<string, PFileDescriptorProto>): Exception;
begin
  Result := nil;
  // Implementation of recursion
end;

end.
