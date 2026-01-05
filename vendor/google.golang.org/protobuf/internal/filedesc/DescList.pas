{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc.DescList;

interface

uses
{$IFDEF FPC}
  SysUtils,
  Classes,
  Math;
{$ELSE}
  System.SysUtils,
  System.Classes,
  System.Math;
{$ENDIF}

implementation

uses
{$IFDEF FPC}
  SyncObjs,
  Generics.Collections,
  Protowire,
  Genid,
  Descfmt,
  Errors,
  Protoreflect;
{$ELSE}
  System.SyncObjs,
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Genid,
  Vendor.Google.Golang.Org.Protobuf.Internal.Descfmt,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;
{$ENDIF}

// --- Forward Declarations/Assumptions for Types ---

type
    // Prefixes/Aliases for external types
    TFileImport = record end; // pref.FileImport
    TName = type String; // pref.Name
    TEnumNumber = type Integer; // pref.EnumNumber
    TFieldNumber = type Integer; // pref.FieldNumber
    TFieldDescriptor = interface end; // pref.FieldDescriptor
    TFileDescriptor = interface end; // pref.FileDescriptor
    TDescriptor = interface end; // pref.Descriptor
    TSourceLocation = record end; // pref.SourceLocation
    TSourcePath = TArray<Integer>; // pref.SourcePath (TArray<int32>)

// --- TGoOnce Implementation (Local Redefinition for Self-Contained Unit) ---
type
    TGoOnce = class
    private
        mCriticalSection : TCriticalSection;
        mDone : Boolean;
    public
        constructor Create;
        destructor Destroy; override;
        procedure DoOnce( ParaProc : TProc );
    end;

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

// --- List/Range Structs ---

type
    FileImports = TArray<TFileImport>;

    TFileImportsHelper = record helper for FileImports
        function Len : Integer;
        function Get( ParaIndex : Integer ) : TFileImport;
    end;

    Names = record
        mList : TArray<TName>;
        mOnce : TGoOnce;
        mHas : TDictionary<TName, Integer>;
    end;

    EnumRanges = record
        mList : TArray<TArray<TEnumNumber>>; // [2]pref.EnumNumber
        mOnce : TGoOnce;
        mSorted : TArray<TArray<TEnumNumber>>;
    end;

    enumRange = TArray<TEnumNumber>;

    FieldRanges = record
        mList : TArray<TArray<TFieldNumber>>; // [2]pref.FieldNumber (end exclusive)
        mOnce : TGoOnce;
        mSorted : TArray<TArray<TFieldNumber>>;
    end;

    fieldRange = TArray<TFieldNumber>;

    FieldNumbers = record
        mList : TArray<TFieldNumber>;
        mOnce : TGoOnce;
        mHas : TDictionary<TFieldNumber, Boolean>; // map[pref.FieldNumber]struct{}
    end;

    OneofFields = record
        mList : TArray<TFieldDescriptor>;
        mOnce : TGoOnce;
        mByName : TDictionary<TName, TFieldDescriptor>;
        mByJSON : TDictionary<String, TFieldDescriptor>;
        mByText : TDictionary<String, TFieldDescriptor>;
        mByNum : TDictionary<TFieldNumber, TFieldDescriptor>;
    end;

    SourceLocations = record
        mList : TArray<TSourceLocation>;
        mFile : TFileDescriptor;
        mOnce : TGoOnce;
        mByPath : TDictionary<pathKey, Integer>;
    end;

    pathKey = record
        mArr : TArray<Byte>; // [16]uint8 (first n-1 segments, last is length)
        mStr : String;       // used if path does not fit in mArr
    end;


// --- Helper Implementations ---

{ FileImports }
function TFileImportsHelper.Len: Integer;
begin
    Result := Length(Self);
end;

function TFileImportsHelper.Get(ParaIndex: Integer): TFileImport;
begin
    Result := Self[ParaIndex];
end;

{ Names }
function NamesLen( ParaNames : Names ) : Integer;
begin
    Result := Length( ParaNames.mList );
end;

function NamesGet( ParaNames : Names; ParaIndex : Integer ) : TName;
begin
    Result := ParaNames.mList[ParaIndex];
end;

function NamesLazyInit( var ParaNames : Names ) : ^Names;
var
    vDoFunc : TProc;
    vName : TName;
begin
    // Go's sync.Once protects the map initialization
    vDoFunc := procedure
    var
        vIndex : Integer;
        vCurrentCount : Integer;
    begin
        if Length( ParaNames.mList ) > 0 then
        begin
            try
                ParaNames.mHas := TDictionary<TName, Integer>.Create( Length( ParaNames.mList ) );
            except
                on E: EOutOfMemory do
                begin
                    raise Exception.Create( 'Failed to create dictionary in NamesLazyInit: ' + E.Message );
                end;
            end;

            for vIndex := 0 to High( ParaNames.mList ) do
            begin
                vName := ParaNames.mList[vIndex];
                if ParaNames.mHas.TryGetValue( vName, vCurrentCount ) then
                begin
                    ParaNames.mHas[vName] := vCurrentCount + 1;
                end else
                begin
                    ParaNames.mHas.Add( vName, 1 );
                end;
            end;
        end;
    end;

    ParaNames.mOnce.DoOnce( vDoFunc );
    Result := @ParaNames;
end;

function NamesHas( var ParaNames : Names; ParaName : TName ) : Boolean;
begin
    // Lazily initialize and check for count > 0
    Result := NamesLazyInit( ParaNames )^.mHas.ContainsKey( ParaName );
end;

function NamesCheckValid( var ParaNames : Names ) : Error;
var
    vName : TName;
    vCount : Integer;
begin
    for vName in NamesLazyInit( ParaNames )^.mHas.Keys do
    begin
        vCount := NamesLazyInit( ParaNames )^.mHas[vName];
        if vCount > 1 then
        begin
            Result := TErrors.New( 'duplicate name: %q', [ vName ] );
            Exit;
        end;
    end;
    Result := nil;
end;

{ EnumRanges }
function EnumRangesLen( ParaRanges : EnumRanges ) : Integer;
begin
    Result := Length( ParaRanges.mList );
end;

function EnumRangesGet( ParaRanges : EnumRanges; ParaIndex : Integer ) : TArray<TEnumNumber>;
begin
    Result := ParaRanges.mList[ParaIndex];
end;

function EnumRangesLazyInit( var ParaRanges : EnumRanges ) : ^EnumRanges;
var
    vDoFunc : TProc;
begin
    vDoFunc := procedure
    begin
        // Copy list to sorted array
        ParaRanges.mSorted := Copy( ParaRanges.mList );
        // Sort by start index
        TArray.Sort<TArray<TEnumNumber>>( ParaRanges.mSorted,
            function( const ParaA, ParaB : TArray<TEnumNumber> ) : Integer
            begin
                if ParaA[0] < ParaB[0] then
                    Result := -1
                else if ParaA[0] > ParaB[0] then
                    Result := 1
                else
                    Result := 0;
            end
        );
    end;

    ParaRanges.mOnce.DoOnce( vDoFunc );
    Result := @ParaRanges;
end;

function EnumRangeStart( ParaRange : enumRange ) : TEnumNumber;
begin
    Result := ParaRange[0];
end;

function EnumRangeEnd( ParaRange : enumRange ) : TEnumNumber;
begin
    Result := ParaRange[1];
end;

function EnumRangeToString( ParaRange : enumRange ) : String;
begin
    if EnumRangeStart( ParaRange ) = EnumRangeEnd( ParaRange ) then
    begin
        Result := Format( '%d', [ EnumRangeStart( ParaRange ) ] );
    end else
    begin
        Result := Format( '%d to %d', [ EnumRangeStart( ParaRange ), EnumRangeEnd( ParaRange ) ] );
    end;
end;

function EnumRangesCheckValid( var ParaRanges : EnumRanges ) : Error;
var
    vRP : enumRange;
    vRange : enumRange;
    vIndex : Integer;
begin
    // Assumes EnumRangesLazyInit has been called
    for vIndex := 0 to High( EnumRangesLazyInit( ParaRanges )^.mSorted ) do
    begin
        vRange := EnumRangesLazyInit( ParaRanges )^.mSorted[vIndex];

        if not ( EnumRangeStart( vRange ) <= EnumRangeEnd( vRange ) ) then
        begin
            Result := TErrors.New( 'invalid range: %v', [ EnumRangeToString( vRange ) ] );
            Exit;
        end;

        if vIndex > 0 then
        begin
            if not ( EnumRangeEnd( vRP ) < EnumRangeStart( vRange ) ) then
            begin
                Result := TErrors.New( 'overlapping ranges: %v with %v', [ EnumRangeToString( vRP ), EnumRangeToString( vRange ) ] );
                Exit;
            end;
        end;

        vRP := vRange;
    end;
    Result := nil;
end;

function EnumRangesHas( var ParaRanges : EnumRanges; ParaNumber : TEnumNumber ) : Boolean;
var
    vSorted : TArray<TArray<TEnumNumber>>;
    vLow, vHigh, vMid : Integer;
    vRange : enumRange;
begin
    vSorted := EnumRangesLazyInit( ParaRanges )^.mSorted;
    vLow := Low( vSorted );
    vHigh := High( vSorted );

    // Binary search logic
    while vLow <= vHigh do
    begin
        vMid := vLow + ( vHigh - vLow ) div 2;
        vRange := vSorted[vMid];

        if ParaNumber < EnumRangeStart( vRange ) then
        begin
            vHigh := vMid - 1; // search lower
        end else if ParaNumber > EnumRangeEnd( vRange ) then
        begin
            vLow := vMid + 1; // search upper
        end else
        begin
            Result := True;
            Exit;
        end;
    end;
    Result := False;
end;

{ FieldRanges }
function FieldRangesLazyInit( var ParaRanges : FieldRanges ) : ^FieldRanges;
var
    vDoFunc : TProc;
begin
    vDoFunc := procedure
    begin
        ParaRanges.mSorted := Copy( ParaRanges.mList );
        TArray.Sort<TArray<TFieldNumber>>( ParaRanges.mSorted,
            function( const ParaA, ParaB : TArray<TFieldNumber> ) : Integer
            begin
                if ParaA[0] < ParaB[0] then
                    Result := -1
                else if ParaA[0] > ParaB[0] then
                    Result := 1
                else
                    Result := 0;
            end
        );
    end;

    ParaRanges.mOnce.DoOnce( vDoFunc );
    Result := @ParaRanges;
end;

function FieldRangesLen( ParaRanges : FieldRanges ) : Integer;
begin
    Result := Length( ParaRanges.mList );
end;

function FieldRangesGet( ParaRanges : FieldRanges; ParaIndex : Integer ) : TArray<TFieldNumber>;
begin
    Result := ParaRanges.mList[ParaIndex];
end;

function FieldRangeStart( ParaRange : fieldRange ) : TFieldNumber;
begin
    Result := ParaRange[0]; // inclusive
end;

function FieldRangeEnd( ParaRange : fieldRange ) : TFieldNumber;
begin
    Result := ParaRange[1] - 1; // inclusive (Go's end exclusive logic: r[1] - 1)
end;

function FieldRangeToString( ParaRange : fieldRange ) : String;
begin
    if FieldRangeStart( ParaRange ) = FieldRangeEnd( ParaRange ) then
    begin
        Result := Format( '%d', [ FieldRangeStart( ParaRange ) ] );
    end else
    begin
        Result := Format( '%d to %d', [ FieldRangeStart( ParaRange ), FieldRangeEnd( ParaRange ) ] );
    end;
end;

function IsValidFieldNumber( ParaNumber : TFieldNumber; ParaIsMessageSet : Boolean ) : Boolean;
begin
    // protowire.MinValidNumber <= n && (n <= protowire.MaxValidNumber || isMessageSet)
    Result := ( ConstProtowireMinValidNumber <= ParaNumber ) and
              ( ( ParaNumber <= ConstProtowireMaxValidNumber ) or ParaIsMessageSet );
end;

function FieldRangesCheckValid( var ParaRanges : FieldRanges; ParaIsMessageSet : Boolean ) : Error;
var
    vRP : fieldRange;
    vRange : fieldRange;
    vIndex : Integer;
begin
    for vIndex := 0 to High( FieldRangesLazyInit( ParaRanges )^.mSorted ) do
    begin
        vRange := FieldRangesLazyInit( ParaRanges )^.mSorted[vIndex];

        if not IsValidFieldNumber( FieldRangeStart( vRange ), ParaIsMessageSet ) then
        begin
            Result := TErrors.New( 'invalid field number: %d', [ FieldRangeStart( vRange ) ] );
            Exit;
        end;

        if not IsValidFieldNumber( FieldRangeEnd( vRange ), ParaIsMessageSet ) then
        begin
            Result := TErrors.New( 'invalid field number: %d', [ FieldRangeEnd( vRange ) ] );
            Exit;
        end;

        if not ( FieldRangeStart( vRange ) <= FieldRangeEnd( vRange ) ) then
        begin
            Result := TErrors.New( 'invalid range: %v', [ FieldRangeToString( vRange ) ] );
            Exit;
        end;

        if vIndex > 0 then
        begin
            if not ( FieldRangeEnd( vRP ) < FieldRangeStart( vRange ) ) then
            begin
                Result := TErrors.New( 'overlapping ranges: %v with %v', [ FieldRangeToString( vRP ), FieldRangeToString( vRange ) ] );
                Exit;
            end;
        end;

        vRP := vRange;
    end;
    Result := nil;
end;

function FieldRangesCheckOverlap( var ParaP : FieldRanges; var ParaQ : FieldRanges ) : Error;
var
    vRPS : TArray<TArray<TFieldNumber>>;
    vRQS : TArray<TArray<TFieldNumber>>;
    vPIndex, vQIndex : Integer;
    vRP : fieldRange;
    vRQ : fieldRange;
begin
    vRPS := FieldRangesLazyInit( ParaP )^.mSorted;
    vRQS := FieldRangesLazyInit( ParaQ )^.mSorted;
    vPIndex := 0;
    vQIndex := 0;

    while ( vPIndex < Length( vRPS ) ) and ( vQIndex < Length( vRQS ) ) do
    begin
        vRP := vRPS[vPIndex];
        vRQ := vRQS[vQIndex];

        // !(rp.End() < rq.Start() || rq.End() < rp.Start())
        if not ( ( FieldRangeEnd( vRP ) < FieldRangeStart( vRQ ) ) or ( FieldRangeEnd( vRQ ) < FieldRangeStart( vRP ) ) ) then
        begin
            Result := TErrors.New( 'overlapping ranges: %v with %v', [ FieldRangeToString( vRP ), FieldRangeToString( vRQ ) ] );
            Exit;
        end;

        if FieldRangeStart( vRP ) < FieldRangeStart( vRQ ) then
        begin
            Inc( vPIndex );
        end else
        begin
            Inc( vQIndex );
        end;
    end;
    Result := nil;
end;

function FieldRangesHas( var ParaRanges : FieldRanges; ParaNumber : TFieldNumber ) : Boolean;
var
    vSorted : TArray<TArray<TFieldNumber>>;
    vLow, vHigh, vMid : Integer;
    vRange : fieldRange;
begin
    vSorted := FieldRangesLazyInit( ParaRanges )^.mSorted;
    vLow := Low( vSorted );
    vHigh := High( vSorted );

    // Binary search logic
    while vLow <= vHigh do
    begin
        vMid := vLow + ( vHigh - vLow ) div 2;
        vRange := vSorted[vMid];

        if ParaNumber < FieldRangeStart( vRange ) then
        begin
            vHigh := vMid - 1; // search lower
        end else if ParaNumber > FieldRangeEnd( vRange ) then
        begin
            vLow := vMid + 1; // search upper
        end else
        begin
            Result := True;
            Exit;
        end;
    end;
    Result := False;
end;


{ FieldNumbers }
function FieldNumbersLen( ParaNumbers : FieldNumbers ) : Integer;
begin
    Result := Length( ParaNumbers.mList );
end;

function FieldNumbersGet( ParaNumbers : FieldNumbers; ParaIndex : Integer ) : TFieldNumber;
begin
    Result := ParaNumbers.mList[ParaIndex];
end;

function FieldNumbersHas( var ParaNumbers : FieldNumbers; ParaNumber : TFieldNumber ) : Boolean;
var
    vDoFunc : TProc;
begin
    vDoFunc := procedure
    var
        vIndex : Integer;
    begin
        if Length( ParaNumbers.mList ) > 0 then
        begin
            try
                ParaNumbers.mHas := TDictionary<TFieldNumber, Boolean>.Create( Length( ParaNumbers.mList ) );
            except
                on E: EOutOfMemory do
                begin
                    raise Exception.Create( 'Failed to create dictionary in FieldNumbersHas: ' + E.Message );
                end;
            end;

            for vIndex := 0 to High( ParaNumbers.mList ) do
            begin
                ParaNumbers.mHas.Add( ParaNumbers.mList[vIndex], True );
            end;
        end;
    end;

    ParaNumbers.mOnce.DoOnce( vDoFunc );

    if ParaNumbers.mHas = nil then
    begin
        Result := False;
        Exit;
    end;

    Result := ParaNumbers.mHas.ContainsKey( ParaNumber );
end;


{ OneofFields }
function OneofFieldsLen( ParaFields : OneofFields ) : Integer;
begin
    Result := Length( ParaFields.mList );
end;

function OneofFieldsGet( ParaFields : OneofFields; ParaIndex : Integer ) : TFieldDescriptor;
begin
    Result := ParaFields.mList[ParaIndex];
end;

function OneofFieldsLazyInit( var ParaFields : OneofFields ) : ^OneofFields;
var
    vDoFunc : TProc;
begin
    vDoFunc := procedure
    var
        vField : TFieldDescriptor;
    begin
        if Length( ParaFields.mList ) > 0 then
        begin
            try
                ParaFields.mByName := TDictionary<TName, TFieldDescriptor>.Create( Length( ParaFields.mList ) );
                ParaFields.mByJSON := TDictionary<String, TFieldDescriptor>.Create( Length( ParaFields.mList ) );
                ParaFields.mByText := TDictionary<String, TFieldDescriptor>.Create( Length( ParaFields.mList ) );
                ParaFields.mByNum := TDictionary<TFieldNumber, TFieldDescriptor>.Create( Length( ParaFields.mList ) );
            except
                on E: EOutOfMemory do
                begin
                    raise Exception.Create( 'Failed to create dictionary in OneofFieldsLazyInit: ' + E.Message );
                end;
            end;

            for vField in ParaFields.mList do
            begin
                // Field names and numbers are guaranteed to be unique.
                ParaFields.mByName.Add( vField.Name, vField );
                ParaFields.mByJSON.Add( vField.JSONName, vField );
                ParaFields.mByText.Add( vField.TextName, vField );
                ParaFields.mByNum.Add( vField.Number, vField );
            end;
        end;
    end;

    ParaFields.mOnce.DoOnce( vDoFunc );
    Result := @ParaFields;
end;

{ SourceLocations }
function NewPathKey( ParaPath : TSourcePath ) : pathKey;
var
    vIndex : Integer;
    vPathSegment : Integer;
begin
    // Initialize array with max length
    SetLength( Result.mArr, 16 );

    if Length( ParaPath ) < Length( Result.mArr ) then
    begin
        for vIndex := 0 to High( ParaPath ) do
        begin
            vPathSegment := ParaPath[vIndex];
            // Check for negative or too large segment
            if ( vPathSegment < 0 ) or ( vPathSegment >= Math.MaxUInt8 ) then
            begin
                // Return string-based key
                Result.mStr := TArray.ToString( ParaPath ); // TSourcePath.String()
                SetLength( Result.mArr, 0 );
                Exit;
            end;
            Result.mArr[vIndex] := Byte( vPathSegment );
        end;
        Result.mArr[Length( Result.mArr ) - 1] := Byte( Length( ParaPath ) );
    end else
    begin
        // Path does not fit in array, use string representation
        Result.mStr := TArray.ToString( ParaPath );
        SetLength( Result.mArr, 0 );
    end;
end;

function SourceLocationsLen( ParaLocations : SourceLocations ) : Integer;
begin
    Result := Length( ParaLocations.mList );
end;

function SourceLocationsGet( ParaLocations : SourceLocations; ParaIndex : Integer ) : TSourceLocation;
begin
    Result := SourceLocationsLazyInit( ParaLocations )^.mList[ParaIndex];
end;


function SourceLocationsLazyInit( var ParaLocations : SourceLocations ) : ^SourceLocations;
var
    vDoFunc : TProc;
begin
    vDoFunc := procedure
    var
        vPathIdxs : TDictionary<pathKey, TArray<Integer>>;
        vIndex : Integer;
        vLocation : TSourceLocation;
        vKey : pathKey;
        vIndexes : TArray<Integer>;
    begin
        if Length( ParaLocations.mList ) > 0 then
        begin
            try
                vPathIdxs := TDictionary<pathKey, TArray<Integer>>.Create;
            except
                on E: EOutOfMemory do
                begin
                    raise Exception.Create( 'Failed to create dictionary vPathIdxs in SourceLocationsLazyInit: ' + E.Message );
                end;
            end;
            try
                // Collect all the indexes for a given path.
                for vIndex := 0 to High( ParaLocations.mList ) do
                begin
                    vLocation := ParaLocations.mList[vIndex];
                    vKey := NewPathKey( vLocation.Path );

                    if not vPathIdxs.TryGetValue( vKey, vIndexes ) then
                    begin
                        vIndexes := TArray<Integer>.Create;
                    end;
                    vPathIdxs[vKey] := vIndexes + [ vIndex ];
                end;

                // Update the next index for all locations and set the first index
                ParaLocations.mByPath := TDictionary<pathKey, Integer>.Create( vPathIdxs.Count );
                for vKey in vPathIdxs.Keys do
                begin
                    vIndexes := vPathIdxs[vKey];
                    // Update the next index chain
                    for vIndex := 0 to High( vIndexes ) - 1 do
                    begin
                        ParaLocations.mList[vIndexes[vIndex]].Next := vIndexes[vIndex + 1];
                    end;
                    ParaLocations.mList[vIndexes[High( vIndexes )]].Next := 0; // The last one points to 0

                    // Record the first location for this path
                    ParaLocations.mByPath.Add( vKey, vIndexes[0] );
                end;
            finally
                vPathIdxs.Free;
            end;
        end;
    end;

    ParaLocations.mOnce.DoOnce( vDoFunc );
    Result := @ParaLocations;
end;


end.