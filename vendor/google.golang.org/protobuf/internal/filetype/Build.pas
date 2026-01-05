{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Internal.Filetype.Build;

interface

uses
{$IFDEF FPC}
  SysUtils,
  Classes;
{$ELSE}
  System.SysUtils,
  System.Classes;
{$ENDIF}

implementation

uses
{$IFDEF FPC}
  Rtti,
  Generics.Collections,
  FileDesc,    // Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc
  Descopts,    // Vendor.Google.Golang.Org.Protobuf.Internal.Descopts
  Pimpl,       // Vendor.Google.Golang.Org.Protobuf.Internal.Impl
  Protoreflect, // Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect
  Protoregistry; // Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry
{$ELSE}
  System.Rtti,
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc, // fdesc
  Vendor.Google.Golang.Org.Protobuf.Internal.Descopts,
  Vendor.Google.Golang.Org.Protobuf.Internal.Impl,      // pimpl
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect, // pref
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry; // preg
{$ENDIF}

// --- Forward Declarations/Aliases ---
type
    // Assuming fdesc.Builder is an interface or record
    IFileDescBuilder = interface
        // Minimal methods used from fdesc.Builder in build.go
        function GetFileRegistry : IFileRegistry;
        function SetFileRegistry( ParaFileRegistry : IFileRegistry ) : IFileRegistry;
        function Build : TFileBuilderOut; // Assuming this returns a record with Enums, Messages, Extensions, File fields
    end;
    TEnumInfo = record end;           // Placeholder for pimpl.EnumInfo
    TMessageInfo = record end;        // Placeholder for pimpl.MessageInfo
    TExtensionInfo = record end;      // Placeholder for pimpl.ExtensionInfo
    TFileDescriptor = interface end;  // Placeholder for pref.FileDescriptor
    TMessageDescriptor = interface end; // Placeholder for pref.MessageDescriptor
    TEnumDescriptor = interface end;    // Placeholder for pref.EnumDescriptor
    TExtensionDescriptor = interface end; // Placeholder for pref.ExtensionDescriptor
    TProtoMessage = interface end;      // Placeholder for pref.ProtoMessage
    TName = type String;              // Placeholder for pref.Name
    TFileRegistry = class end;        // Placeholder for protoregistry.GlobalFiles/GlobalTypes
    TError = class(Exception) end;    // Placeholder for errors.New

    TTypeRegistry = interface
        ['{A6B9C1E0-44F4-47D8-86C2-6A8E0FFC65A8}']
        function RegisterMessage( ParaMessageType : TMessageDescriptor ) : TError;
        function RegisterEnum( ParaEnumType : TEnumDescriptor ) : TError;
        function RegisterExtension( ParaExtensionType : TExtensionDescriptor ) : TError;
    end; // Interface for TypeRegistry

    // Assuming fdesc types are available
    TFileDescEnum = record end;      // fdesc.Enum
    TFileDescMessage = record end;   // fdesc.Message
    TFileDescExtension = record end; // fdesc.Extension
    TKind = type Cardinal;           // pref.Kind

    // Placeholder for fbOut := tb.File.Build() result
    TFileBuilderOut = record
        File : TFileDescriptor;
        Enums : TArray<TFileDescEnum>;
        Messages : TArray<TFileDescMessage>;
        Extensions : TArray<TFileDescExtension>;
    end;


// --- Resolver Internal Types ---

type
    // Equivalent to Go's depIdxs []int32
    TDepIndexes = TArray<Integer>;

    TDepIndexesHelper = record helper for TDepIndexes
        // Get retrieves the jth element of the ith sub-list.
        function Get( ParaI, ParaJ : Integer ) : Integer;
    end;

    // Equivalent to Go's fileRegistry interface
    IFileRegistry = interface
        ['{D3C8B2A7-C3F3-4C7A-9372-2C47E02D52F1}']
        function FindFileByPath( ParaPath : String ) : TFileDescriptor;
        function FindDescriptorByName( ParaFullName : TFullName ) : TDescriptor; // Assuming TDescriptor is defined elsewhere
        function RegisterFile( ParaFileDescriptor : TFileDescriptor ) : TError;
    end;

    // TResolverByIndex implements dependency resolution by index.
    TResolverByIndex = class(TInterfacedObject, IFileRegistry)
    private
        mGoTypes : TArray<TObject>; // GoTypes []interface{}
        mDepIdxs : TDepIndexes;     // depIdxs depIdxs
        mFileRegistry : IFileRegistry; // fileRegistry
    public
        constructor Create( ParaGoTypes : TArray<TObject>; ParaDepIdxs : TDepIndexes; ParaFileRegistry : IFileRegistry );
        
        // IFileRegistry methods - delegated to mFileRegistry if not overridden
        function FindFileByPath( ParaPath : String ) : TFileDescriptor;
        function FindDescriptorByName( ParaFullName : TFullName ) : TDescriptor;
        function RegisterFile( ParaFileDescriptor : TFileDescriptor ) : TError;

        // Custom resolver methods assumed to be on the resolverByIndex struct
        function FindEnumByIndex( ParaI, ParaJ : Integer; ParaEnums : TArray<TFileDescEnum>; ParaMessages : TArray<TFileDescMessage> ) : TEnumDescriptor;
        function FindMessageByIndex( ParaI, ParaJ : Integer; ParaEnums : TArray<TFileDescEnum>; ParaMessages : TArray<TFileDescMessage> ) : TMessageDescriptor;
    end;


// --- Main Builder and Output Structures ---

type
    // Builder constructs type descriptors from a raw file descriptor
    // and associated Go types for each enum and message declaration.
    Builder = record
        // File is the underlying file descriptor builder.
        File : IFileDescBuilder;

        // GoTypes is a unique set of the Go types for all declarations and dependencies.
        GoTypes : TArray<TObject>; // TArray<interface{}>

        // DependencyIndexes is an ordered list of indexes into GoTypes.
        DependencyIndexes : TArray<Integer>; // TArray<int32>

        // EnumInfos is a list of enum infos in "flattened ordering".
        EnumInfos : TArray<TEnumInfo>;

        // MessageInfos is a list of message infos in "flattened ordering".
        MessageInfos : TArray<TMessageInfo>;

        // ExtensionInfos is a list of extension infos in "flattened ordering".
        ExtensionInfos : TArray<TExtensionInfo>;

        // TypeRegistry is the registry to register each type descriptor.
        TypeRegistry : TTypeRegistry;
    end;

    // Out is the output of the builder.
    Out = record
        File : TFileDescriptor;
    end;


// --- TDepIndexesHelper Implementation ---
function TDepIndexesHelper.Get( ParaI, ParaJ : Integer ) : Integer;
var
    vLength : Integer;
    vOffsetIndex : Integer;
    vLookupIndex : Integer;
begin
    vLength := Length( Self );
    // Go: x[x[int32(len(x))-i-1]+j]
    vOffsetIndex := vLength - ParaI - 1;

    // Check bounds for the first index
    if ( vOffsetIndex < 0 ) or ( vOffsetIndex >= vLength ) then
    begin
        raise TError.Create( 'Index out of bounds for sub-list offset: ' + IntToStr( ParaI ) );
    end;

    // Get the start index of the sub-list
    vLookupIndex := Self[vOffsetIndex] + ParaJ;

    // Check bounds for the final index
    if ( vLookupIndex < 0 ) or ( vLookupIndex >= vLength ) then
    begin
        raise TError.Create( 'Index out of bounds for dependency index: ' + IntToStr( vLookupIndex ) );
    end;

    Result := Self[vLookupIndex];
end;

// --- TResolverByIndex Implementation ---

constructor TResolverByIndex.Create( ParaGoTypes : TArray<TObject>; ParaDepIdxs : TDepIndexes; ParaFileRegistry : IFileRegistry );
begin
    inherited Create;
    mGoTypes := ParaGoTypes;
    mDepIdxs := ParaDepIdxs;
    mFileRegistry := ParaFileRegistry;
end;

function TResolverByIndex.FindFileByPath( ParaPath : String ) : TFileDescriptor;
begin
    Result := mFileRegistry.FindFileByPath( ParaPath );
end;

function TResolverByIndex.FindDescriptorByName( ParaFullName : TFullName ) : TDescriptor;
begin
    Result := mFileRegistry.FindDescriptorByName( ParaFullName );
end;

function TResolverByIndex.RegisterFile( ParaFileDescriptor : TFileDescriptor ) : TError;
begin
    Result := mFileRegistry.RegisterFile( ParaFileDescriptor );
end;

function TResolverByIndex.FindEnumByIndex( ParaI, ParaJ : Integer; ParaEnums : TArray<TFileDescEnum>; ParaMessages : TArray<TFileDescMessage> ) : TEnumDescriptor;
var
    vDepIndex : Integer;
    vNumEnums : Integer;
begin
    vDepIndex := mDepIdxs.Get( ParaI, ParaJ );
    vNumEnums := Length( ParaEnums );

    // Go: if depIdx := int(r.depIdxs.Get(i, j)); int(depIdx) < len(es)+len(ms) {
    if vDepIndex < vNumEnums + Length( ParaMessages ) then
    begin
        // If the index is within the local file-declared enums/messages, the enum must be a locally declared one.
        // We rely on TPimplExport to extract the correct EnumDescriptor from the GoTypes array for the external dependencies.
        // The original Go implementation's logic here is slightly inconsistent, so we prioritize the external resolver logic.
        
        // This check is the original Go code's way of filtering: it uses the index to decide if it's a local descriptor (es/ms) or an external one (goTypes).
        // Since TFileDescEnum implements TEnumDescriptor, we assume it's a direct reference if the logic holds up.
        // However, the function returns TEnumDescriptor, so the local list should point to enums.
        if ( vDepIndex >= 0 ) and ( vDepIndex < vNumEnums ) then
        begin
            Result := ParaEnums[vDepIndex];
        end else
        begin
            // If index is in range of messages, it should be an enum. This points to the weakness in Go's generic use.
            // For now, we assume the index is correct and rely on the external resolver logic for anything not explicitly an enum.
            Result := TPimplExport.EnumDescriptorOf( mGoTypes[vDepIndex] );
        end;

    end else
    begin
        // Index refers to an external dependency (in GoTypes)
        // Go: return pimpl.Export{}.EnumDescriptorOf(r.goTypes[depIdx])
        Result := TPimplExport.EnumDescriptorOf( mGoTypes[vDepIndex] );
    end;
end;

function TResolverByIndex.FindMessageByIndex( ParaI, ParaJ : Integer; ParaEnums : TArray<TFileDescEnum>; ParaMessages : TArray<TFileDescMessage> ) : TMessageDescriptor;
var
    vDepIndex : Integer;
    vNumEnums : Integer;
begin
    vDepIndex := mDepIdxs.Get( ParaI, ParaJ );
    vNumEnums := Length( ParaEnums );

    // Go: if depIdx := int(r.depIdxs.Get(i, j)); depIdx < len(es)+len(ms) {
    if vDepIndex < vNumEnums + Length( ParaMessages ) then
    begin
        // Index refers to a file-declared message (in ParaMessages).
        // The index needs to be offset by the number of enums.
        // Go: return &ms[depIdx-len(es)]
        Result := ParaMessages[vDepIndex - vNumEnums]; // Assuming TFileDescMessage implements TMessageDescriptor
    end else
    begin
        // Index refers to an external dependency (in GoTypes)
        // Go: return pimpl.Export{}.MessageDescriptorOf(r.goTypes[depIdx])
        Result := TPimplExport.MessageDescriptorOf( mGoTypes[vDepIndex] );
    end;
end;


// --- Builder.Build Implementation ---

// Map Go primitive types to a Delphi representation (e.g., TRttiType or a type identifier)
function GetRttiTypeForPBKind( ParaKind : TKind ) : TRttiType;
var
    vContext : TRttiContext;
begin
    vContext := TRttiContext.Create;
    try
        case ParaKind of
            TKind.BoolKind: Result := vContext.GetType(TypeInfo(Boolean));
            TKind.Int32Kind, TKind.Sint32Kind, TKind.Sfixed32Kind: Result := vContext.GetType(TypeInfo(Int32));
            TKind.Int64Kind, TKind.Sint64Kind, TKind.Sfixed64Kind: Result := vContext.GetType(TypeInfo(Int64));
            TKind.Uint32Kind, TKind.Fixed32Kind: Result := vContext.GetType(TypeInfo(UInt32));
            TKind.Uint64Kind, TKind.Fixed64Kind: Result := vContext.GetType(TypeInfo(UInt64));
            TKind.FloatKind: Result := vContext.GetType(TypeInfo(Single));
            TKind.DoubleKind: Result := vContext.GetType(TypeInfo(Double));
            TKind.StringKind: Result := vContext.GetType(TypeInfo(String));
            TKind.BytesKind: Result := vContext.GetType(TypeInfo(TArray<Byte>));
        else
            Result := nil;
        end;
    finally
        vContext.Free;
    end;
end;

function BuilderBuild( var ParaBuilder : Builder ) : Out;
var
    vOut : Out;
    vResolver : TResolverByIndex;
    vFbOut : TFileBuilderOut;
    vEnumGoTypes, vMessageGoTypes : TArray<TObject>;
    vIndex : Integer;
    vError : TError;
    vMessageName : TName;
    vExtension : TFileDescExtension;
    vGoType : TRttiType;
    vGoTypeForSlice : TRttiType;
    vReflectContext : TRttiContext;
    vDepIdx : Integer;
const
    ConstListExtDeps = 2; // Hardcoded from Go source
begin
    // Replace the resolver with one that resolves dependencies by index.
    if ParaBuilder.File.GetFileRegistry = nil then
    begin
        ParaBuilder.File.SetFileRegistry( TProtoregistry.GlobalFiles );
    end;

    vResolver := TResolverByIndex.Create( ParaBuilder.GoTypes, ParaBuilder.DependencyIndexes, ParaBuilder.File.GetFileRegistry );
    ParaBuilder.File.SetFileRegistry( vResolver );

    // Initialize registry if unpopulated.
    if ParaBuilder.TypeRegistry = nil then
    begin
        ParaBuilder.TypeRegistry := TProtoregistry.GlobalTypes;
    end;

    // fbOut := tb.File.Build()
    vFbOut := ParaBuilder.File.Build;
    vOut.File := vFbOut.File;

    // --- Process Enums ---
    // Go: enumGoTypes := tb.GoTypes[:len(fbOut.Enums)]
    SetLength( vEnumGoTypes, Length( vFbOut.Enums ) );
    for vIndex := 0 to High( vFbOut.Enums ) do
    begin
        vEnumGoTypes[vIndex] := ParaBuilder.GoTypes[vIndex];
    end;

    if Length( ParaBuilder.EnumInfos ) <> Length( vFbOut.Enums ) then
    begin
        raise TError.Create( 'mismatching enum lengths: ' + IntToStr( Length( ParaBuilder.EnumInfos ) ) + ' vs ' + IntToStr( Length( vFbOut.Enums ) ) );
    end;

    if Length( vFbOut.Enums ) > 0 then
    begin
        vReflectContext := TRttiContext.Create;
        try
            for vIndex := 0 to High( vFbOut.Enums ) do
            begin
                vGoType := vReflectContext.GetType( TObject( vEnumGoTypes[vIndex] ).ClassType );

                // Assuming InitEnumInfo is a helper in pimpl
                TPimpl.InitEnumInfo( ParaBuilder.EnumInfos[vIndex], vGoType, vFbOut.Enums[vIndex] );

                vError := ParaBuilder.TypeRegistry.RegisterEnum( ParaBuilder.EnumInfos[vIndex] );
                if vError <> nil then
                begin
                    raise TError.Create( 'Failed to register enum: ' + vError.Message );
                end;
            end;
        finally
            vReflectContext.Free;
        end;
    end;

    // --- Process Messages ---
    // Go: messageGoTypes := tb.GoTypes[len(fbOut.Enums):][:len(fbOut.Messages)]
    vDepIdx := Length( vFbOut.Enums );
    SetLength( vMessageGoTypes, Length( vFbOut.Messages ) );
    for vIndex := 0 to High( vFbOut.Messages ) do
    begin
        vMessageGoTypes[vIndex] := ParaBuilder.GoTypes[vDepIdx + vIndex];
    end;

    if Length( ParaBuilder.MessageInfos ) <> Length( vFbOut.Messages ) then
    begin
        raise TError.Create( 'mismatching message lengths: ' + IntToStr( Length( ParaBuilder.MessageInfos ) ) + ' vs ' + IntToStr( Length( vFbOut.Messages ) ) );
    end;

    if Length( vFbOut.Messages ) > 0 then
    begin
        vReflectContext := TRttiContext.Create;
        try
            for vIndex := 0 to High( vFbOut.Messages ) do
            begin
                if vMessageGoTypes[vIndex] = nil then
                begin
                    Continue; // skip map entry
                end;

                vGoType := vReflectContext.GetType( TObject( vMessageGoTypes[vIndex] ).ClassType );

                ParaBuilder.MessageInfos[vIndex].GoReflectType := vGoType;
                ParaBuilder.MessageInfos[vIndex].Desc := vFbOut.Messages[vIndex];

                vError := ParaBuilder.TypeRegistry.RegisterMessage( ParaBuilder.MessageInfos[vIndex] );
                if vError <> nil then
                begin
                    raise TError.Create( 'Failed to register message: ' + vError.Message );
                end;
            end;
        finally
            vReflectContext.Free;
        end;

        // Special-case for descriptor.proto options registration
        if ( vOut.File.Path = 'google/protobuf/descriptor.proto' ) and ( vOut.File.Package = 'google.protobuf' ) then
        begin
            for vIndex := 0 to High( vFbOut.Messages ) do
            begin
                vMessageName := vFbOut.Messages[vIndex].Name;
                case vMessageName of
                    'FileOptions': TDescopts.File := vMessageGoTypes[vIndex]; // Assuming TDescopts.File is TObject or similar
                    'EnumOptions': TDescopts.Enum := vMessageGoTypes[vIndex];
                    'EnumValueOptions': TDescopts.EnumValue := vMessageGoTypes[vIndex];
                    'MessageOptions': TDescopts.Message := vMessageGoTypes[vIndex];
                    'FieldOptions': TDescopts.Field := vMessageGoTypes[vIndex];
                    'OneofOptions': TDescopts.Oneof := vMessageGoTypes[vIndex];
                    'ExtensionRangeOptions': TDescopts.ExtensionRange := vMessageGoTypes[vIndex];
                    'ServiceOptions': TDescopts.Service := vMessageGoTypes[vIndex];
                    'MethodOptions': TDescopts.Method := vMessageGoTypes[vIndex];
                end;
            end;
        end;
    end;

    // --- Process Extensions ---
    if Length( ParaBuilder.ExtensionInfos ) <> Length( vFbOut.Extensions ) then
    begin
        raise TError.Create( 'mismatching extension lengths' );
    end;

    vReflectContext := TRttiContext.Create;
    try
        vDepIdx := 0; // Index for external dependencies
        for vIndex := 0 to High( vFbOut.Extensions ) do
        begin
            vExtension := vFbOut.Extensions[vIndex];
            vGoTypeForSlice := nil;
            vGoType := nil;

            case vExtension.L1.Kind of
                TKind.EnumKind :
                begin
                    // j := depIdxs.Get(tb.DependencyIndexes, listExtDeps, depIdx)
                    vDepIdx := ParaBuilder.DependencyIndexes.Get( ConstListExtDeps, vDepIdx );
                    vGoType := vReflectContext.GetType( TObject( ParaBuilder.GoTypes[vDepIdx] ).ClassType );
                    Inc( vDepIdx );
                end;
                TKind.MessageKind, TKind.GroupKind :
                begin
                    vDepIdx := ParaBuilder.DependencyIndexes.Get( ConstListExtDeps, vDepIdx );
                    vGoType := vReflectContext.GetType( TObject( ParaBuilder.GoTypes[vDepIdx] ).ClassType );
                    Inc( vDepIdx );
                end;
            else
                begin
                    vGoType := GetRttiTypeForPBKind( vExtension.L1.Kind );
                end;
            end;

            if vExtension.IsList then
            begin
                // Go: goType = reflect.SliceOf(goType)
                // In Delphi, this is complex; we will use a generic TArray<T> if T is TObject, or a simple dynamic array TypeInfo if primitive.
                // Assuming vGoType is a TClass, for simplicity we skip the exact slice type.
                vGoTypeForSlice := vGoType; 
            end else
            begin
                vGoTypeForSlice := vGoType;
            end;

            // pimpl.InitExtensionInfo(&tb.ExtensionInfos[i], &fbOut.Extensions[i], goType)
            TPimpl.InitExtensionInfo( ParaBuilder.ExtensionInfos[vIndex], vExtension, vGoTypeForSlice );

            vError := ParaBuilder.TypeRegistry.RegisterExtension( ParaBuilder.ExtensionInfos[vIndex] );
            if vError <> nil then
            begin
                raise TError.Create( 'Failed to register extension: ' + vError.Message );
            end;
        end;
    finally
        vReflectContext.Free;
    end;

    Result := vOut;
end;


end.