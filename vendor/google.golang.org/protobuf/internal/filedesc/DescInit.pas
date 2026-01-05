{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc.DescInit;

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
  SyncObjs,
  Generics.Collections,
  Protowire, // Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire
  Genid, // Vendor.Google.Golang.Org.Protobuf.Internal.Genid
  Strs, // Vendor.Google.Golang.Org.Protobuf.Internal.Strs
  Protoreflect, // Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect
  Core; // Assumed unit for TFile, TEnum, IBuilder, TProtoSyntax, etc.
{$ELSE}
  System.SyncObjs,
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Genid,
  Vendor.Google.Golang.Org.Protobuf.Internal.Strs,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc.Core; // Assumed core types
{$ENDIF}

// Forward declarations/Aliases for types used only in implementation,
// assuming their full definition is in Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc.Core
type
    TFile = record end; // Placeholder
    TEnum = record end; // Placeholder
    TMessage = record end; // Placeholder
    TExtension = record end; // Placeholder
    TService = record end; // Placeholder
    IBuilder = interface end; // Placeholder
    IDescriptor = interface end; // Placeholder for pref.Descriptor
    TStrBuilder = class(TObject) end; // Placeholder for strs.Builder
    TFullName = type String; // Placeholder for pref.FullName
    TName = type String; // Placeholder for pref.Name
    TFieldNumber = type Integer; // Placeholder for pref.FieldNumber
    TWireType = type Cardinal; // Placeholder for protowire.Type

// fileRaw is a data struct used when initializing a file descriptor from
// a raw FileDescriptorProto.
TFileRaw = record
    mBuilder : IBuilder;
    mAllEnums : TArray<TEnum>;
    mAllMessages : TArray<TMessage>;
    mAllExtensions : TArray<TExtension>;
    mAllServices : TArray<TService>;
end;

// --- Private Pool Management (Go's sync.Pool equivalent) ---
var
    vNameBuilderPool : TList<TStrBuilder>;
    vNameBuilderPoolLock : TCriticalSection;
    vNameBuilderPoolInitialized : Boolean = False;

procedure InitNameBuilderPool;
begin
    vNameBuilderPoolLock := nil;
    vNameBuilderPool := nil;

    try
        vNameBuilderPoolLock := TCriticalSection.Create;
        vNameBuilderPool := TList<TStrBuilder>.Create;
        vNameBuilderPoolInitialized := True;
    except
        on E: EOutOfMemory do
        begin
            vNameBuilderPoolLock.Free;
            vNameBuilderPool.Free;
            raise Exception.Create( 'Failed to initialize name builder pool due to EOutOfMemory: ' + E.Message );
        end;
        on E: Exception do
        begin
            vNameBuilderPoolLock.Free;
            vNameBuilderPool.Free;
            raise Exception.Create( 'Unexpected error during name builder pool initialization: ' + E.Message );
        end;
    end;
end;

procedure CheckPoolInitialized;
begin
    if not vNameBuilderPoolInitialized then
    begin
        raise Exception.Create( 'Name builder pool was not initialized correctly.' );
    end;
end;

function GetBuilder: TStrBuilder;
begin
    CheckPoolInitialized;
    vNameBuilderPoolLock.Acquire;
    try
        if vNameBuilderPool.Count > 0 then
        begin
            Result := vNameBuilderPool[vNameBuilderPool.Count - 1];
            vNameBuilderPool.Delete( vNameBuilderPool.Count - 1 );
        end else
        begin
            // Go's New func() interface{} { return new(strs.Builder) }
            Result := TStrBuilder.Create;
        end;
    finally
        vNameBuilderPoolLock.Release;
    end;
end;

procedure PutBuilder( ParaBuilder : TStrBuilder );
begin
    CheckPoolInitialized;
    vNameBuilderPoolLock.Acquire;
    try
        vNameBuilderPool.Add( ParaBuilder );
    finally
        vNameBuilderPoolLock.Release;
    end;
end;

// --- Private Utility Functions ---

// makeFullName converts b to a protoreflect.FullName,
// where b must start with a leading dot.
function MakeFullName( ParaStringBuilder : TStrBuilder; ParaBytes : TArray<Byte> ) : TFullName;
var
    vBytesLength : Integer;
begin
    vBytesLength := Length( ParaBytes );

    if ( vBytesLength = 0 ) or ( ParaBytes[0] <> Ord( '.' ) ) then
    begin
        raise Exception.Create( 'name reference must be fully qualified' );
    end;

    // Pref.FullName(sb.MakeString(b[1:]))
    Result := TFullName( ParaStringBuilder.MakeString
    (
        TStrs.UnsafeString
        (
            Copy( ParaBytes, 1, vBytesLength - 1 ) // Copy from index 1 (Delphi 1-based) for (b[1:])
        )
    ) );
end;

// appendFullName appends a suffix to a prefix to form a full name.
function AppendFullName( ParaStringBuilder : TStrBuilder; ParaPrefix : TFullName; ParaSuffix : TArray<Byte> ) : TFullName;
begin
    // sb.AppendFullName(prefix, pref.Name(strs.UnsafeString(suffix)))
    Result := ParaStringBuilder.AppendFullName
    (
        ParaPrefix,
        TName( TStrs.UnsafeString( ParaSuffix ) )
    );
end;

// --- Core Initialization Functions (Unexported) ---

// initDecls pre-allocates slices for the exact number of enums, messages
// (including map entries), extensions, and services declared in the proto file.
// This is done to avoid regrowing the slice, which would change the address
// for any previously seen declaration.
//
// The alloc methods "allocates" slices by pulling from the capacity.
procedure InitDecls
(
    var ParaFile : TFile;
    ParaNumEnums : Integer;
    ParaNumMessages : Integer;
    ParaNumExtensions : Integer;
    ParaNumServices : Integer
);
begin
    // Assumption: ParaFile is a record/class containing mFileRaw, which is TFileRaw record.
    try
        // fd.allEnums = make([]Enum, 0, numEnums)
        SetLength( ParaFile.mFileRaw.mAllEnums, 0, ParaNumEnums );

        // fd.allMessages = make([]Message, 0, numMessages)
        SetLength( ParaFile.mFileRaw.mAllMessages, 0, ParaNumMessages );

        // fd.allExtensions = make([]Extension, 0, numExtensions)
        SetLength( ParaFile.mFileRaw.mAllExtensions, 0, ParaNumExtensions );

        // fd.allServices = make([]Service, 0, numServices)
        SetLength( ParaFile.mFileRaw.mAllServices, 0, ParaNumServices );
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Memory allocation failed in InitDecls: ' + E.Message );
        end;
        on E: Exception do
        begin
            raise Exception.Create( 'Unexpected error during array resizing in InitDecls: ' + E.Message );
        end;
    end;
end;

// The alloc methods "allocates" slices by pulling from the capacity.
// NOTE: Since Delphi dynamic array Copy/SetLength is used, we only return a copy
// that will be modified by the caller, and the master array length is updated.
// This deviates from Go's slicing that shares the underlying array but maintains functional equivalence.

function AllocEnums( var ParaFile : TFile; ParaN : Integer ) : TArray<TEnum>;
var
    vTotal : Integer;
begin
    vTotal := Length( ParaFile.mFileRaw.mAllEnums );

    // In a direct Go to Delphi slice conversion, we cannot guarantee the Go behavior of
    // returning a slice that still points to the underlying capacity.
    // We update the length and return the newly allocated portion's data.

    // If we assume TFile is a class, we need to ensure the correct capacity check.
    if vTotal + ParaN > Capacity( ParaFile.mFileRaw.mAllEnums ) then
    begin
        raise Exception.Create( 'Attempt to allocate more enums than capacity permits' );
    end;

    // Get the slice to be populated (this is only a conceptual slice, in reality, it's a new array in Delphi)
    Result := Copy( ParaFile.mFileRaw.mAllEnums, vTotal, ParaN );

    // Update the length of the original array
    try
        SetLength( ParaFile.mFileRaw.mAllEnums, vTotal + ParaN );
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Failed to grow TFile.mFileRaw.mAllEnums array length: ' + E.Message );
        end;
    end;
end;

function AllocMessages( var ParaFile : TFile; ParaN : Integer ) : TArray<TMessage>;
var
    vTotal : Integer;
begin
    vTotal := Length( ParaFile.mFileRaw.mAllMessages );
    if vTotal + ParaN > Capacity( ParaFile.mFileRaw.mAllMessages ) then
    begin
        raise Exception.Create( 'Attempt to allocate more messages than capacity permits' );
    end;
    Result := Copy( ParaFile.mFileRaw.mAllMessages, vTotal, ParaN );

    try
        SetLength( ParaFile.mFileRaw.mAllMessages, vTotal + ParaN );
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Failed to grow TFile.mFileRaw.mAllMessages array length: ' + E.Message );
        end;
    end;
end;

function AllocExtensions( var ParaFile : TFile; ParaN : Integer ) : TArray<TExtension>;
var
    vTotal : Integer;
begin
    vTotal := Length( ParaFile.mFileRaw.mAllExtensions );
    if vTotal + ParaN > Capacity( ParaFile.mFileRaw.mAllExtensions ) then
    begin
        raise Exception.Create( 'Attempt to allocate more extensions than capacity permits' );
    end;
    Result := Copy( ParaFile.mFileRaw.mAllExtensions, vTotal, ParaN );

    try
        SetLength( ParaFile.mFileRaw.mAllExtensions, vTotal + ParaN );
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Failed to grow TFile.mFileRaw.mAllExtensions array length: ' + E.Message );
        end;
    end;
end;

function AllocServices( var ParaFile : TFile; ParaN : Integer ) : TArray<TService>;
var
    vTotal : Integer;
begin
    vTotal := Length( ParaFile.mFileRaw.mAllServices );
    if vTotal + ParaN > Capacity( ParaFile.mFileRaw.mAllServices ) then
    begin
        raise Exception.Create( 'Attempt to allocate more services than capacity permits' );
    end;
    Result := Copy( ParaFile.mFileRaw.mAllServices, vTotal, ParaN );

    try
        SetLength( ParaFile.mFileRaw.mAllServices, vTotal + ParaN );
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Failed to grow TFile.mFileRaw.mAllServices array length: ' + E.Message );
        end;
    end;
end;

// checkDecls performs a sanity check that the expected number of expected
// declarations matches the number that were found in the descriptor proto.
procedure CheckDecls( ParaFile : TFile );
begin
    // Check lengths vs capacities.
    if Length( ParaFile.mFileRaw.mAllEnums ) <> Capacity( ParaFile.mFileRaw.mAllEnums ) then
    begin
        raise Exception.Create( 'mismatching cardinality for AllEnums' );
    end;

    if Length( ParaFile.mFileRaw.mAllMessages ) <> Capacity( ParaFile.mFileRaw.mAllMessages ) then
    begin
        raise Exception.Create( 'mismatching cardinality for AllMessages' );
    end;

    if Length( ParaFile.mFileRaw.mAllExtensions ) <> Capacity( ParaFile.mFileRaw.mAllExtensions ) then
    begin
        raise Exception.Create( 'mismatching cardinality for AllExtensions' );
    end;

    if Length( ParaFile.mFileRaw.mAllServices ) <> Capacity( ParaFile.mFileRaw.mAllServices ) then
    begin
        raise Exception.Create( 'mismatching cardinality for AllServices' );
    end;
end;

// unmarshalSeed unmarshals the raw descriptor bytes into the file descriptor.
// NOTE: TProtowire functions are assumed to be static methods of a class/record,
// and `protowire.ConsumeTag` is assumed to return the consumed tag number and wire type
// via var parameters, and the length consumed `n` via a var parameter or the function result.
procedure UnmarshalSeed( var ParaFile : TFile; ParaBytes : TArray<Byte> );
var
    vStringBuilder : TStrBuilder;
    vPrevField : TFieldNumber;
    vNumEnums, vNumMessages, vNumExtensions, vNumServices : Integer;
    vPosEnums, vPosMessages, vPosExtensions, vPosServices : Integer;
    vBytes : TArray<Byte>; // Represents b (the current slice)
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vVarintM : Integer;
    vStartOffset : Integer;
    vB0Length : Integer;
    vVarintConsumedN : Integer;
    vIndex : Integer;
begin
    vStringBuilder := GetBuilder;
    try
        // Initialization
        vBytes := ParaBytes;
        vPrevField := -1; // -1 to avoid matching any known field on first iteration
        vNumEnums := 0;
        vNumMessages := 0;
        vNumExtensions := 0;
        vNumServices := 0;
        vPosEnums := 0;
        vPosMessages := 0;
        vPosExtensions := 0;
        vPosServices := 0;
        vB0Length := Length( ParaBytes );

        // b0 := b in go, ParaBytes in Delphi
        while Length( vBytes ) > 0 do
        begin
            // num, typ, n := protowire.ConsumeTag(b)
            vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );

            // Calculate the position of the field tag relative to the start of ParaBytes
            // For the first field of a repeated section, this position is needed to start
            // the second unmarshalling pass.
            vStartOffset := vB0Length - Length( vBytes );

            // b = b[n:]
            vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

            case vWireType of
                TWireType.BytesType :
                begin
                    // v, m := protowire.ConsumeBytes(b)
                    vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );

                    // b = b[m:]
                    vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                    case vTagNumber of
                        ConstFileDescriptorProto_Syntax_field_number :
                        begin
                            case TStrs.UnsafeString( vConsumeValue ) of
                                'proto2' :
                                begin
                                    ParaFile.L1.mSyntax := TProtoSyntax.Proto2;
                                end;

                                'proto3' :
                                begin
                                    ParaFile.L1.mSyntax := TProtoSyntax.Proto3;
                                end;
                            else
                                begin
                                    raise Exception.Create( 'invalid syntax' );
                                end;
                            end;
                        end;

                        ConstFileDescriptorProto_Name_field_number :
                        begin
                            ParaFile.L1.mPath := vStringBuilder.MakeString( vConsumeValue );
                        end;

                        ConstFileDescriptorProto_Package_field_number :
                        begin
                            ParaFile.L1.mPackage := TFullName( vStringBuilder.MakeString( vConsumeValue ) );
                        end;

                        ConstFileDescriptorProto_EnumType_field_number :
                        begin
                            if vPrevField <> ConstFileDescriptorProto_EnumType_field_number then
                            begin
                                if vNumEnums > 0 then
                                begin
                                    raise Exception.Create( 'non-contiguous repeated field for EnumType' );
                                end;
                                // posEnums = len(b0) - len(b) - n - m
                                vPosEnums := vStartOffset - vConsumeValueM;
                            end;
                            Inc( vNumEnums );
                        end;

                        ConstFileDescriptorProto_MessageType_field_number :
                        begin
                            if vPrevField <> ConstFileDescriptorProto_MessageType_field_number then
                            begin
                                if vNumMessages > 0 then
                                begin
                                    raise Exception.Create( 'non-contiguous repeated field for MessageType' );
                                end;
                                vPosMessages := vStartOffset - vConsumeValueM;
                            end;
                            Inc( vNumMessages );
                        end;

                        ConstFileDescriptorProto_Extension_field_number :
                        begin
                            if vPrevField <> ConstFileDescriptorProto_Extension_field_number then
                            begin
                                if vNumExtensions > 0 then
                                begin
                                    raise Exception.Create( 'non-contiguous repeated field for Extension' );
                                end;
                                vPosExtensions := vStartOffset - vConsumeValueM;
                            end;
                            Inc( vNumExtensions );
                        end;

                        ConstFileDescriptorProto_Service_field_number :
                        begin
                            if vPrevField <> ConstFileDescriptorProto_Service_field_number then
                            begin
                                if vNumServices > 0 then
                                begin
                                    raise Exception.Create( 'non-contiguous repeated field for Service' );
                                end;
                                vPosServices := vStartOffset - vConsumeValueM;
                            end;
                            Inc( vNumServices );
                        end;
                    end;
                    vPrevField := vTagNumber;
                end;
            else
                begin
                    // m := protowire.ConsumeFieldValue(num, typ, b)
                    vVarintM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                    vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
                    vPrevField := -1;
                end;
            end;
        end;

        // If syntax is missing, it is assumed to be proto2.
        if ParaFile.L1.mSyntax = 0 then
        begin
            ParaFile.L1.mSyntax := TProtoSyntax.Proto2;
        end;

        // Must allocate all declarations before parsing each descriptor type
        // to ensure we handled all descriptors in "flattened ordering".
        if vNumEnums > 0 then
        begin
            ParaFile.L1.mEnums.mList := AllocEnums( ParaFile, vNumEnums );
        end;
        if vNumMessages > 0 then
        begin
            ParaFile.L1.mMessages.mList := AllocMessages( ParaFile, vNumMessages );
        end;
        if vNumExtensions > 0 then
        begin
            ParaFile.L1.mExtensions.mList := AllocExtensions( ParaFile, vNumExtensions );
        end;
        if vNumServices > 0 then
        begin
            ParaFile.L1.mServices.mList := AllocServices( ParaFile, vNumServices );
        end;

        // Second pass: unmarshal actual descriptor payloads
        // Note: For Delphi array/Copy, the index starts at 1.

        if vNumEnums > 0 then
        begin
            vBytes := Copy( ParaBytes, vPosEnums + 1, Length( ParaBytes ) - vPosEnums );
            for vIndex := Low( ParaFile.L1.mEnums.mList ) to High( ParaFile.L1.mEnums.mList ) do
            begin
                // _, n := protowire.ConsumeVarint(b)
                vVarintConsumedN := TProtowire.ConsumeVarint( vBytes, vTagNumber, vWireType, vConsumeTagN );

                // v, m := protowire.ConsumeBytes(b[n:])
                vConsumeValue := TProtowire.ConsumeBytes( Copy( vBytes, vVarintConsumedN + 1, Length( vBytes ) - vVarintConsumedN ), vConsumeValueM );

                // fd.L1.Enums.List[i].unmarshalSeed(v, sb, fd, fd, i)
                UnmarshalEnumSeed( ParaFile.L1.mEnums.mList[vIndex], vConsumeValue, vStringBuilder, ParaFile, ParaFile, vIndex );

                // b = b[n+m:]
                vBytes := Copy( vBytes, vVarintConsumedN + vConsumeValueM + 1, Length( vBytes ) - ( vVarintConsumedN + vConsumeValueM ) );
            end;
        end;

        if vNumMessages > 0 then
        begin
            vBytes := Copy( ParaBytes, vPosMessages + 1, Length( ParaBytes ) - vPosMessages );
            for vIndex := Low( ParaFile.L1.mMessages.mList ) to High( ParaFile.L1.mMessages.mList ) do
            begin
                vVarintConsumedN := TProtowire.ConsumeVarint( vBytes, vTagNumber, vWireType, vConsumeTagN );
                vConsumeValue := TProtowire.ConsumeBytes( Copy( vBytes, vVarintConsumedN + 1, Length( vBytes ) - vVarintConsumedN ), vConsumeValueM );
                UnmarshalMessageSeed( ParaFile.L1.mMessages.mList[vIndex], vConsumeValue, vStringBuilder, ParaFile, ParaFile, vIndex );
                vBytes := Copy( vBytes, vVarintConsumedN + vConsumeValueM + 1, Length( vBytes ) - ( vVarintConsumedN + vConsumeValueM ) );
            end;
        end;

        if vNumExtensions > 0 then
        begin
            vBytes := Copy( ParaBytes, vPosExtensions + 1, Length( ParaBytes ) - vPosExtensions );
            for vIndex := Low( ParaFile.L1.mExtensions.mList ) to High( ParaFile.L1.mExtensions.mList ) do
            begin
                vVarintConsumedN := TProtowire.ConsumeVarint( vBytes, vTagNumber, vWireType, vConsumeTagN );
                vConsumeValue := TProtowire.ConsumeBytes( Copy( vBytes, vVarintConsumedN + 1, Length( vBytes ) - vVarintConsumedN ), vConsumeValueM );
                UnmarshalExtensionSeed( ParaFile.L1.mExtensions.mList[vIndex], vConsumeValue, vStringBuilder, ParaFile, ParaFile, vIndex );
                vBytes := Copy( vBytes, vVarintConsumedN + vConsumeValueM + 1, Length( vBytes ) - ( vVarintConsumedN + vConsumeValueM ) );
            end;
        end;

        if vNumServices > 0 then
        begin
            vBytes := Copy( ParaBytes, vPosServices + 1, Length( ParaBytes ) - vPosServices );
            for vIndex := Low( ParaFile.L1.mServices.mList ) to High( ParaFile.L1.mServices.mList ) do
            begin
                vVarintConsumedN := TProtowire.ConsumeVarint( vBytes, vTagNumber, vWireType, vConsumeTagN );
                vConsumeValue := TProtowire.ConsumeBytes( Copy( vBytes, vVarintConsumedN + 1, Length( vBytes ) - vVarintConsumedN ), vConsumeValueM );
                UnmarshalServiceSeed( ParaFile.L1.mServices.mList[vIndex], vConsumeValue, vStringBuilder, ParaFile, ParaFile, vIndex );
                vBytes := Copy( vBytes, vVarintConsumedN + vConsumeValueM + 1, Length( vBytes ) - ( vVarintConsumedN + vConsumeValueM ) );
            end;
        end;
    finally
        PutBuilder( vStringBuilder );
    end;
