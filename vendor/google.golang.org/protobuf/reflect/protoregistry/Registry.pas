{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry.Registry;

interface

uses
	// Standard dependencies for core types
	System.SysUtils,
	System.Generics.Collections,
	// Mapped Go dependencies for types used in public interfaces/declarations
	Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type

{ Forward declarations }
	TFSRegistry = class;
	TTypesRegistry = class;

{ Interface: MessageTypeResolver }
// MessageTypeResolver is an interface for looking up messages.
type
	IMessageTypeResolver = interface
		['{A286F3E6-4554-4B7C-A4D0-2EC294101A39}']

		// FindMessageByName looks up a message by its full name.
		// E.g., "google.protobuf.Any"
		// This returns (nil, NotFound) if not found.
		function FindMessageByName
		(
			ParaMessage : TFullName
		) : TMessageType;

		// FindMessageByURL looks up a message by a URL identifier.
		// See documentation on google.protobuf.Any.type_url for the URL format.
		// This returns (nil, NotFound) if not found.
		function FindMessageByURL
		(
			ParaURL : string
		) : TMessageType;
	end;

{ Interface: ExtensionTypeResolver }
// ExtensionTypeResolver is an interface for looking up extensions.
type
	IExtensionTypeResolver = interface
		['{AE23D002-9907-4C04-8E1E-2B6005886F45}']

		// FindExtensionByName looks up a extension field by the field's full name.
		// Note that this is the full name of the field as determined by
		// where the extension is declared and is unrelated to the full name of the
		// message being extended.
		// This returns (nil, NotFound) if not found.
		function FindExtensionByName
		(
			ParaField : TFullName
		) : TExtensionType;

		// FindExtensionByNumber looks up a extension field by the field number
		// within some parent message, identified by full name.
		// This returns (nil, NotFound) if not found.
		function FindExtensionByNumber
		(
			ParaMessage : TFullName;
			ParaField : TFieldNumber
		) : TExtensionType;
	end;

{ Type: TNameSuffix }
type
	TNameSuffix = type string;

{ TPackageDescriptor }
type
	TPackageDescriptor = class(TObject)
	private
		// files []protoreflect.FileDescriptor
		mFiles : TList<TFileDescriptor>;
	public
		constructor Create;
		destructor Destroy; override;
		property Files : TList<TFileDescriptor> read mFiles;
	end;

{ Class: TFSRegistry }
// Files is a registry for looking up or iterating over files and the
// descriptors contained within them.
// The Find and Range methods are safe for concurrent use.
type
	TFSRegistry = class(TObject)
	private
		// The map of descsByName contains:
		// EnumDescriptor, EnumValueDescriptor, MessageDescriptor,
		// ExtensionDescriptor, ServiceDescriptor, *packageDescriptor
		mDescsByName : TDictionary<TFullName, TObject>;

		// filesByPath map[string][]protoreflect.FileDescriptor
		mFilesByPath : TDictionary<string, TList<TFileDescriptor>>;

		// numFiles int
		mNumFiles : Integer;

		procedure checkGenProtoConflict
		(
			ParaPath : string
		);

	public
		constructor Create;
		destructor Destroy; override;

		// RegisterFile registers the provided file descriptor.
		function RegisterFile
		(
			ParaFile : TFileDescriptor
		) : TErrorInterface;

		// FindDescriptorByName looks up a descriptor by the full name.
		// This returns (nil, NotFound) if not found.
		function FindDescriptorByName
		(
			ParaName : TFullName
		) : TDescriptor;

		// FindFileByPath looks up a file by the path.
		// This returns (nil, NotFound) if not found.
		// This returns an error if multiple files have the same path.
		function FindFileByPath
		(
			ParaPath : string
		) : TFileDescriptor;

		// NumFiles reports the number of registered files,
		// including duplicate files with the same name.
		function NumFiles : Integer;

		// RangeFiles iterates over all registered files while f returns true.
		procedure RangeFiles
		(
			ParaFunc : TFunc<TFileDescriptor, Boolean>
		);

		// NumFilesByPackage reports the number of registered files in a proto package.
		function NumFilesByPackage
		(
			ParaName : TFullName
		) : Integer;

		// RangeFilesByPackage iterates over all registered files in a given proto package
		// while f returns true. The iteration order is undefined.
		procedure RangeFilesByPackage
		(
			ParaName : TFullName;
			ParaFunc : TFunc<TFileDescriptor, Boolean>
		);
	end;

{ Class: TTypesRegistry }
// Types is a registry for looking up or iterating over descriptor types.
// The Find and Range methods are safe for concurrent use.
type
	TTypesRegistry = class(TInterfacedObject, IMessageTypeResolver, IExtensionTypeResolver)
	private
		// typesByName map[protoreflect.FullName]interface{}
		mTypesByName : TDictionary<TFullName, TObject>;

		// extensionsByMessage map[protoreflect.FullName]extensionsByNumber
		mExtensionsByMessage : TDictionary<TFullName, TDictionary<TFieldNumber, TExtensionType>>;

		// numEnums      int
		mNumEnums : Integer;
		// numMessages   int
		mNumMessages : Integer;
		// numExtensions int
		mNumExtensions : Integer;

		function register
		(
			ParaKind : string;
			ParaDesc : TDescriptor;
			ParaType : TObject
		) : TErrorInterface;

		function typeName
		(
			ParaType : TObject
		) : string;

	public
		constructor Create;
		destructor Destroy; override;

		// RegisterMessage registers the provided message type.
		function RegisterMessage
		(
			ParaMessageType : TMessageType
		) : TErrorInterface;

		// RegisterEnum registers the provided enum type.
		function RegisterEnum
		(
			ParaEnumType : TEnumType
		) : TErrorInterface;

		// RegisterExtension registers the provided extension type.
		function RegisterExtension
		(
			ParaExtensionType : TExtensionType
		) : TErrorInterface;

		// IMessageTypeResolver interface
		function FindMessageByName
		(
			ParaMessage : TFullName
		) : TMessageType;
		function FindMessageByURL
		(
			ParaURL : string
		) : TMessageType;

		// IExtensionTypeResolver interface
		function FindExtensionByName
		(
			ParaField : TFullName
		) : TExtensionType;
		function FindExtensionByNumber
		(
			ParaMessage : TFullName;
			ParaField : TFieldNumber
		) : TExtensionType;

		// NumEnums reports the number of registered enums.
		function NumEnums : Integer;

		// RangeEnums iterates over all registered enums while f returns true.
		procedure RangeEnums
		(
			ParaFunc : TFunc<TEnumType, Boolean>
		);

		// NumMessages reports the number of registered messages.
		function NumMessages : Integer;

		// RangeMessages iterates over all registered messages while f returns true.
		procedure RangeMessages
		(
			ParaFunc : TFunc<TMessageType, Boolean>
		);

		// NumExtensions reports the number of registered extensions.
		function NumExtensions : Integer;

		// RangeExtensions iterates over all registered extensions while f returns true.
		procedure RangeExtensions
		(
			ParaFunc : TFunc<TExtensionType, Boolean>
		);

		// NumExtensionsByMessage reports the number of registered extensions for
		// a given message type.
		function NumExtensionsByMessage
		(
			ParaMessage : TFullName
		) : Integer;

		// RangeExtensionsByMessage iterates over all registered extensions filtered
		// by a given message type while f returns true.
		procedure RangeExtensionsByMessage
		(
			ParaMessage : TFullName;
			ParaFunc : TFunc<TExtensionType, Boolean>
		);
	end;

// GlobalFiles is a global registry of file descriptors.
var
	GlobalFiles : TFSRegistry;

// GlobalTypes is the registry used by default for type lookups
// unless a local registry is provided by the user.
var
	GlobalTypes : TTypesRegistry;

// NotFound is a sentinel error value to indicate that the type was not found.
var
	NotFound : TErrorInterface;

implementation

uses
	System.Types,
	System.Rtti,
	System.IOUtils,
	System.SyncObjs, // For TSimpleRWMutex
	Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
	Vendor.Google.Golang.Org.Protobuf.Internal.Flags,
	Vendor.Google.Golang.Org.Protobuf.Internal.Encoding.Messageset;

// Global mutex for synchronized access to GlobalFiles and GlobalTypes
var
	globalMutex : TSimpleRWMutex;

// conflictPolicy configures the policy for handling registration conflicts.
const
	ConstConflictPolicyDefault = 'panic'; // "panic" | "warn" | "ignore"

// ----------------------------------------------------------------------------
// Private helper functions (Go unexported)
// ----------------------------------------------------------------------------

// PopNameSuffix implements the Go pointer method for nameSuffix
// Go: func (s *nameSuffix) Pop() (name protoreflect.Name)
function PopNameSuffix
(
	var ParaNameSuffix : TNameSuffix
) : TName;
var
	vIndex : Integer;
begin
	vIndex := System.SysUtils.Pos( '.', ParaNameSuffix );

	if vIndex > 0 then
	begin
		Result := TName( Copy( ParaNameSuffix, 1, vIndex - 1 ) );
		ParaNameSuffix := TNameSuffix( Copy( ParaNameSuffix, vIndex + 1, MaxInt ) );
	end else
	begin
		Result := TName( ParaNameSuffix );
		ParaNameSuffix := '';
	end;
end;

// rangeTopLevelDescriptors iterates over all top-level descriptors in a file
// which will be directly entered into the registry.
// Go: func rangeTopLevelDescriptors(fd protoreflect.FileDescriptor, f func(protoreflect.Descriptor))
procedure rangeTopLevelDescriptors
(
	ParaFileDescriptor : TFileDescriptor;
	ParaFunc : TFunc<TDescriptor, Boolean>
);
var
	vEnumDescriptors : TEnumDescriptorList;
	vMessageDescriptors : TMessageDescriptorList;
	vExtensionDescriptors : TExtensionDescriptorList;
	vServiceDescriptors : TServiceDescriptorList;
	vValueDescriptors : TEnumValueDescriptorList;
	vIndex : Integer;
	vInnerIndex : Integer;
	vEnumDescriptor : TEnumDescriptor;
begin
	vEnumDescriptors := ParaFileDescriptor.Enums;
	vIndex := vEnumDescriptors.Len - 1;

	while vIndex >= 0 do
	begin
		vEnumDescriptor := vEnumDescriptors.Get( vIndex );
		if not ParaFunc( vEnumDescriptor ) then
		begin
			Exit;
		end;

		vValueDescriptors := vEnumDescriptor.Values;
		vInnerIndex := vValueDescriptors.Len - 1;

		while vInnerIndex >= 0 do
		begin
			if not ParaFunc( vValueDescriptors.Get( vInnerIndex ) ) then
			begin
				Exit;
			end;
			Dec( vInnerIndex );
		end;

		Dec( vIndex );
	end;

	vMessageDescriptors := ParaFileDescriptor.Messages;
	vIndex := vMessageDescriptors.Len - 1;

	while vIndex >= 0 do
	begin
		if not ParaFunc( vMessageDescriptors.Get( vIndex ) ) then
		begin
			Exit;
		end;
		Dec( vIndex );
	end;

	vExtensionDescriptors := ParaFileDescriptor.Extensions;
	vIndex := vExtensionDescriptors.Len - 1;

	while vIndex >= 0 do
	begin
		if not ParaFunc( vExtensionDescriptors.Get( vIndex ) ) then
		begin
			Exit;
		end;
		Dec( vIndex );
	end;

	vServiceDescriptors := ParaFileDescriptor.Services;
	vIndex := vServiceDescriptors.Len - 1;

	while vIndex >= 0 do
	begin
		if not ParaFunc( vServiceDescriptors.Get( vIndex ) ) then
		begin
			Exit;
		end;
		Dec( vIndex );
	end;
end;

// goPackage is a helper function to get the Go package path of a type.
// Go: func goPackage(v interface{}) string
function goPackage( ParaValue : TObject ) : string;
var
	vDescriptor : TDescriptor;
	vGoPackagePathable : IGoPackagePath;
begin
	Result := '';
	vDescriptor := nil;

	// Use RTTI to check interface support, assuming the protoreflect types are objects implementing TDescriptor
	if ParaValue is TEnumType then
	begin
		vDescriptor := TEnumType( ParaValue ).Descriptor;
	end else if ParaValue is TMessageType then
	begin
		vDescriptor := TMessageType( ParaValue ).Descriptor;
	end else if ParaValue is TExtensionType then
	begin
		vDescriptor := TExtensionType( ParaValue ).TypeDescriptor;
	end else if ParaValue is TDescriptor then
	begin
		vDescriptor := ParaValue as TDescriptor;
	end;

	if Assigned( vDescriptor ) then
	begin
		vDescriptor := vDescriptor.ParentFile;
	end;

	// Check if the file descriptor implements IGoPackagePath
	if Assigned( vDescriptor ) and Supports( vDescriptor, IGoPackagePath, vGoPackagePathable ) then
	begin
		Result := vGoPackagePathable.GoPackagePath;
	end;
end;

// amendErrorWithCaller appends Go package information to an error for conflict reporting.
// Go: func amendErrorWithCaller(err error, prev, curr interface{}) error
function amendErrorWithCaller
(
	ParaError : TErrorInterface;
	ParaPrevType : TObject;
	ParaCurrType : TObject
) : TErrorInterface;
var
	vPrevPkg : string;
	vCurrPkg : string;
begin
	vPrevPkg := goPackage( ParaPrevType );
	vCurrPkg := goPackage( ParaCurrType );

	if ( vPrevPkg = '' ) or ( vCurrPkg = '' ) or ( vPrevPkg = vCurrPkg ) then
	begin
		Result := ParaError;
		Exit;
	end;

	// errors.New("%s\n\tpreviously from: %q\n\tcurrently from:  %q", err, prevPkg, currPkg)
	// Using TErrors.New and TErrorInterface.Error to get the string content
	Result := TErrors.New( '%s' + LineEnding + #9 +
		'previously from: %q' + LineEnding + #9 +
		'currently from:  %q', 
		[ ParaError.Error, vPrevPkg, vCurrPkg ] );
end;

// ignoreConflict reports whether to ignore a registration conflict
// Go: var ignoreConflict = func(d protoreflect.Descriptor, err error) bool
function ignoreConflict
(
	ParaDescriptor : TDescriptor;
	ParaError : TErrorInterface
) : Boolean;
const
	ConstEnv = 'GOLANG_PROTOBUF_REGISTRATION_CONFLICT';
	ConstFAQ = 'https://developers.google.com/protocol-buffers/docs/reference/go/faq#namespace-conflict';
var
	vPolicy : string;
	vEnvValue : string;
begin
	Result := False;
	vPolicy := ConstConflictPolicyDefault;
	vEnvValue := GetEnvironmentVariable( ConstEnv );

	if vEnvValue <> '' then
	begin
		vPolicy := vEnvValue;
	end;

	vPolicy := LowerCase( vPolicy );

	case vPolicy of
		'panic' :
		begin
			// panic(fmt.Sprintf("%v\nSee %v\n", err, faq))
			raise Exception.Create( Format( '%s' + LineEnding + 'See %s', [ ParaError.Error, ConstFAQ ] ) );
		end;

		'warn' :
		begin
			// fmt.Fprintf(os.Stderr, "WARNING: %v\nSee %v\n\n", err, faq)
			// Using System.ErrorStream for os.Stderr equivalent
			System.ErrorStream.Write( TEncoding.UTF8.GetBytes(
				Format( 'WARNING: %s' + LineEnding + 'See %s' + LineEnding + LineEnding, 
					[ ParaError.Error, ConstFAQ ] ) ), 0, TEncoding.UTF8.GetByteCount( Format( 'WARNING: %s' + LineEnding + 'See %s' + LineEnding + LineEnding, 
					[ ParaError.Error, ConstFAQ ] ) ) );
			System.ErrorStream.Flush;
			Result := True;
		end;

		'ignore' :
		begin
			Result := True;
		end;
	else
		begin
			// panic("invalid " + env + " value: " + os.Getenv(env))
			raise Exception.Create( 'invalid ' + ConstEnv + ' value: ' + vEnvValue );
		end;
	end;
end;

// findDescriptorInMessage
// Go: func findDescriptorInMessage(md protoreflect.MessageDescriptor, suffix nameSuffix) protoreflect.Descriptor
function findDescriptorInMessage
(
	ParaMessageDesc : TMessageDescriptor;
	var ParaSuffix : TNameSuffix
) : TDescriptor;
var
	vName : TName;
	vMessageDesc : TMessageDescriptor;
	vIndex : Integer;
	vEnumDesc : TEnumDescriptor;
begin
	vName := PopNameSuffix( ParaSuffix );
	Result := nil;

	if ParaSuffix = '' then
	begin
		// Check top-level message members
		if Assigned( ParaMessageDesc.Enums.ByName( vName ) ) then
		begin
			Result := ParaMessageDesc.Enums.ByName( vName );
			Exit;
		end;

		// Check enum values
		vIndex := ParaMessageDesc.Enums.Len - 1;
		while vIndex >= 0 do
		begin
			vEnumDesc := ParaMessageDesc.Enums.Get( vIndex );
			if Assigned( vEnumDesc.Values.ByName( vName ) ) then
			begin
				Result := vEnumDesc.Values.ByName( vName );
				Exit;
			end;
			Dec( vIndex );
		end;

		if Assigned( ParaMessageDesc.Extensions.ByName( vName ) ) then
		begin
			Result := ParaMessageDesc.Extensions.ByName( vName );
			Exit;
		end;

		if Assigned( ParaMessageDesc.Fields.ByName( vName ) ) then
		begin
			Result := ParaMessageDesc.Fields.ByName( vName );
			Exit;
		end;

		if Assigned( ParaMessageDesc.Oneofs.ByName( vName ) ) then
		begin
			Result := ParaMessageDesc.Oneofs.ByName( vName );
			Exit;
		end;
	end;

	// Check nested messages
	vMessageDesc := ParaMessageDesc.Messages.ByName( vName );
	if Assigned( vMessageDesc ) then
	begin
		if ParaSuffix = '' then
		begin
			Result := vMessageDesc;
			Exit;
		end;
		Result := findDescriptorInMessage( vMessageDesc, ParaSuffix );
		Exit;
	end;
end;


// ----------------------------------------------------------------------------
// TPackageDescriptor
// ----------------------------------------------------------------------------

constructor TPackageDescriptor.Create;
begin
	inherited Create;
	mFiles := nil;
	try
		mFiles := TList<TFileDescriptor>.Create;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Failed to create TList<TFileDescriptor> for TPackageDescriptor: ' + E.Message );
		end;
	end;
end;

destructor TPackageDescriptor.Destroy;
begin
	mFiles.Free;
	inherited Destroy;
end;

// ----------------------------------------------------------------------------
// TFSRegistry (Files)
// ----------------------------------------------------------------------------

constructor TFSRegistry.Create;
begin
	inherited Create;
	mDescsByName := nil;
	mFilesByPath := nil;
	mNumFiles := 0;

	try
		mDescsByName := TDictionary<TFullName, TObject>.Create;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Failed to create TDictionary<TFullName, TObject> for mDescsByName: ' + E.Message );
		end;
	end;

	try
		mFilesByPath := TDictionary<string, TList<TFileDescriptor>>.Create;
	except
		on E: EOutOfMemory do
		begin
			mDescsByName.Free;
			raise Exception.Create( 'Failed to create TDictionary<string, TList<TFileDescriptor>> for mFilesByPath: ' + E.Message );
		end;
	end;
end;

destructor TFSRegistry.Destroy;
var
	vObject : TObject;
	vFileList : TList<TFileDescriptor>;
begin
	// mDescsByName Cleanup: Free TPackageDescriptor objects
	for vObject in mDescsByName.Values do
	begin
		if vObject is TPackageDescriptor then
		begin
			vObject.Free;
		end;
	end;
	mDescsByName.Free;

	// mFilesByPath Cleanup: Free TList<TFileDescriptor> lists
	for vFileList in mFilesByPath.Values do
	begin
		vFileList.Free;
	end;
	mFilesByPath.Free;

	inherited Destroy;
end;

// checkGenProtoConflict handles a specific migration panic/warning.
// Go: func (r *Files) checkGenProtoConflict(path string)
procedure TFSRegistry.checkGenProtoConflict( ParaPath : string );
const
	ConstPrevModule = 'google.golang.org/genproto';
	ConstPrevVersion = 'cb27e3aa (May 26th, 2020)';
var
	vPrevPath : string;
	vPkgName : string;
	vCurrPath : string;
begin
	if Self <> GlobalFiles then
	begin
		Exit;
	end;

	vPrevPath := '';
	case ParaPath of
		'google/protobuf/field_mask.proto' :
		begin
			vPrevPath := ConstPrevModule + '/protobuf/field_mask';
		end;

		'google/protobuf/api.proto' :
		begin
			vPrevPath := ConstPrevModule + '/protobuf/api';
		end;

		'google/protobuf/type.proto' :
		begin
			vPrevPath := ConstPrevModule + '/protobuf/ptype';
		end;

		'google/protobuf/source_context.proto' :
		begin
			vPrevPath := ConstPrevModule + '/protobuf/source_context';
		end;
	else
		begin
			Exit;
		end;
	end;

	vPkgName := Copy( ParaPath, Length( 'google/protobuf/' ) + 1, MaxInt );
	vPkgName := Copy( vPkgName, 1, Length( vPkgName ) - Length( '.proto' ) );
	vPkgName := StringReplace( vPkgName, '_', '', [ rfReplaceAll ] ) + 'pb';
	vCurrPath := 'google.golang.org/protobuf/types/known/' + vPkgName;

	// panic(fmt.Sprintf("...\n"))
	raise Exception.Create( Format( '' +
		'duplicate registration of %q' + LineEnding +
		LineEnding +
		'The generated definition for this file has moved:' + LineEnding +
		#9 + 'from: %q' + LineEnding +
		#9 + 'to:   %q' + LineEnding +
		'A dependency on the %q module must' + LineEnding +
		'be at version %s or higher.' + LineEnding +
		LineEnding +
		'Upgrade the dependency by running:' + LineEnding +
		#9 + 'go get -u %s', 
		[ ParaPath, vPrevPath, vCurrPath, ConstPrevModule, ConstPrevVersion, vPrevPath ] ) );
end;

// RegisterFile registers the provided file descriptor.
// Go: func (r *Files) RegisterFile(file protoreflect.FileDescriptor) error
function TFSRegistry.RegisterFile
(
	ParaFile : TFileDescriptor
) : TErrorInterface;
var
	vPath : string;
	vPrevFiles : TList<TFileDescriptor>;
	vName : TFullName;
	vError : TErrorInterface;
	vConflict : Boolean;
	vPrevDesc : TObject;
	vPackageDescriptor : TPackageDescriptor;

	// Local function containing the core registration logic to handle the lock flow cleanly.
	function doRegister : TErrorInterface;
	var
		// Inner variables for local function
		vInnerError : TErrorInterface;
		vInnerPrevDesc : TObject;

		// Local function for iteration over descriptors to check for conflict
		procedure RangeCheckConflict( ParaDescriptor : TDescriptor );
		begin
			if Assigned( vInnerError ) then
			begin
				Exit;
			end;

			if mDescsByName.TryGetValue( ParaDescriptor.FullName, vInnerPrevDesc ) then
			begin
				vConflict := True;
				vInnerError := TErrors.New( 'file %q has a name conflict over %v', [ ParaFile.Path, ParaDescriptor.FullName ] );
				vInnerError := amendErrorWithCaller( vInnerError, vInnerPrevDesc, ParaFile as TObject );

				if ( Self = GlobalFiles ) and ignoreConflict( ParaDescriptor, vInnerError ) then
				begin
					vInnerError := nil;
				end;
			end;
		end;

		// Local function for iteration over descriptors to register
		procedure RangeRegister( ParaDescriptor : TDescriptor );
		begin
			// The Go code uses the interface as the map value, TObject in Delphi.
		mDescsByName.Add( ParaDescriptor.FullName, ParaDescriptor as TObject );
	end;
	begin
		Result := nil;
		vInnerError := nil;
		vPath := ParaFile.Path;

		// Go: if r.descsByName == nil { ... initialization ... }
		if mDescsByName.Count = 0 then
		begin
			// Check for OOM
			try
				mDescsByName.Add( TFullName( '' ), TPackageDescriptor.Create );
			except
				on E: EOutOfMemory do
				begin
					raise Exception.Create( 'OOM in RegisterFile when initializing registry: ' + E.Message );
				end;
			end;
		end;

		if mFilesByPath.TryGetValue( vPath, vPrevFiles ) and ( vPrevFiles.Count > 0 ) then
		begin
			checkGenProtoConflict( vPath );

			vInnerError := TErrors.New( 'file %q is already registered', [ ParaFile.Path ] );
			vInnerError := amendErrorWithCaller( vInnerError, vPrevFiles.Items[ 0 ] as TObject, ParaFile as TObject );

			if not ( ( Self = GlobalFiles ) and ignoreConflict( ParaFile as TDescriptor, vInnerError ) ) then
			begin
				Result := vInnerError;
				Exit;
			end;
		end;

		// Check for package name conflicts
		vName := ParaFile.Package;

		while vName <> '' do
		begin
			if mDescsByName.TryGetValue( vName, vPrevDesc ) then
			begin
				if not ( vPrevDesc is TPackageDescriptor ) then
				begin
					vInnerError := TErrors.New( 'file %q has a package name conflict over %v', [ ParaFile.Path, vName ] );
					vInnerError := amendErrorWithCaller( vInnerError, vPrevDesc, ParaFile as TObject );

					if ( Self = GlobalFiles ) and ignoreConflict( ParaFile as TDescriptor, vInnerError ) then
					begin
						vInnerError := nil;
					end;

					if Assigned( vInnerError ) then
					begin
						Result := vInnerError;
						Exit;
					end;
				end;
			end;
			vName := vName.Parent;
		end;

		// Check for name conflicts in top-level descriptors
		vConflict := False;
		rangeTopLevelDescriptors( ParaFile,
			function( ParaDescriptor : TDescriptor ) : Boolean
			begin
				RangeCheckConflict( ParaDescriptor );

				if Assigned( vInnerError ) then
				begin
					Result := False;
				end else
				begin
					Result := True;
				end;
			end
		);

		if vConflict and Assigned( vInnerError ) then
		begin
			Result := vInnerError;
			Exit;
		end;

		// Register package names
	vName := ParaFile.Package;
	while vName <> '' do
	begin
		if not mDescsByName.ContainsKey( vName ) then
		begin
			try
				mDescsByName.Add( vName, TPackageDescriptor.Create );
			except
				on E: EOutOfMemory do
				begin
					raise Exception.Create( 'OOM in RegisterFile when creating package descriptor: ' + E.Message );
				end;
			end;
		end;
		vName := vName.Parent;
	end;

		// Register file to package and descriptors to registry
		mDescsByName.TryGetValue( ParaFile.Package, vPackageDescriptor );
	if not Assigned( vPackageDescriptor ) then
	begin
		// Fallback to default package if a package descriptor was not created
		if mDescsByName.TryGetValue( TFullName( '' ), vPackageDescriptor ) and ( vPackageDescriptor is TPackageDescriptor ) then
		begin
			// OK
		end else
		begin
			// Should not happen, but if it does, panic
			raise Exception.Create( 'Internal error: Could not find package descriptor for ' + ParaFile.Package );
		end;
	end;

		( vPackageDescriptor as TPackageDescriptor ).mFiles.Add( ParaFile );

	rangeTopLevelDescriptors( ParaFile,
		function( ParaDescriptor : TDescriptor ) : Boolean
		begin
			RangeRegister( ParaDescriptor );
			Result := True;
		end
	);

		// Register file to path
	if not mFilesByPath.TryGetValue( vPath, vPrevFiles ) then
	begin
		vPrevFiles := nil;
		try
			vPrevFiles := TList<TFileDescriptor>.Create;
		except
			on E: EOutOfMemory do
			begin
				raise Exception.Create( 'OOM in RegisterFile when creating file list: ' + E.Message );
			end;
		end;
		mFilesByPath.Add( vPath, vPrevFiles );
	end;

		vPrevFiles.Add( ParaFile );

		Inc( mNumFiles );
	end; // end of doRegister

begin
	if Self = GlobalFiles then
	begin
		globalMutex.Lock;
		try
			Result := doRegister;
		finally
			globalMutex.Unlock;
		end;
	end else
	begin
		Result := doRegister;
	end;
end;

// FindDescriptorByName
// Go: func (r *Files) FindDescriptorByName(name protoreflect.FullName) (protoreflect.Descriptor, error)
function TFSRegistry.FindDescriptorByName
(
	ParaName : TFullName
) : TDescriptor;
var
	vPrefix : TFullName;
	vSuffix : TNameSuffix;
	vDescObject : TObject;
	vDesc : TDescriptor;
	vServiceDesc : TServiceDescriptor;
	vMethodDesc : TMethodDescriptor;
	vPopName : TName;
	vCurrentSuffix : TNameSuffix; // A mutable copy of suffix to be passed to functions
begin
	Result := nil;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalFiles then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	vPrefix := ParaName;
	vSuffix := TNameSuffix( '' );

	while vPrefix <> '' do
	begin
		if mDescsByName.TryGetValue( vPrefix, vDescObject ) then
		begin
			vDesc := nil;
			vServiceDesc := nil;

			if vDescObject is TEnumDescriptor then
			begin
				vDesc := vDescObject as TEnumDescriptor;
			end else if vDescObject is TEnumValueDescriptor then
			begin
				vDesc := vDescObject as TEnumValueDescriptor;
			end else if vDescObject is TMessageDescriptor then
			begin
				vDesc := vDescObject as TMessageDescriptor;
				if vDesc.FullName = ParaName then
				begin
					Result := vDesc;
					Exit;
				end;
				// Check nested descriptors
			vCurrentSuffix := TNameSuffix( Copy( ParaName, Length( vPrefix ) + 2, MaxInt ) ); // +2 for '.'
			vDesc := findDescriptorInMessage( vDescObject as TMessageDescriptor, vCurrentSuffix );
			if Assigned( vDesc ) and ( vDesc.FullName = ParaName ) then
			begin
				Result := vDesc;
				Exit;
			end;
		end else if vDescObject is TExtensionDescriptor then
			begin
				vDesc := vDescObject as TExtensionDescriptor;
			end else if vDescObject is TServiceDescriptor then
			begin
				vServiceDesc := vDescObject as TServiceDescriptor;
				if vServiceDesc.FullName = ParaName then
				begin
					Result := vServiceDesc;
					Exit;
				end;

				// Check methods
			vCurrentSuffix := TNameSuffix( Copy( ParaName, Length( vPrefix ) + 2, MaxInt ) ); // +2 for '.'
			vPopName := PopNameSuffix( vCurrentSuffix );
			vMethodDesc := vServiceDesc.Methods.ByName( vPopName );
			if Assigned( vMethodDesc ) and ( vMethodDesc.FullName = ParaName ) then
			begin
				Result := vMethodDesc;
				Exit;
			end;
		end else if vDescObject is TPackageDescriptor then
			begin
				// Ignore package descriptors and continue to the next prefix parent.
			end;

			// Final check for descriptors that are not TMessageDescriptor or TServiceDescriptor
			if Assigned( vDesc ) and ( vDesc.FullName = ParaName ) then
			begin
				Result := vDesc;
				Exit;
			end;

			// If we found a non-package object but couldn't resolve the full name, we stop.
			if not ( vDescObject is TPackageDescriptor ) then
			begin
				Exit; // Returns nil (NotFound implied)
			end;
		end;

		vPrefix := vPrefix.Parent;
	end;
	// Loop finished, Result is nil (NotFound implied)
end;

// FindFileByPath
// Go: func (r *Files) FindFileByPath(path string) (protoreflect.FileDescriptor, error)
function TFSRegistry.FindFileByPath
(
	ParaPath : string
) : TFileDescriptor;
var
	vFileDescriptors : TList<TFileDescriptor>;
begin
	Result := nil;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalFiles then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mFilesByPath.TryGetValue( ParaPath, vFileDescriptors ) then
	begin
		case vFileDescriptors.Count of
			0:
			begin
				// Go: return nil, NotFound (Result is nil)
			end;
			1:
			begin
				Result := vFileDescriptors.Items[ 0 ];
			end;
			else
			begin
				// Go: return nil, errors.New("multiple files named %q", path)
			raise EInternalError.Create( Format( 'Multiple files named %q', [ ParaPath ] ) );
			end;
		end;
	end;
	// If not found, Result is nil.
end;

// NumFiles
function TFSRegistry.NumFiles : Integer;
begin
	if not Assigned( Self ) then
	begin
		Result := 0;
		Exit;
	end;

	if Self = GlobalFiles then
	begin
		globalMutex.RLock;
		try
			Result := mNumFiles;
		finally
			globalMutex.RUnlock;
		end;
	end else
	begin
		Result := mNumFiles;
	end;
end;

// RangeFiles
procedure TFSRegistry.RangeFiles
(
	ParaFunc : TFunc<TFileDescriptor, Boolean>
);
var
	vFileList : TList<TFileDescriptor>;
	vFileDesc : TFileDescriptor;
begin
	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalFiles then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	for vFileList in mFilesByPath.Values do
	begin
		for vFileDesc in vFileList do
		begin
			if not ParaFunc( vFileDesc ) then
			begin
				Exit;
			end;
		end;
	end;
end;

// NumFilesByPackage
function TFSRegistry.NumFilesByPackage
(
	ParaName : TFullName
) : Integer;
var
	vDescObject : TObject;
	vPackageDescriptor : TPackageDescriptor;
begin
	Result := 0;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalFiles then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mDescsByName.TryGetValue( ParaName, vDescObject ) then
	begin
		if vDescObject is TPackageDescriptor then
		begin
			vPackageDescriptor := vDescObject as TPackageDescriptor;
			Result := vPackageDescriptor.mFiles.Count;
		end;
	end;
end;

// RangeFilesByPackage
procedure TFSRegistry.RangeFilesByPackage
(
	ParaName : TFullName;
	ParaFunc : TFunc<TFileDescriptor, Boolean>
);
var
	vDescObject : TObject;
	vPackageDescriptor : TPackageDescriptor;
	vFileDesc : TFileDescriptor;
begin
	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalFiles then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mDescsByName.TryGetValue( ParaName, vDescObject ) then
	begin
		if vDescObject is TPackageDescriptor then
		begin
			vPackageDescriptor := vDescObject as TPackageDescriptor;
			for vFileDesc in vPackageDescriptor.mFiles do
			begin
				if not ParaFunc( vFileDesc ) then
				begin
					Exit;
				end;
			end;
		end;
	end;
end;

// ----------------------------------------------------------------------------
// TTypesRegistry (Types)
// ----------------------------------------------------------------------------

// Helper function typeName
// Go: func typeName(t interface{}) string
function TTypesRegistry.typeName
(
	ParaType : TObject
) : string;
begin
	if ParaType is TEnumType then
	begin
		Result := 'enum';
	end else if ParaType is TMessageType then
	begin
		Result := 'message';
	end else if ParaType is TExtensionType then
	begin
		Result := 'extension';
	end else
	begin
		Result := Format( '%s', [ ParaType.ClassName ] ); // Using class name as fallback for Go's %T
	end;
end;

// Helper function register
// Go: func (r *Types) register(kind string, desc protoreflect.Descriptor, typ interface{}) error
function TTypesRegistry.register
(
	ParaKind : string;
	ParaDesc : TDescriptor;
	ParaType : TObject
) : TErrorInterface;
var
	vName : TFullName;
	vPrev : TObject;
	vError : TErrorInterface;
begin
	Result := nil;

	vName := ParaDesc.FullName;
	if mTypesByName.TryGetValue( vName, vPrev ) then
	begin
		vError := TErrors.New( '%v %v is already registered', [ ParaKind, vName ] );
		vError := amendErrorWithCaller( vError, vPrev, ParaType );

		if not ( ( Self = GlobalTypes ) and ignoreConflict( ParaDesc, vError ) ) then
		begin
			Result := vError;
			Exit;
		end;
	end;

	// Go: if r.typesByName == nil { r.typesByName = make(typesByName) }
	// We handle this in the constructor, but if it was cleared for some reason:
	if mTypesByName.Count = 0 then
	begin
		try
			mTypesByName := TDictionary<TFullName, TObject>.Create;
		except
			on E: EOutOfMemory do
			begin
				raise Exception.Create( 'OOM in register when creating typesByName dictionary: ' + E.Message );
			end;
		end;
	end;

	mTypesByName.Add( vName, ParaType );
end;

constructor TTypesRegistry.Create;
begin
	inherited Create;
	mNumEnums := 0;
	mNumMessages := 0;
	mNumExtensions := 0;

	mTypesByName := nil;
	mExtensionsByMessage := nil;

	try
		mTypesByName := TDictionary<TFullName, TObject>.Create;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Failed to create mTypesByName: ' + E.Message );
		end;
	end;

	try
		mExtensionsByMessage := TDictionary<TFullName, TDictionary<TFieldNumber, TExtensionType>>.Create;
	except
		on E: EOutOfMemory do
		begin
			mTypesByName.Free;
			raise Exception.Create( 'Failed to create mExtensionsByMessage: ' + E.Message );
		end;
	end;
end;

destructor TTypesRegistry.Destroy;
var
	vInnerDict : TDictionary<TFieldNumber, TExtensionType>;
begin
	// The dictionary values are interfaces (TExtensionType), so no explicit Free on elements.
	for vInnerDict in mExtensionsByMessage.Values do
	begin
		vInnerDict.Free;
	end;
	mExtensionsByMessage.Free;
	mTypesByName.Free;
	inherited Destroy;
end;

// RegisterMessage
function TTypesRegistry.RegisterMessage
(
	ParaMessageType : TMessageType
) : TErrorInterface;
var
	vDescriptor : TDescriptor;
	vError : TErrorInterface;
begin
	vDescriptor := ParaMessageType.Descriptor;

	if Self = GlobalTypes then
	begin
		globalMutex.Lock;
		try
			vError := register( 'message', vDescriptor, ParaMessageType as TObject );
			if Assigned( vError ) then
			begin
				Result := vError;
				Exit;
			end;
			Inc( mNumMessages );
		finally
			globalMutex.Unlock;
		end;
	end else
	begin
		vError := register( 'message', vDescriptor, ParaMessageType as TObject );
		if Assigned( vError ) then
		begin
			Result := vError;
			Exit;
		end;
		Inc( mNumMessages );
	end;
	Result := nil;
end;

// RegisterEnum
function TTypesRegistry.RegisterEnum
(
	ParaEnumType : TEnumType
) : TErrorInterface;
var
	vDescriptor : TDescriptor;
	vError : TErrorInterface;
begin
	vDescriptor := ParaEnumType.Descriptor;

	if Self = GlobalTypes then
	begin
		globalMutex.Lock;
		try
			vError := register( 'enum', vDescriptor, ParaEnumType as TObject );
			if Assigned( vError ) then
			begin
				Result := vError;
				Exit;
			end;
			Inc( mNumEnums );
		finally
			globalMutex.Unlock;
		end;
	end else
	begin
		vError := register( 'enum', vDescriptor, ParaEnumType as TObject );
		if Assigned( vError ) then
		begin
			Result := vError;
			Exit;
		end;
		Inc( mNumEnums );
	end;
	Result := nil;
end;

// RegisterExtension
function TTypesRegistry.RegisterExtension
(
	ParaExtensionType : TExtensionType
) : TErrorInterface;
var
	vDescriptor : TExtensionDescriptor;
	vField : TFieldNumber;
	vMessage : TFullName;
	vPrev : TExtensionType;
	vError : TErrorInterface;
	vExtensionsByNumber : TDictionary<TFieldNumber, TExtensionType>;
begin
	Result := nil;
	vDescriptor := ParaExtensionType.TypeDescriptor;
	vField := vDescriptor.Number;
	vMessage := vDescriptor.ContainingMessage.FullName;

	if Self = GlobalTypes then
	begin
		globalMutex.Lock;
		try
			// Check for number conflict first (outside of register)
			if mExtensionsByMessage.TryGetValue( vMessage, vExtensionsByNumber ) then
			begin
				if vExtensionsByNumber.TryGetValue( vField, vPrev ) then
				begin
					vError := TErrors.New( 'extension number %d is already registered on message %v', [ vField, vMessage ] );
					vError := amendErrorWithCaller( vError, vPrev as TObject, ParaExtensionType as TObject );

					if not ( ( Self = GlobalTypes ) and ignoreConflict( vDescriptor, vError ) ) then
					begin
						Result := vError;
						Exit;
					end;
				end;
			end;

			// Register by name
			vError := register( 'extension', vDescriptor, ParaExtensionType as TObject );
			if Assigned( vError ) then
			begin
				Result := vError;
				Exit;
			end;

			// Register by number
			if mExtensionsByMessage.Count = 0 then
			begin
				try
					mExtensionsByMessage := TDictionary<TFullName, TDictionary<TFieldNumber, TExtensionType>>.Create;
				except
					on E: EOutOfMemory do
					begin
						raise Exception.Create( 'OOM in RegisterExtension when creating extensionsByMessage dictionary: ' + E.Message );
					end;
			end;
		end;

			if not mExtensionsByMessage.TryGetValue( vMessage, vExtensionsByNumber ) then
			begin
				vExtensionsByNumber := nil;
				try
					vExtensionsByNumber := TDictionary<TFieldNumber, TExtensionType>.Create;
				except
					on E: EOutOfMemory do
					begin
						raise Exception.Create( 'OOM in RegisterExtension when creating extensionsByNumber dictionary: ' + E.Message );
					end;
			end;
			mExtensionsByMessage.Add( vMessage, vExtensionsByNumber );
		end;

			vExtensionsByNumber.Add( vField, ParaExtensionType );
			Inc( mNumExtensions );
		finally
			globalMutex.Unlock;
		end;
	end else
	begin
		// No lock, repeated logic
		// Check for number conflict first (outside of register)
		if mExtensionsByMessage.TryGetValue( vMessage, vExtensionsByNumber ) then
		begin
			if vExtensionsByNumber.TryGetValue( vField, vPrev ) then
			begin
				vError := TErrors.New( 'extension number %d is already registered on message %v', [ vField, vMessage ] );
				vError := amendErrorWithCaller( vError, vPrev as TObject, ParaExtensionType as TObject );

				if not ( ( Self = GlobalTypes ) and ignoreConflict( vDescriptor, vError ) ) then
				begin
					Result := vError;
					Exit;
				end;
			end;
		end;

		// Register by name
		vError := register( 'extension', vDescriptor, ParaExtensionType as TObject );
		if Assigned( vError ) then
		begin
			Result := vError;
			Exit;
		end;

		// Register by number
		if mExtensionsByMessage.Count = 0 then
		begin
			try
				mExtensionsByMessage := TDictionary<TFullName, TDictionary<TFieldNumber, TExtensionType>>.Create;
			except
				on E: EOutOfMemory do
				begin
					raise Exception.Create( 'OOM in RegisterExtension when creating extensionsByMessage dictionary: ' + E.Message );
				end;
		end;
		end;

		if not mExtensionsByMessage.TryGetValue( vMessage, vExtensionsByNumber ) then
		begin
			vExtensionsByNumber := nil;
			try
				vExtensionsByNumber := TDictionary<TFieldNumber, TExtensionType>.Create;
			except
				on E: EOutOfMemory do
				begin
					raise Exception.Create( 'OOM in RegisterExtension when creating extensionsByNumber dictionary: ' + E.Message );
				end;
		end;
		mExtensionsByMessage.Add( vMessage, vExtensionsByNumber );
	end;

		vExtensionsByNumber.Add( vField, ParaExtensionType );
		Inc( mNumExtensions );
	end;
	Result := nil;
end;

// FindEnumByName
function TTypesRegistry.FindEnumByName
(
	ParaEnum : TFullName
) : TEnumType;
var
	vValue : TObject;
begin
	Result := nil;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mTypesByName.TryGetValue( ParaEnum, vValue ) then
	begin
		if vValue is TEnumType then
		begin
			Result := vValue as TEnumType;
			Exit;
		end;

		// Go: return nil, errors.New("found wrong type: got %v, want enum", typeName(v))
		raise EInternalError.Create( Format( 'Found wrong type: got %s, want enum', [ typeName( vValue ) ] ) );
	end;
	// Go: return nil, NotFound
end;

// FindMessageByName
function TTypesRegistry.FindMessageByName
(
	ParaMessage : TFullName
) : TMessageType;
var
	vValue : TObject;
begin
	Result := nil;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mTypesByName.TryGetValue( ParaMessage, vValue ) then
	begin
		if vValue is TMessageType then
		begin
			Result := vValue as TMessageType;
			Exit;
		end;
		raise EInternalError.Create( Format( 'Found wrong type: got %s, want message', [ typeName( vValue ) ] ) );
	end;
	// Go: return nil, NotFound
end;

// FindMessageByURL
function TTypesRegistry.FindMessageByURL
(
	ParaURL : string
) : TMessageType;
var
	vMessage : TFullName;
	vIndex : Integer;
	vValue : TObject;
begin
	Result := nil;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	vMessage := TFullName( ParaURL );
	vIndex := LastDelimiter( '/', ParaURL );

	if vIndex > 0 then
	begin
		vMessage := TFullName( Copy( ParaURL, vIndex + 1, MaxInt ) );
	end;

	if mTypesByName.TryGetValue( vMessage, vValue ) then
	begin
		if vValue is TMessageType then
		begin
			Result := vValue as TMessageType;
			Exit;
		end;
		raise EInternalError.Create( Format( 'Found wrong type: got %s, want message', [ typeName( vValue ) ] ) );
	end;
	// Go: return nil, NotFound
end;

// FindExtensionByName
function TTypesRegistry.FindExtensionByName
(
	ParaField : TFullName
) : TExtensionType;
var
	vValue : TObject;
	vField : TFullName;
begin
	Result := nil;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mTypesByName.TryGetValue( ParaField, vValue ) then
	begin
		if vValue is TExtensionType then
		begin
			Result := vValue as TExtensionType;
			Exit;
		end;

		// MessageSet extensions logic
		if Flags.ConstProtoLegacy then
		begin
			if vValue is TMessageType then
			begin
				vField := ParaField.Append( Messageset.ConstExtensionName );
				if mTypesByName.TryGetValue( vField, vValue ) and ( vValue is TExtensionType ) then
				begin
					Result := vValue as TExtensionType;
					if Messageset.IsMessageSetExtension( Result.TypeDescriptor ) then
					begin
						Exit;
					end;
				end;
			end;
		end;

		raise EInternalError.Create( Format( 'Found wrong type: got %s, want extension', [ typeName( vValue ) ] ) );
	end;
	// Go: return nil, NotFound
end;

// FindExtensionByNumber
function TTypesRegistry.FindExtensionByNumber
(
	ParaMessage : TFullName;
	ParaField : TFieldNumber
) : TExtensionType;
var
	vExtensionsByNumber : TDictionary<TFieldNumber, TExtensionType>;
begin
	Result := nil;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mExtensionsByMessage.TryGetValue( ParaMessage, vExtensionsByNumber ) then
	begin
		if vExtensionsByNumber.TryGetValue( ParaField, Result ) then
		begin
			Exit;
		end;
	end;
	// Go: return nil, NotFound
end;

// NumEnums
function TTypesRegistry.NumEnums : Integer;
begin
	if not Assigned( Self ) then
	begin
		Result := 0;
		Exit;
	end;
	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			Result := mNumEnums;
		finally
			globalMutex.RUnlock;
		end;
	end else
	begin
		Result := mNumEnums;
	end;
end;

// RangeEnums
procedure TTypesRegistry.RangeEnums
(
	ParaFunc : TFunc<TEnumType, Boolean>
);
var
	vTyp : TObject;
begin
	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	for vTyp in mTypesByName.Values do
	begin
		if vTyp is TEnumType then
		begin
			if not ParaFunc( vTyp as TEnumType ) then
			begin
				Exit;
			end;
		end;
	end;
end;

// NumMessages
function TTypesRegistry.NumMessages : Integer;
begin
	if not Assigned( Self ) then
	begin
		Result := 0;
		Exit;
	end;
	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			Result := mNumMessages;
		finally
			globalMutex.RUnlock;
		end;
	end else
	begin
		Result := mNumMessages;
	end;
end;

// RangeMessages
procedure TTypesRegistry.RangeMessages
(
	ParaFunc : TFunc<TMessageType, Boolean>
);
var
	vTyp : TObject;
begin
	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	for vTyp in mTypesByName.Values do
	begin
		if vTyp is TMessageType then
		begin
			if not ParaFunc( vTyp as TMessageType ) then
			begin
				Exit;
			end;
		end;
	end;
end;

// NumExtensions
function TTypesRegistry.NumExtensions : Integer;
begin
	if not Assigned( Self ) then
	begin
		Result := 0;
		Exit;
	end;
	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			Result := mNumExtensions;
		finally
			globalMutex.RUnlock;
		end;
	end else
	begin
		Result := mNumExtensions;
	end;
end;

// RangeExtensions
procedure TTypesRegistry.RangeExtensions
(
	ParaFunc : TFunc<TExtensionType, Boolean>
);
var
	vTyp : TObject;
begin
	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	for vTyp in mTypesByName.Values do
	begin
		if vTyp is TExtensionType then
		begin
			if not ParaFunc( vTyp as TExtensionType ) then
			begin
				Exit;
			end;
		end;
	end;
end;

// NumExtensionsByMessage
function TTypesRegistry.NumExtensionsByMessage
(
	ParaMessage : TFullName
) : Integer;
var
	vExtensionsByNumber : TDictionary<TFieldNumber, TExtensionType>;
begin
	Result := 0;

	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mExtensionsByMessage.TryGetValue( ParaMessage, vExtensionsByNumber ) then
	begin
		Result := vExtensionsByNumber.Count;
	end;
end;

// RangeExtensionsByMessage
procedure TTypesRegistry.RangeExtensionsByMessage
(
	ParaMessage : TFullName;
	ParaFunc : TFunc<TExtensionType, Boolean>
);
var
	vExtensionsByNumber : TDictionary<TFieldNumber, TExtensionType>;
	vExtensionType : TExtensionType;
begin
	if not Assigned( Self ) then
	begin
		Exit;
	end;

	if Self = GlobalTypes then
	begin
		globalMutex.RLock;
		try
			// Go: defer globalMutex.RUnlock()
		finally
			globalMutex.RUnlock;
		end;
	end;

	if mExtensionsByMessage.TryGetValue( ParaMessage, vExtensionsByNumber ) then
	begin
		for vExtensionType in vExtensionsByNumber.Values do
		begin
			if not ParaFunc( vExtensionType ) then
			begin
				Exit;
			end;
		end;
	end;
end;

initialization
	// Initialize global variables
	globalMutex := nil;
	try
		globalMutex := TSimpleRWMutex.Create;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Failed to create globalMutex: ' + E.Message );
		end;
	end;

	// GlobalFiles is a global registry of file descriptors.
	GlobalFiles := nil;
	try
		GlobalFiles := TFSRegistry.Create;
	except
		on E: EOutOfMemory do
		begin
			globalMutex.Free;
			raise Exception.Create( 'Failed to create GlobalFiles: ' + E.Message );
		end;
	end;

	// GlobalTypes is the registry used by default for type lookups
	// unless a local registry is provided by the user.
	GlobalTypes := nil;
	try
		GlobalTypes := TTypesRegistry.Create;
	except
		on E: EOutOfMemory do
		begin
			GlobalFiles.Free;
			globalMutex.Free;
			raise Exception.Create( 'Failed to create GlobalTypes: ' + E.Message );
		end;
	end;

	// NotFound is a sentinel error value to indicate that the type was not found.
	NotFound := TErrors.New( 'not found' );


finalization
	// Cleanup global variables
	GlobalTypes.Free;
	GlobalFiles.Free;
	globalMutex.Free;
	NotFound := nil; // Release the error interface

end.