unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Source;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils;

type
  TSourcePath = TArray<Int32>;
  
  TSourcePathHelper = record helper for TSourcePath
    function Equal(ParaOther: TSourcePath): Boolean;
    function ToString: string;
    
    // Gen methods
    function AppendFileDescriptorProto(ParaB: TArray<Byte>): TArray<Byte>;
    function AppendDescriptorProto(ParaB: TArray<Byte>): TArray<Byte>;
    function AppendEnumDescriptorProto(ParaB: TArray<Byte>): TArray<Byte>;
    // ... others
  end;

  TSourceLocation = record
    Path: TSourcePath;
    StartLine, StartColumn: Integer;
    EndLine, EndColumn: Integer;
    LeadingDetachedComments: TArray<string>;
    LeadingComments: string;
    TrailingComments: string;
    Next: Integer;
  end;

  ISourceLocations = interface
    function Len: Integer;
    function Get(ParaIndex: Integer): TSourceLocation;
    function ByPath(ParaPath: TSourcePath): TSourceLocation;
    // function ByDescriptor(ParaDesc: IDescriptor): TSourceLocation;
  end;

implementation

{ TSourcePathHelper }

function TSourcePathHelper.Equal(ParaOther: TSourcePath): Boolean;
var
  vI: Integer;
begin
  if Length(Self) <> Length(ParaOther) then Exit(False);
  for vI := 0 to High(Self) do
    if Self[vI] <> ParaOther[vI] then Exit(False);
  Result := True;
end;

function TSourcePathHelper.ToString: string;
begin
  // Implementation of string formatting
  Result := ''; 
  // ...
end;

function TSourcePathHelper.AppendFileDescriptorProto(ParaB: TArray<Byte>): TArray<Byte>;
begin
  // Implementation from source_gen.go would go here
  Result := ParaB;
end;

function TSourcePathHelper.AppendDescriptorProto(ParaB: TArray<Byte>): TArray<Byte>;
begin
  Result := ParaB;
end;

function TSourcePathHelper.AppendEnumDescriptorProto(ParaB: TArray<Byte>): TArray<Byte>;
begin
  Result := ParaB;
end;

end.