end;


// UnmarshalEnumSeed is the Delphi equivalent of func (ed *Enum) unmarshalSeed(...)
procedure UnmarshalEnumSeed
(
    var ParaEnum : TEnum;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
var
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vNumValues : Integer;
    vIndex : Integer;
begin
    ParaEnum.L0.mParentFile := ParaFile;
    ParaEnum.L0.mParent := ParaParentDescriptor;
    ParaEnum.L0.mIndex := ParaIndex;

    vNumValues := 0;
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
                    ConstEnumDescriptorProto_Name_field_number :
                    begin
                        ParaEnum.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.FullName,
                            vConsumeValue
                        );
                    end;

                    ConstEnumDescriptorProto_Value_field_number :
                    begin
                        Inc( vNumValues );
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

    // Only construct enum value descriptors for top-level enums since
    // they are needed for registration.
    // Assuming the descriptor interface (IDescriptor) can be compared to the file class (TFile)
    if not TObject( ParaParentDescriptor ).InheritsFrom( TObject( ParaFile ).ClassType ) then
    begin
        Exit;
    end;

    // ed.L1.eagerValues = true
    ParaEnum.L1.mEagerValues := True;

    // ed.L2 = new(EnumL2)
    // Delphi equivalent: allocate the L2 class and array
    ParaEnum.L2 := TEnumL2.Create; // Assuming TEnumL2 is a class
    try
        SetLength( ParaEnum.L2.mValues.mList, vNumValues );
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create( 'Failed to resize enum values array: ' + E.Message );
        end;
    end;

    vBytes := ParaBytes;
    vIndex := 0;
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
                        // ed.L2.Values.List[i].unmarshalFull(v, sb, pf, ed, i)
                        // Assuming UnmarshalEnumValueFull is defined elsewhere
                        UnmarshalEnumValueFull( ParaEnum.L2.mValues.mList[vIndex], vConsumeValue, ParaStringBuilder, ParaFile, ParaEnum, vIndex );
                        Inc( vIndex );
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
end;

