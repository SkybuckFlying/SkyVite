{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc.DescLazy;

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
  SyncObjs,
  Generics.Collections,
  Protowire,
  Descopts,
  Genid,
  Strs,
  Proto,
  Protoreflect,
  Core, // Assumed unit for TFile, TMessage, TField, etc.
  DescInit; // For GetBuilder and PutBuilder
{$ELSE}
  System.Rtti,
  System.SyncObjs,
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Descopts,
  Vendor.Google.Golang.Org.Protobuf.Internal.Genid,
  Vendor.Google.Golang.Org.Protobuf.Internal.Strs,
  Vendor.Google.Golang.Org.Protobuf.Proto,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc.Core,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc.DescInit; // For GetBuilder/PutBuilder
{$ENDIF}

// --- Forward Declarations/Assumptions for Types ---

type
    // Assuming these are all records defined in Core.pas, but used locally
    TFile = record end;
    TMessage = record end;
    TField = record end;
    TExtension = record end;
    TService = record end;
    TMethod = record end;
    TOneof = record end;
    TFileL2 = record end;
    TMessageL2 = record end;
    TExtensionL2 = record end;
    TEnumL2 = record end;
    TEnumValue = record end;
    TFileImport = record end; // pref.FileImport
    TProtoMessage = interface end; // pref.ProtoMessage
    TTypeResolver = interface end; // db.TypeResolver
    TFullName = type String; // pref.FullName
    TFieldNumber = type Integer; // pref.FieldNumber
    TEnumNumber = type Integer; // pref.EnumNumber
    TKind = type Cardinal; // pref.Kind
    TCardinality = type Cardinal; // pref.Cardinality
    TWireType = type Cardinal; // protowire.Type
    TResolverByIndex = interface end; // resolverByIndex (assuming an interface)
    IFileDescriptor = interface end; // placeholder for resolved file descriptor
    TPlaceholderFile = class(TInterfacedObject) end; // placeholder for PlaceholderFile
    TDescOpts = class end; // placeholder for descopts
    
    // TGoOnce implementation (equivalent to Go's sync.Once)
    TGoOnce = class
    private
        mCriticalSection : TCriticalSection;
        mDone : Boolean;
    public
        constructor Create;
        destructor Destroy; override;
        procedure DoOnce( ParaProc : TProc );
    end;

// --- TGoOnce Implementation ---

constructor TGoOnce.Create;
begin
    inherited Create;
    mCriticalSection := nil;
    try
        mCriticalSection := TCriticalSection.Create;
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Failed to create TCriticalSection in TGoOnce: ' + E.Message );
        end;
    end;
    mDone := False;
end;

destructor TGoOnce.Destroy;
begin
    mCriticalSection.Free;
    inherited Destroy;
end;

procedure TGoOnce.DoOnce( ParaProc : TProc );
begin
    if not mDone then
    begin
        mCriticalSection.Acquire;
        try
            if not mDone then
            begin
                ParaProc;
                mDone := True;
            end;
        finally
            mCriticalSection.Release;
        end;
    end;
end;

// --- Utility Functions ---

// appendOptions appends src to dst, where the returned slice is never nil.
// This is necessary to distinguish between empty and unpopulated options.
function AppendOptions( ParaDst : TArray<Byte>; ParaSrc : TArray<Byte> ) : TArray<Byte>;
var
    vDst : TArray<Byte>;
begin
    // Check if ParaDst is nil (Go's nil slice) and initialize to an empty, non-nil slice.
    if ParaDst = nil then
    begin
        SetLength( vDst, 0 );
    end else
    begin
        vDst := ParaDst;
    end;

    // Append src to vDst
    Result := vDst + ParaSrc;
end;

// optionsUnmarshaler constructs a lazy unmarshal function for an options message.
// The complexity of Go's reflection is simplified by assuming RTTI is set up 
// for the necessary types.
function OptionsUnmarshaler( ParaBuilder : IBuilder; ParaProtoMessagePtr : PProtoMessage; ParaBytes : TArray<Byte> ) : TFunc<TProtoMessage>;
var
    vBytes : TArray<Byte>;
    vOpts : TProtoMessage;
    vOnce : TGoOnce;
    vDoFunc : TProc;
begin
    if ParaBytes = nil then
    begin
        Result := nil;
        Exit;
    end;

    // Local state capture
    vBytes := ParaBytes;
    vOnce := nil;
    try
        vOnce := TGoOnce.Create;
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Failed to create TGoOnce instance for OptionsUnmarshaler: ' + E.Message );
        end;
    end;

    // Define the closure (anonymous method) for DoOnce
    vDoFunc := procedure
    var
        vRttiContext : TRttiContext;
        vRttiType : TRttiType;
    begin
        if ParaProtoMessagePtr^ = nil then
        begin
            raise Exception.Create( 'Descriptor.Options called without importing the descriptor package' );
        end;

        // Implementation of: opts = reflect.New(reflect.TypeOf(*p).Elem()).Interface().(pref.ProtoMessage)
        vRttiContext := TRttiContext.Create;
        try
            // Get RTTI for the class that implements the interface ParaProtoMessagePtr^
            vRttiType := vRttiContext.GetType( TObject( ParaProtoMessagePtr^ ).ClassType );
            
            if vRttiType = nil then
            begin
                raise Exception.Create( 'RTTI failed to find type for ProtoMessage interface.' );
            end;
            
            vOpts := vRttiType.AsInstance.GetInterface( TProtoMessage ) as TProtoMessage;
            
            if vOpts = nil then
            begin
                raise Exception.Create( 'Failed to instantiate ProtoMessage type via RTTI.' );
            end;
        finally
            vRttiContext.Free;
        end;

        // Implementation of: if err := (proto.UnmarshalOptions{...}).Unmarshal(b, opts); err != nil { panic(err) }
        TProto.Unmarshal
        (
            TProto.TUnmarshalOptions.Create // Assuming TUnmarshalOptions is a record/class with fields
            (
                True, // AllowPartial
                ParaBuilder.TypeResolver
            )
            ,
            vBytes,
            vOpts
        );

    end;

    // The returned anonymous method implements the lazy unmarshaling logic
    Result := function : TProtoMessage
    begin
        vOnce.DoOnce( vDoFunc );
        Result := vOpts;
    end;
end;

// --- Core Initialization Functions (Unexported) ---

// lazyRawInit is the Delphi equivalent of func (fd *File) lazyRawInit()
// It performs full unmarshalling and dependency resolution.
procedure LazyRawInit( var ParaFile : TFile );
begin
    UnmarshalFull( ParaFile, ParaFile.mBuilder.mRawDescriptor );
    ResolveMessages( ParaFile );
    ResolveExtensions( ParaFile );
    ResolveServices( ParaFile );
end;

// resolveMessages is the Delphi equivalent of func (file *File) resolveMessages()
procedure ResolveMessages( var ParaFile : TFile );
var
    vDepIndex : Integer; // int32
    vIndex, vJIndex : Integer;
    vMessageDescriptor : TMessage;
    vFieldDescriptor : TField;
begin
    vDepIndex := 0;
    for vIndex := Low( ParaFile.mAllMessages ) to High( ParaFile.mAllMessages ) do
    begin
        vMessageDescriptor := ParaFile.mAllMessages[vIndex];

        // Resolve message field dependencies.
        for vJIndex := Low( vMessageDescriptor.L2.mFields.mList ) to High( vMessageDescriptor.L2.mFields.mList ) do
        begin
            vFieldDescriptor := vMessageDescriptor.L2.mFields.mList[vJIndex];

            // Weak fields are resolved upon actual use.
            if vFieldDescriptor.L1.mIsWeak then
            begin
                Continue;
            end;

            // Resolve message field dependency.
            case vFieldDescriptor.L1.mKind of
                TKind.EnumKind :
                begin
                    vFieldDescriptor.L1.mEnum := ParaFile.ResolveEnumDependency
                    (
                        vFieldDescriptor.L1.mEnum,
                        ConstListFieldDeps, // Assuming ConstListFieldDeps constant is available
                        vDepIndex
                    );
                    Inc( vDepIndex );
                end;

                TKind.MessageKind, TKind.GroupKind :
                begin
                    vFieldDescriptor.L1.mMessage := ParaFile.ResolveMessageDependency
                    (
                        vFieldDescriptor.L1.mMessage,
                        ConstListFieldDeps,
                        vDepIndex
                    );
                    Inc( vDepIndex );
                end;
            end;

            // Default is resolved here since it depends on Enum being resolved.
            if vFieldDescriptor.L1.mDefault.mVal.IsValid then
            begin
                vFieldDescriptor.L1.mDefault := UnmarshalDefault
                (
                    vFieldDescriptor.L1.mDefault.mVal.GetByteSlice, // Assuming GetByteSlice retrieves the []byte
                    vFieldDescriptor.L1.mKind,
                    ParaFile,
                    vFieldDescriptor.L1.mEnum
                );
            end;

            // Assign back if TField is a record
            vMessageDescriptor.L2.mFields.mList[vJIndex] := vFieldDescriptor;
        end;

        // Assign back if TMessage is a record
        ParaFile.mAllMessages[vIndex] := vMessageDescriptor;
    end;
end;

// resolveExtensions is the Delphi equivalent of func (file *File) resolveExtensions()
procedure ResolveExtensions( var ParaFile : TFile );
var
    vDepIndex : Integer; // int32
    vIndex : Integer;
    vExtensionDescriptor : TExtension;
begin
    vDepIndex := 0;
    for vIndex := Low( ParaFile.mAllExtensions ) to High( ParaFile.mAllExtensions ) do
    begin
        vExtensionDescriptor := ParaFile.mAllExtensions[vIndex];

        // Resolve extension field dependency.
        case vExtensionDescriptor.L1.mKind of
            TKind.EnumKind :
            begin
                vExtensionDescriptor.L2.mEnum := ParaFile.ResolveEnumDependency
                (
                    vExtensionDescriptor.L2.mEnum,
                    ConstListExtDeps,
                    vDepIndex
                );
                Inc( vDepIndex );
            end;

            TKind.MessageKind, TKind.GroupKind :
            begin
                vExtensionDescriptor.L2.mMessage := ParaFile.ResolveMessageDependency
                (
                    vExtensionDescriptor.L2.mMessage,
                    ConstListExtDeps,
                    vDepIndex
                );
                Inc( vDepIndex );
            end;
        end;

        // Default is resolved here since it depends on Enum being resolved.
        if vExtensionDescriptor.L2.mDefault.mVal.IsValid then
        begin
            vExtensionDescriptor.L2.mDefault := UnmarshalDefault
            (
                vExtensionDescriptor.L2.mDefault.mVal.GetByteSlice,
                vExtensionDescriptor.L1.mKind,
                ParaFile,
                vExtensionDescriptor.L2.mEnum
            );
        end;

        // Assign back if TExtension is a record
        ParaFile.mAllExtensions[vIndex] := vExtensionDescriptor;
    end;
end;

// resolveServices is the Delphi equivalent of func (file *File) resolveServices()
procedure ResolveServices( var ParaFile : TFile );
var
    vDepIndex : Integer; // int32
    vIndex, vJIndex : Integer;
    vServiceDescriptor : TService;
    vMethodDescriptor : TMethod;
begin
    vDepIndex := 0;
    for vIndex := Low( ParaFile.mAllServices ) to High( ParaFile.mAllServices ) do
    begin
        vServiceDescriptor := ParaFile.mAllServices[vIndex];

        // Resolve method dependencies.
        for vJIndex := Low( vServiceDescriptor.L2.mMethods.mList ) to High( vServiceDescriptor.L2.mMethods.mList ) do
        begin
            vMethodDescriptor := vServiceDescriptor.L2.mMethods.mList[vJIndex];

            vMethodDescriptor.L1.mInput := ParaFile.ResolveMessageDependency
            (
                vMethodDescriptor.L1.mInput,
                ConstListMethInDeps,
                vDepIndex
            );

            vMethodDescriptor.L1.mOutput := ParaFile.ResolveMessageDependency
            (
                vMethodDescriptor.L1.mOutput,
                ConstListMethOutDeps,
                vDepIndex
            );
            Inc( vDepIndex );

            // Assign back if TMethod is a record
            vServiceDescriptor.L2.mMethods.mList[vJIndex] := vMethodDescriptor;
        end;

        // Assign back if TService is a record
        ParaFile.mAllServices[vIndex] := vServiceDescriptor;
    end;
end;

// unmarshalFull is the Delphi equivalent of func (fd *File) unmarshalFull(...)
procedure UnmarshalFull( var ParaFile : TFile; ParaBytes : TArray<Byte> );
var
    vStringBuilder : TStrBuilder;
    vEnumIndex, vMessageIndex, vExtensionIndex, vServiceIndex : Integer;
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vPath : TFullName;
    vImport : IFileDescriptor; // Assuming IFileDescriptor is the interface for file descriptor
begin
    vStringBuilder := GetBuilder;
    try
        vEnumIndex := 0;
        vMessageIndex := 0;
        vExtensionIndex := 0;
        vServiceIndex := 0;
        vRawOptions := nil; // nil to start, handled by AppendOptions

        // Allocate L2 struct
        ParaFile.L2 := TFileL2.Create; // Assuming TFileL2 is a class
        try
            ParaFile.L2.mImports := TArray<TFileImport>.Create;
        except
            on E: EOutOfMemory do
            begin
                ParaFile.L2.Free;
                raise Exception.Create( 'Failed to initialize imports array: ' + E.Message );
            end;
        end;

        vBytes := ParaBytes;
        while Length( vBytes ) > 0 do
        begin
            vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
            vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

            case vWireType of
                TWireType.VarintType :
                begin
                    vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                    vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                    case vTagNumber of
                        ConstFileDescriptorProto_PublicDependency_field_number :
                        begin
                            // fd.L2.Imports[v].IsPublic = true
                            ParaFile.L2.mImports[vVarint].mIsPublic := True;
                        end;

                        ConstFileDescriptorProto_WeakDependency_field_number :
                        begin
                            // fd.L2.Imports[v].IsWeak = true
                            ParaFile.L2.mImports[vVarint].mIsWeak := True;
                        end;
                    end;
                end;

                TWireType.BytesType :
                begin
                    vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                    vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                    case vTagNumber of
                        ConstFileDescriptorProto_Dependency_field_number :
                        begin
                            vPath := vStringBuilder.MakeString( vConsumeValue );

                            // imp, _ := fd.builder.FileRegistry.FindFileByPath(path)
                            vImport := ParaFile.mBuilder.mFileRegistry.FindFileByPath( vPath );

                            if vImport = nil then
                            begin
                                vImport := TPlaceholderFile.Create( vPath ); // Assuming TPlaceholderFile type
                            end;

                            // fd.L2.Imports = append(fd.L2.Imports, pref.FileImport{FileDescriptor: imp})
                            // Assuming TFileImport is a record containing IFileDescriptor
                            ParaFile.L2.mImports := ParaFile.L2.mImports + [ TFileImport.Create( vImport ) ];
                        end;

                        ConstFileDescriptorProto_EnumType_field_number :
                        begin
                            // fd.L1.Enums.List[enumIdx].unmarshalFull(v, sb)
                            // Assuming UnmarshalEnumFull is a standalone procedure
                            UnmarshalEnumFull( ParaFile.L1.mEnums.mList[vEnumIndex], vConsumeValue, vStringBuilder );
                            Inc( vEnumIndex );
                        end;

                        ConstFileDescriptorProto_MessageType_field_number :
                        begin
                            UnmarshalMessageFull( ParaFile.L1.mMessages.mList[vMessageIndex], vConsumeValue, vStringBuilder );
                            Inc( vMessageIndex );
                        end;

                        ConstFileDescriptorProto_Extension_field_number :
                        begin
                            UnmarshalExtensionFull( ParaFile.L1.mExtensions.mList[vExtensionIndex], vConsumeValue, vStringBuilder );
                            Inc( vExtensionIndex );
                        end;

                        ConstFileDescriptorProto_Service_field_number :
                        begin
                            UnmarshalServiceFull( ParaFile.L1.mServices.mList[vServiceIndex], vConsumeValue, vStringBuilder );
                            Inc( vServiceIndex );
                        end;

                        ConstFileDescriptorProto_Options_field_number :
                        begin
                            vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                        end;
                    end;
                end;
            else
                begin
                    vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                    vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
                end;
            end;
        end;

        // fd.L2.Options = fd.builder.optionsUnmarshaler(&descopts.File, rawOptions)
        ParaFile.L2.mOptions := OptionsUnmarshaler( ParaFile.mBuilder, @TDescOpts.File, vRawOptions ); // Assuming TDescOpts.File is available
    finally
        PutBuilder( vStringBuilder );
    end;
end;

// unmarshalEnumReservedRange is the Delphi equivalent of func unmarshalEnumReservedRange(...)
function UnmarshalEnumReservedRange( ParaBytes : TArray<Byte> ) : TArray<TEnumNumber>;
var
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
begin
    SetLength( Result, 2 ); // [2]pref.EnumNumber

    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstEnumDescriptorProto_EnumReservedRange_Start_field_number :
                    begin
                        Result[0] := TEnumNumber( vVarint );
                    end;

                    ConstEnumDescriptorProto_EnumReservedRange_End_field_number :
                    begin
                        Result[1] := TEnumNumber( vVarint );
                    end;
                end;
            end;
        else
            begin
                vVarintM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
            end;
        end;
    end;
end;

// unmarshalFull is the Delphi equivalent of func (ed *Enum) unmarshalFull(...)
procedure UnmarshalEnumFull( var ParaEnum : TEnum; ParaBytes : TArray<Byte>; ParaStringBuilder : TStrBuilder );
var
    vRawValues : TArray<TArray<Byte>>;
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vIndex : Integer;
begin
    vRawValues := TArray<TArray<Byte>>.Create;
    vRawOptions := nil;

    if not ParaEnum.L1.mEagerValues then
    begin
        // Allocate L2 struct if not done in unmarshalSeed
        ParaEnum.L2 := TEnumL2.Create;
    end;

    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstEnumDescriptorProto_Value_field_number :
                    begin
                        vRawValues := vRawValues + [ vConsumeValue ];
                    end;

                    ConstEnumDescriptorProto_ReservedName_field_number :
                    begin
                        ParaEnum.L2.mReservedNames.mList := ParaEnum.L2.mReservedNames.mList +
                            [ TName( ParaStringBuilder.MakeString( vConsumeValue ) ) ];
                    end;

                    ConstEnumDescriptorProto_ReservedRange_field_number :
                    begin
                        ParaEnum.L2.mReservedRanges.mList := ParaEnum.L2.mReservedRanges.mList +
                            [ UnmarshalEnumReservedRange( vConsumeValue ) ];
                    end;

                    ConstEnumDescriptorProto_Options_field_number :
                    begin
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
            end;
        end;
    end;

    if not ParaEnum.L1.mEagerValues and ( Length( vRawValues ) > 0 ) then
    begin
        // Allocate and unmarshal EnumValues
        SetLength( ParaEnum.L2.mValues.mList, Length( vRawValues ) );
        for vIndex := 0 to High( vRawValues ) do
        begin
            // unmarshalFull(b, sb, ed.L0.ParentFile, ed, i)
            UnmarshalEnumValueFull( ParaEnum.L2.mValues.mList[vIndex], vRawValues[vIndex], ParaStringBuilder, ParaEnum.L0.mParentFile, ParaEnum, vIndex );
        end;
    end;

    // ed.L2.Options = ed.L0.ParentFile.builder.optionsUnmarshaler(&descopts.Enum, rawOptions)
    ParaEnum.L2.mOptions := OptionsUnmarshaler( ParaEnum.L0.mParentFile.mBuilder, @TDescOpts.Enum, vRawOptions );
end;

// unmarshalFull is the Delphi equivalent of func (vd *EnumValue) unmarshalFull(...)
procedure UnmarshalEnumValueFull
(
    var ParaEnumValue : TEnumValue;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
var
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
begin
    ParaEnumValue.L0.mParentFile := ParaFile;
    ParaEnumValue.L0.mParent := ParaParentDescriptor;
    ParaEnumValue.L0.mIndex := ParaIndex;

    vRawOptions := nil;
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstEnumValueDescriptorProto_Number_field_number :
                    begin
                        ParaEnumValue.L1.mNumber := TEnumNumber( vVarint );
                    end;
                end;
            end;

            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstEnumValueDescriptorProto_Name_field_number :
                    begin
                        // NOTE: Enum values are in the same scope as the enum parent.
                        ParaEnumValue.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.Parent.FullName, // Parent().FullName()
                            vConsumeValue
                        );
                    end;

                    ConstEnumValueDescriptorProto_Options_field_number :
                    begin
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
            end;
        end;
    end;

    // vd.L1.Options = pf.builder.optionsUnmarshaler(&descopts.EnumValue, rawOptions)
    ParaEnumValue.L1.mOptions := OptionsUnmarshaler( ParaFile.mBuilder, @TDescOpts.EnumValue, vRawOptions );
end;

// unmarshalFull is the Delphi equivalent of func (md *Message) unmarshalFull(...)
procedure UnmarshalMessageFull( var ParaMessage : TMessage; ParaBytes : TArray<Byte>; ParaStringBuilder : TStrBuilder );
var
    vRawFields, vRawOneofs : TArray<TArray<Byte>>;
    vEnumIndex, vMessageIndex, vExtensionIndex : Integer;
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vExtensionRange : TArray<TFieldNumber>;
    vExtensionRangeOptions : TFunc<TProtoMessage>;
    vIndex : Integer;
    vFieldDescriptor : TField;
begin
    vRawFields := TArray<TArray<Byte>>.Create;
    vRawOneofs := TArray<TArray<Byte>>.Create;
    vEnumIndex := 0;
    vMessageIndex := 0;
    vExtensionIndex := 0;
    vRawOptions := nil;

    ParaMessage.L2 := TMessageL2.Create;
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstDescriptorProto_Field_field_number :
                    begin
                        vRawFields := vRawFields + [ vConsumeValue ];
                    end;

                    ConstDescriptorProto_OneofDecl_field_number :
                    begin
                        vRawOneofs := vRawOneofs + [ vConsumeValue ];
                    end;

                    ConstDescriptorProto_ReservedName_field_number :
                    begin
                        ParaMessage.L2.mReservedNames.mList := ParaMessage.L2.mReservedNames.mList +
                            [ TName( ParaStringBuilder.MakeString( vConsumeValue ) ) ];
                    end;

                    ConstDescriptorProto_ReservedRange_field_number :
                    begin
                        ParaMessage.L2.mReservedRanges.mList := ParaMessage.L2.mReservedRanges.mList +
                            [ UnmarshalMessageReservedRange( vConsumeValue ) ];
                    end;

                    ConstDescriptorProto_ExtensionRange_field_number :
                    begin
                        UnmarshalMessageExtensionRange( vConsumeValue, vExtensionRange, vRawOptions );
                        vExtensionRangeOptions := OptionsUnmarshaler( ParaMessage.L0.mParentFile.mBuilder, @TDescOpts.ExtensionRange, vRawOptions );
                        ParaMessage.L2.mExtensionRanges.mList := ParaMessage.L2.mExtensionRanges.mList + [ vExtensionRange ];
                        ParaMessage.L2.mExtensionRangeOptions := ParaMessage.L2.mExtensionRangeOptions + [ vExtensionRangeOptions ];
                    end;

                    ConstDescriptorProto_EnumType_field_number :
                    begin
                        UnmarshalEnumFull( ParaMessage.L1.mEnums.mList[vEnumIndex], vConsumeValue, vStringBuilder );
                        Inc( vEnumIndex );
                    end;

                    ConstDescriptorProto_NestedType_field_number :
                    begin
                        UnmarshalMessageFull( ParaMessage.L1.mMessages.mList[vMessageIndex], vConsumeValue, vStringBuilder );
                        Inc( vMessageIndex );
                    end;

                    ConstDescriptorProto_Extension_field_number :
                    begin
                        UnmarshalExtensionFull( ParaMessage.L1.mExtensions.mList[vExtensionIndex], vConsumeValue, vStringBuilder );
                        Inc( vExtensionIndex );
                    end;

                    ConstDescriptorProto_Options_field_number :
                    begin
                        UnmarshalMessageOptions( ParaMessage, vConsumeValue );
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            else
                begin
                    vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                    vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
                end;
            end;
        end;

    if ( Length( vRawFields ) > 0 ) or ( Length( vRawOneofs ) > 0 ) then
    begin
        // Allocate space for Fields and Oneofs lists
        SetLength( ParaMessage.L2.mFields.mList, Length( vRawFields ) );
        SetLength( ParaMessage.L2.mOneofs.mList, Length( vRawOneofs ) );

        for vIndex := 0 to High( vRawFields ) do
        begin
            vFieldDescriptor := ParaMessage.L2.mFields.mList[vIndex];
            UnmarshalFieldFull( vFieldDescriptor, vRawFields[vIndex], vStringBuilder, ParaMessage.L0.mParentFile, ParaMessage, vIndex );

            if vFieldDescriptor.L1.mCardinality = TCardinality.Required then
            begin
                ParaMessage.L2.mRequiredNumbers.mList := ParaMessage.L2.mRequiredNumbers.mList + [ vFieldDescriptor.L1.mNumber ];
            end;
            ParaMessage.L2.mFields.mList[vIndex] := vFieldDescriptor;
        end;

        for vIndex := 0 to High( vRawOneofs ) do
        begin
            // od := &md.L2.Oneofs.List[i]
            // od.unmarshalFull(b, sb, md.L0.ParentFile, md, i)
            UnmarshalOneofFull( ParaMessage.L2.mOneofs.mList[vIndex], vRawOneofs[vIndex], vStringBuilder, ParaMessage.L0.mParentFile, ParaMessage, vIndex );
        end;
    end;

    ParaMessage.L2.mOptions := OptionsUnmarshaler( ParaMessage.L0.mParentFile.mBuilder, @TDescOpts.Message, vRawOptions );
end;

// unmarshalOptions is the Delphi equivalent of func (md *Message) unmarshalOptions(...)
procedure UnmarshalMessageOptions( var ParaMessage : TMessage; ParaBytes : TArray<Byte> );
var
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
begin
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstMessageOptions_MapEntry_field_number :
                    begin
                        ParaMessage.L1.mIsMapEntry := TProtowire.DecodeBool( vVarint );
                    end;

                    ConstMessageOptions_MessageSetWireFormat_field_number :
                    begin
                        ParaMessage.L1.mIsMessageSet := TProtowire.DecodeBool( vVarint );
                    end;
                end;
            end;
        else
            begin
                vVarintM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
            end;
        end;
    end;
end;

// unmarshalMessageReservedRange is the Delphi equivalent of func unmarshalMessageReservedRange(...)
function UnmarshalMessageReservedRange( ParaBytes : TArray<Byte> ) : TArray<TFieldNumber>;
var
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
begin
    SetLength( Result, 2 ); // [2]pref.FieldNumber

    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstDescriptorProto_ReservedRange_Start_field_number :
                    begin
                        Result[0] := TFieldNumber( vVarint );
                    end;

                    ConstDescriptorProto_ReservedRange_End_field_number :
                    begin
                        Result[1] := TFieldNumber( vVarint );
                    end;
                end;
            end;
        else
            begin
                vVarintM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
            end;
        end;
    end;
end;

// unmarshalMessageExtensionRange is the Delphi equivalent of func unmarshalMessageExtensionRange(...)
procedure UnmarshalMessageExtensionRange( ParaBytes : TArray<Byte>; var ParaRange : TArray<TFieldNumber>; var ParaRawOptions : TArray<Byte> );
var
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
begin
    SetLength( ParaRange, 2 ); // [2]pref.FieldNumber
    ParaRawOptions := nil;

    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstDescriptorProto_ExtensionRange_Start_field_number :
                    begin
                        ParaRange[0] := TFieldNumber( vVarint );
                    end;

                    ConstDescriptorProto_ExtensionRange_End_field_number :
                    begin
                        ParaRange[1] := TFieldNumber( vVarint );
                    end;
                end;
            end;

            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstDescriptorProto_ExtensionRange_Options_field_number :
                    begin
                        ParaRawOptions := AppendOptions( ParaRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vVarintM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
            end;
        end;
    end;
end;

// unmarshalFull is the Delphi equivalent of func (fd *Field) unmarshalFull(...)
procedure UnmarshalFieldFull
(
    var ParaField : TField;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
const
    ConstFieldOptions_EnforceUTF8 = 13;
var
    vRawTypeName : TArray<Byte>;
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vMessageDescriptor : TMessage; // To cast ParaParentDescriptor
    vOneofDescriptor : TOneof;
begin
    ParaField.L0.mParentFile := ParaFile;
    ParaField.L0.mParent := ParaParentDescriptor;
    ParaField.L0.mIndex := ParaIndex;

    vRawTypeName := nil;
    vRawOptions := nil;
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstFieldDescriptorProto_Number_field_number :
                    begin
                        ParaField.L1.mNumber := TFieldNumber( vVarint );
                    end;
                    ConstFieldDescriptorProto_Label_field_number :
                    begin
                        ParaField.L1.mCardinality := TCardinality( vVarint );
                    end;
                    ConstFieldDescriptorProto_Type_field_number :
                    begin
                        ParaField.L1.mKind := TKind( vVarint );
                    end;

                    ConstFieldDescriptorProto_OneofIndex_field_number :
                    begin
                        // Go's type assertion for Message: pd.(*Message)
                        // Assuming TMessage implements the IDescriptor interface.
                        vMessageDescriptor := ParaParentDescriptor as TMessage;
                        
                        vOneofDescriptor := vMessageDescriptor.L2.mOneofs.mList[vVarint];
                        
                        // od.L1.Fields.List = append(od.L1.Fields.List, fd)
                        vOneofDescriptor.L1.mFields.mList := vOneofDescriptor.L1.mFields.mList + [ @ParaField ]; // Storing a pointer/reference to the field

                        if ParaField.L1.mContainingOneof <> nil then
                        begin
                            raise Exception.Create( 'oneof type already set' );
                        end;

                        ParaField.L1.mContainingOneof := @vOneofDescriptor;
                        vMessageDescriptor.L2.mOneofs.mList[vVarint] := vOneofDescriptor;
                    end;

                    ConstFieldDescriptorProto_Proto3Optional_field_number :
                    begin
                        ParaField.L1.mIsProto3Optional := TProtowire.DecodeBool( vVarint );
                    end;

                    ConstFieldOptions_Packed_field_number :
                    begin
                        ParaField.L1.mHasPacked := True;
                        ParaField.L1.mIsPacked := TProtowire.DecodeBool( vVarint );
                    end;

                    ConstFieldOptions_Weak_field_number :
                    begin
                        ParaField.L1.mIsWeak := TProtowire.DecodeBool( vVarint );
                    end;

                    ConstFieldOptions_EnforceUTF8 :
                    begin
                        ParaField.L1.mHasEnforceUTF8 := True;
                        ParaField.L1.mEnforceUTF8 := TProtowire.DecodeBool( vVarint );
                    end;
                end;
            end;

            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstFieldDescriptorProto_Name_field_number :
                    begin
                        ParaField.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.FullName,
                            vConsumeValue
                        );
                    end;

                    ConstFieldDescriptorProto_JsonName_field_number :
                    begin
                        ParaField.L1.mStringName.InitJSON( ParaStringBuilder.MakeString( vConsumeValue ) );
                    end;

                    ConstFieldDescriptorProto_DefaultValue_field_number :
                    begin
                        ParaField.L1.mDefault.mVal := TValueOfBytes.Create( vConsumeValue ); // Assuming TValueOfBytes is the type for pref.ValueOfBytes
                    end;

                    ConstFieldDescriptorProto_TypeName_field_number :
                    begin
                        vRawTypeName := vConsumeValue;
                    end;

                    ConstFieldDescriptorProto_Options_field_number :
                    begin
                        // fd.unmarshalOptions(v) is inlined in Go, but here we only handle options that modify the struct directly.
                        // The rest are appended to rawOptions.
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vVarintM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
            end;
        end;
    end;

    if vRawTypeName <> nil then
    begin
        vRawTypeName := MakeFullName( ParaStringBuilder, vRawTypeName );
        case ParaField.L1.mKind of
            TKind.EnumKind :
            begin
                ParaField.L1.mEnum := TPlaceholderEnum.Create( vRawTypeName ); // Assuming TPlaceholderEnum type
            end;
            TKind.MessageKind, TKind.GroupKind :
            begin
                ParaField.L1.mMessage := TPlaceholderMessage.Create( vRawTypeName );
            end;
        end;
    end;

    // fd.L1.Options = pf.builder.optionsUnmarshaler(&descopts.Field, rawOptions)
    ParaField.L1.mOptions := OptionsUnmarshaler( ParaFile.mBuilder, @TDescOpts.Field, vRawOptions );
end;

// unmarshalFull is the Delphi equivalent of func (od *Oneof) unmarshalFull(...)
procedure UnmarshalOneofFull
(
    var ParaOneof : TOneof;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
var
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
begin
    ParaOneof.L0.mParentFile := ParaFile;
    ParaOneof.L0.mParent := ParaParentDescriptor;
    ParaOneof.L0.mIndex := ParaIndex;

    vRawOptions := nil;
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstOneofDescriptorProto_Name_field_number :
                    begin
                        ParaOneof.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.FullName,
                            vConsumeValue
                        );
                    end;

                    ConstOneofDescriptorProto_Options_field_number :
                    begin
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
            end;
        end;
    end;

    // od.L1.Options = pf.builder.optionsUnmarshaler(&descopts.Oneof, rawOptions)
    ParaOneof.L1.mOptions := OptionsUnmarshaler( ParaFile.mBuilder, @TDescOpts.Oneof, vRawOptions );
end;

// unmarshalFull is the Delphi equivalent of func (xd *Extension) unmarshalFull(...)
procedure UnmarshalExtensionFull( var ParaExtension : TExtension; ParaBytes : TArray<Byte>; ParaStringBuilder : TStrBuilder );
var
    vRawTypeName : TArray<Byte>;
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
begin
    vRawTypeName := nil;
    vRawOptions := nil;

    ParaExtension.L2 := TExtensionL2.Create;
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstFieldDescriptorProto_Proto3Optional_field_number :
                    begin
                        ParaExtension.L2.mIsProto3Optional := TProtowire.DecodeBool( vVarint );
                    end;

                    ConstFieldOptions_Packed_field_number :
                    begin
                        ParaExtension.L2.mIsPacked := TProtowire.DecodeBool( vVarint );
                    end;
                end;
            end;

            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstFieldDescriptorProto_JsonName_field_number :
                    begin
                        ParaExtension.L2.mStringName.InitJSON( ParaStringBuilder.MakeString( vConsumeValue ) );
                    end;

                    ConstFieldDescriptorProto_DefaultValue_field_number :
                    begin
                        ParaExtension.L2.mDefault.mVal := TValueOfBytes.Create( vConsumeValue ); // temporarily store as bytes; later resolved
                    end;

                    ConstFieldDescriptorProto_TypeName_field_number :
                    begin
                        vRawTypeName := vConsumeValue;
                    end;

                    ConstFieldDescriptorProto_Options_field_number :
                    begin
                        // xd.unmarshalOptions(v) is partially inlined in Go, but here we only extract the raw options.
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vVarintM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
            end;
        end;
    end;

    if vRawTypeName <> nil then
    begin
        vRawTypeName := MakeFullName( ParaStringBuilder, vRawTypeName );
        case ParaExtension.L1.mKind of
            TKind.EnumKind :
            begin
                ParaExtension.L2.mEnum := TPlaceholderEnum.Create( vRawTypeName );
            end;
            TKind.MessageKind, TKind.GroupKind :
            begin
                ParaExtension.L2.mMessage := TPlaceholderMessage.Create( vRawTypeName );
            end;
        end;
    end;

    // xd.L2.Options = xd.L0.ParentFile.builder.optionsUnmarshaler(&descopts.Field, rawOptions)
    ParaExtension.L2.mOptions := OptionsUnmarshaler( ParaExtension.L0.mParentFile.mBuilder, @TDescOpts.Field, vRawOptions );
end;


// unmarshalFull is the Delphi equivalent of func (sd *Service) unmarshalFull(...)
procedure UnmarshalServiceFull( var ParaService : TService; ParaBytes : TArray<Byte>; ParaStringBuilder : TStrBuilder );
var
    vRawMethods : TArray<TArray<Byte>>;
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vIndex : Integer;
begin
    vRawMethods := TArray<TArray<Byte>>.Create;
    vRawOptions := nil;

    ParaService.L2 := TServiceL2.Create;
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstServiceDescriptorProto_Method_field_number :
                    begin
                        vRawMethods := vRawMethods + [ vConsumeValue ];
                    end;

                    ConstServiceDescriptorProto_Options_field_number :
                    begin
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
            end;
        end;
    end;

    if Length( vRawMethods ) > 0 then
    begin
        SetLength( ParaService.L2.mMethods.mList, Length( vRawMethods ) );
        for vIndex := 0 to High( vRawMethods ) do
        begin
            // unmarshalFull(b, sb, sd.L0.ParentFile, sd, i)
            UnmarshalMethodFull( ParaService.L2.mMethods.mList[vIndex], vRawMethods[vIndex], vStringBuilder, ParaService.L0.mParentFile, ParaService, vIndex );
        end;
    end;

    // sd.L2.Options = sd.L0.ParentFile.builder.optionsUnmarshaler(&descopts.Service, rawOptions)
    ParaService.L2.mOptions := OptionsUnmarshaler( ParaService.L0.mParentFile.mBuilder, @TDescOpts.Service, vRawOptions );
end;

// unmarshalFull is the Delphi equivalent of func (md *Method) unmarshalFull(...)
procedure UnmarshalMethodFull
(
    var ParaMethod : TMethod;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
var
    vRawOptions : TArray<Byte>;
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vVarint : UInt64;
    vVarintM : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
begin
    ParaMethod.L0.mParentFile := ParaFile;
    ParaMethod.L0.mParent := ParaParentDescriptor;
    ParaMethod.L0.mIndex := ParaIndex;

    vRawOptions := nil;
    vBytes := ParaBytes;
    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.VarintType :
            begin
                vVarint := TProtowire.ConsumeVarint( vBytes, vVarintM );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );

                case vTagNumber of
                    ConstMethodDescriptorProto_ClientStreaming_field_number :
                    begin
                        ParaMethod.L1.mIsStreamingClient := TProtowire.DecodeBool( vVarint );
                    end;

                    ConstMethodDescriptorProto_ServerStreaming_field_number :
                    begin
                        ParaMethod.L1.mIsStreamingServer := TProtowire.DecodeBool( vVarint );
                    end;
                end;
            end;

            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstMethodDescriptorProto_Name_field_number :
                    begin
                        ParaMethod.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.FullName,
                            vConsumeValue
                        );
                    end;

                    ConstMethodDescriptorProto_InputType_field_number :
                    begin
                        ParaMethod.L1.mInput := TPlaceholderMessage.Create( MakeFullName( ParaStringBuilder, vConsumeValue ) );
                    end;

                    ConstMethodDescriptorProto_OutputType_field_number :
                    begin
                        ParaMethod.L1.mOutput := TPlaceholderMessage.Create( MakeFullName( ParaStringBuilder, vConsumeValue ) );
                    end;

                    ConstMethodDescriptorProto_Options_field_number :
                    begin
                        vRawOptions := AppendOptions( vRawOptions, vConsumeValue );
                    end;
                end;
            end;
        else
            begin
                vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
            end;
        end;
    end;

    // md.L1.Options = pf.builder.optionsUnmarshaler(&descopts.Method, rawOptions)
    ParaMethod.L1.mOptions := OptionsUnmarshaler( ParaFile.mBuilder, @TDescOpts.Method, vRawOptions );
end;


initialization
    // Finalization section is handled by the Destroy of TGoOnce instances created in OptionsUnmarshaler

finalization
    // Clean up TGoOnce instances

end.