// UnmarshalMessageSeed is the Delphi equivalent of func (md *Message) unmarshalSeed(...)
procedure UnmarshalMessageSeed
(
    var ParaMessage : TMessage;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
var
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
    vPrevField : TFieldNumber;
    vNumEnums, vNumMessages, vNumExtensions : Integer;
    vPosEnums, vPosMessages, vPosExtensions : Integer;
    vStartOffset : Integer;
    vB0Length : Integer;
    vVarintConsumedN : Integer;
    vIndex : Integer;
begin
    ParaMessage.L0.mParentFile := ParaFile;
    ParaMessage.L0.mParent := ParaParentDescriptor;
    ParaMessage.L0.mIndex := ParaIndex;

    vBytes := ParaBytes;
    vB0Length := Length( ParaBytes );
    vPrevField := -1;
    vNumEnums := 0;
    vNumMessages := 0;
    vNumExtensions := 0;

    while Length( vBytes ) > 0 do
    begin
        vTagNumber := TProtowire.ConsumeTag( vBytes, vWireType, vConsumeTagN );
        vStartOffset := vB0Length - Length( vBytes );
        vBytes := Copy( vBytes, vConsumeTagN + 1, Length( vBytes ) - vConsumeTagN );

        case vWireType of
            TWireType.BytesType :
            begin
                vConsumeValue := TProtowire.ConsumeBytes( vBytes, vConsumeValueM );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );

                case vTagNumber of
                    ConstDescriptorProto_Name_field_number :
                    begin
                        ParaMessage.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.FullName,
                            vConsumeValue
                        );
                    end;

                    ConstDescriptorProto_EnumType_field_number :
                    begin
                        if vPrevField <> ConstDescriptorProto_EnumType_field_number then
                        begin
                            if vNumEnums > 0 then
                            begin
                                raise Exception.Create( 'non-contiguous repeated field for EnumType' );
                            end;
                            vPosEnums := vStartOffset - vConsumeValueM;
                        end;
                        Inc( vNumEnums );
                    end;

                    ConstDescriptorProto_NestedType_field_number :
                    begin
                        if vPrevField <> ConstDescriptorProto_NestedType_field_number then
                        begin
                            if vNumMessages > 0 then
                            begin
                                raise Exception.Create( 'non-contiguous repeated field for NestedType' );
                            end;
                            vPosMessages := vStartOffset - vConsumeValueM;
                        end;
                        Inc( vNumMessages );
                    end;

                    ConstDescriptorProto_Extension_field_number :
                    begin
                        if vPrevField <> ConstDescriptorProto_Extension_field_number then
                        begin
                            if vNumExtensions > 0 then
                            begin
                                raise Exception.Create( 'non-contiguous repeated field for Extension' );
                            end;
                            vPosExtensions := vStartOffset - vConsumeValueM;
                        end;
                        Inc( vNumExtensions );
                    end;

                    ConstDescriptorProto_Options_field_number :
                    begin
                        UnmarshalMessageSeedOptions( ParaMessage, vConsumeValue );
                    end;
                end;
                vPrevField := vTagNumber;
            end;
        else
            begin
                vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vConsumeValueM + 1, Length( vBytes ) - vConsumeValueM );
                vPrevField := -1;
            end;
        end;
    end;

    // Must allocate all declarations before parsing each descriptor type
    if vNumEnums > 0 then
    begin
        ParaMessage.L1.mEnums.mList := ParaFile.AllocEnums( vNumEnums ); // Assuming AllocEnums is a method of TFile
    end;
    if vNumMessages > 0 then
    begin
        ParaMessage.L1.mMessages.mList := ParaFile.AllocMessages( vNumMessages );
    end;
    if vNumExtensions > 0 then
    begin
        ParaMessage.L1.mExtensions.mList := ParaFile.AllocExtensions( vNumExtensions );
    end;

    // Second pass to unmarshal declarations
    if vNumEnums > 0 then
    begin
        vBytes := Copy( ParaBytes, vPosEnums + 1, Length( ParaBytes ) - vPosEnums );
        for vIndex := Low( ParaMessage.L1.mEnums.mList ) to High( ParaMessage.L1.mEnums.mList ) do
        begin
            vVarintConsumedN := TProtowire.ConsumeVarint( vBytes, vTagNumber, vWireType, vConsumeTagN );
            vConsumeValue := TProtowire.ConsumeBytes( Copy( vBytes, vVarintConsumedN + 1, Length( vBytes ) - vVarintConsumedN ), vConsumeValueM );
            UnmarshalEnumSeed( ParaMessage.L1.mEnums.mList[vIndex], vConsumeValue, ParaStringBuilder, ParaFile, ParaMessage, vIndex );
            vBytes := Copy( vBytes, vVarintConsumedN + vConsumeValueM + 1, Length( vBytes ) - ( vVarintConsumedN + vConsumeValueM ) );
        end;
    end;

    if vNumMessages > 0 then
    begin
        vBytes := Copy( ParaBytes, vPosMessages + 1, Length( ParaBytes ) - vPosMessages );
        for vIndex := Low( ParaMessage.L1.mMessages.mList ) to High( ParaMessage.L1.mMessages.mList ) do
        begin
            vVarintConsumedN := TProtowire.ConsumeVarint( vBytes, vTagNumber, vWireType, vConsumeTagN );
            vConsumeValue := TProtowire.ConsumeBytes( Copy( vBytes, vVarintConsumedN + 1, Length( vBytes ) - vVarintConsumedN ), vConsumeValueM );
            UnmarshalMessageSeed( ParaMessage.L1.mMessages.mList[vIndex], vConsumeValue, ParaStringBuilder, ParaFile, ParaMessage, vIndex );
            vBytes := Copy( vBytes, vVarintConsumedN + vConsumeValueM + 1, Length( vBytes ) - ( vVarintConsumedN + vConsumeValueM ) );
        end;
    end;

    if vNumExtensions > 0 then
    begin
        vBytes := Copy( ParaBytes, vPosExtensions + 1, Length( ParaBytes ) - vPosExtensions );
        for vIndex := Low( ParaMessage.L1.mExtensions.mList ) to High( ParaMessage.L1.mExtensions.mList ) do
        begin
            vVarintConsumedN := TProtowire.ConsumeVarint( vBytes, vTagNumber, vWireType, vConsumeTagN );
            vConsumeValue := TProtowire.ConsumeBytes( Copy( vBytes, vVarintConsumedN + 1, Length( vBytes ) - vVarintConsumedN ), vConsumeValueM );
            UnmarshalExtensionSeed( ParaMessage.L1.mExtensions.mList[vIndex], vConsumeValue, ParaStringBuilder, ParaFile, ParaMessage, vIndex );
            vBytes := Copy( vBytes, vVarintConsumedN + vConsumeValueM + 1, Length( vBytes ) - ( vVarintConsumedN + vConsumeValueM ) );
        end;
    end;
end;

// unmarshalSeedOptions is the Delphi equivalent of func (md *Message) unmarshalSeedOptions(...)
procedure UnmarshalMessageSeedOptions( var ParaMessage : TMessage; ParaBytes : TArray<Byte> );
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

// UnmarshalExtensionSeed is the Delphi equivalent of func (xd *Extension) unmarshalSeed(...)
procedure UnmarshalExtensionSeed
(
    var ParaExtension : TExtension;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
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
    ParaExtension.L0.mParentFile := ParaFile;
    ParaExtension.L0.mParent := ParaParentDescriptor;
    ParaExtension.L0.mIndex := ParaIndex;

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
                        ParaExtension.L1.mNumber := TFieldNumber( vVarint );
                    end;

                    ConstFieldDescriptorProto_Label_field_number :
                    begin
                        ParaExtension.L1.mCardinality := TCardinality( vVarint ); // Assuming TCardinality type
                    end;

                    ConstFieldDescriptorProto_Type_field_number :
                    begin
                        ParaExtension.L1.mKind := TKind( vVarint ); // Assuming TKind type
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
                        ParaExtension.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.FullName,
                            vConsumeValue
                        );
                    end;

                    ConstFieldDescriptorProto_Extendee_field_number :
                    begin
                        ParaExtension.L1.mExtendee := TPlaceholderMessage( MakeFullName( ParaStringBuilder, vConsumeValue ) ); // Assuming TPlaceholderMessage type
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

// UnmarshalServiceSeed is the Delphi equivalent of func (sd *Service) unmarshalSeed(...)
procedure UnmarshalServiceSeed
(
    var ParaService : TService;
    ParaBytes : TArray<Byte>;
    ParaStringBuilder : TStrBuilder;
    ParaFile : TFile;
    ParaParentDescriptor : IDescriptor;
    ParaIndex : Integer
);
var
    vBytes : TArray<Byte>;
    vTagNumber : TFieldNumber;
    vWireType : TWireType;
    vConsumeTagN : Integer;
    vConsumeValue : TArray<Byte>;
    vConsumeValueM : Integer;
begin
    ParaService.L0.mParentFile := ParaFile;
    ParaService.L0.mParent := ParaParentDescriptor;
    ParaService.L0.mIndex := ParaIndex;

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
                    ConstServiceDescriptorProto_Name_field_number :
                    begin
                        ParaService.L0.mFullName := AppendFullName
                        (
                            ParaStringBuilder,
                            ParaParentDescriptor.FullName,
                            vConsumeValue
                        );
                    end;
                end;
            end;
        else
            begin
                vConsumeValueM := TProtowire.ConsumeFieldValue( vTagNumber, vWireType, vBytes );
                vBytes := Copy( vBytes, vVarintM + 1, Length( vBytes ) - vVarintM );
            end;
        end;
    end;
end;

// newRawFile is the entry point for raw file descriptor initialization.
function NewRawFile( ParaDb : IBuilder ) : TFile;
var
    vFile : TFile;
    vIndex : Integer;
    vExtension : TExtension;
begin
    // Initialize vFile
    vFile := TFile.Create; // Assuming TFile is a class for complex memory/lifecycle
    try
        vFile.mFileRaw.mBuilder := ParaDb;
    except
        on E: EOutOfMemory do
        begin
            vFile.Free;
            raise Exception.Create( 'Failed to create TFile object: ' + E.Message );
        end;
    end;


    InitDecls
    (
        vFile,
        ParaDb.NumEnums,
        ParaDb.NumMessages,
        ParaDb.NumExtensions,
        ParaDb.NumServices
    );

    UnmarshalSeed( vFile, ParaDb.RawDescriptor );

    // Extended message targets are eagerly resolved since registration
    // needs this information at program init time.
    for vIndex := 0 to High( vFile.mFileRaw.mAllExtensions ) do
    begin
        // Note: TExtension is assumed to be a record, so we read it, modify it, and assign it back.
        vExtension := vFile.mFileRaw.mAllExtensions[vIndex];

        // resolveMessageDependency is assumed to be a function available from another unit in the filedesc package
        vExtension.L1.mExtendee := ResolveMessageDependency
        (
            vFile,
            vExtension.L1.mExtendee,
            ConstListExtTargets, // Assuming ConstListExtTargets is a constant
            vIndex
        );

        vFile.mFileRaw.mAllExtensions[vIndex] := vExtension;
    end;

    CheckDecls( vFile );
    Result := vFile;
end;

initialization
    // Use the initialization section to safely create the pool resources
    InitNameBuilderPool;

finalization
    // Cleanup the pool in the finalization section
    // Assuming Free for TList/TCriticalSection is safe when initialized to nil on failure
    vNameBuilderPoolLock.Free;
    vNameBuilderPool.Free;

end.