{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Davecgh.GoSpew.Spew.Format;

interface

{$IFDEF FPC}
uses
	Classes, Rtti, SysUtils, Generics.Collections
;
{$ELSE}
uses
	System.Classes, System.Rtti, System.SysUtils, System.Generics.Collections
;
{$ENDIF}

type
	TFormatState = class
	private
		mValue          : TValue;
		mFs             : TStream;
		mDepth          : Integer;
		mPointers       : TDictionary<UIntPtr, Integer>;
		mIgnoreNextType : Boolean;
		
		procedure printBool( ParaVal : Boolean );
		procedure printInt( ParaVal : Int64; ParaBase : Integer );
		procedure printUint( ParaVal : UInt64; ParaBase : Integer );
		procedure printFloat( ParaVal : Extended; ParaPrecision : Integer );
		procedure printHexPtr( ParaP : UIntPtr );

	public
		constructor Create( ParaV : TValue );
		destructor Destroy; override;

		function buildDefaultFormat : string;
		function constructOrigFormat( ParaVerb : Char ) : string;
		function unpackValue( ParaV : TValue ) : TValue;
		procedure formatPtr( ParaV : TValue );
		procedure format( ParaV : TValue );
		
		procedure Execute( ParaFs : TStream; ParaVerb : Char );
	end;

function NewFormatter( ParaV : TValue ) : TFormatState;

implementation

uses
	Vendor.Github.Com.Davecgh.GoSpew.Spew.Config,
	Vendor.Github.Com.Davecgh.GoSpew.Spew.Common
;

const
	ConstSupportedFlags = '0-+# ';

constructor TFormatState.Create( ParaV : TValue );
begin
	inherited Create;
	mValue := ParaV;
	mPointers := nil;
	try
		mPointers := TDictionary<UIntPtr, Integer>.Create;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed for mPointers' );
		end;
	end;
	mDepth := 0;
	mIgnoreNextType := False;
end;

destructor TFormatState.Destroy;
begin
	if mPointers <> nil then
	begin
		mPointers.Free;
	end;
	inherited Destroy;
end;

function TFormatState.buildDefaultFormat : string;
begin
	Result := '%v';
end;

function TFormatState.constructOrigFormat( ParaVerb : Char ) : string;
begin
	Result := '%' + ParaVerb;
end;

function TFormatState.unpackValue( ParaV : TValue ) : TValue;
begin
	// In Delphi, TValue doesn't have a direct 'Interface' kind like Go,
	// but it can hold various types.
	Result := ParaV;
end;

procedure TFormatState.printBool( ParaVal : Boolean );
begin
	if ParaVal then
	begin
		mFs.Write( Const_TrueBytes[ 0 ], Length( Const_TrueBytes ) );
	end else
	begin
		mFs.Write( Const_FalseBytes[ 0 ], Length( Const_FalseBytes ) );
	end;
end;

procedure TFormatState.printInt( ParaVal : Int64; ParaBase : Integer );
var
	vS : string;
	vB : TBytes;
begin
	vS := IntToStr( ParaVal );
	vB := TEncoding.UTF8.GetBytes( vS );
	mFs.Write( vB[ 0 ], Length( vB ) );
end;

procedure TFormatState.printUint( ParaVal : UInt64; ParaBase : Integer );
var
	vS : string;
	vB : TBytes;
begin
	vS := UIntToStr( ParaVal );
	vB := TEncoding.UTF8.GetBytes( vS );
	mFs.Write( vB[ 0 ], Length( vB ) );
end;

procedure TFormatState.printFloat( ParaVal : Extended; ParaPrecision : Integer );
var
	vS : string;
	vB : TBytes;
begin
	vS := FloatToStr( ParaVal );
	vB := TEncoding.UTF8.GetBytes( vS );
	mFs.Write( vB[ 0 ], Length( vB ) );
end;

procedure TFormatState.printHexPtr( ParaP : UIntPtr );
var
	vS : string;
	vB : TBytes;
begin
	if ParaP = 0 then
	begin
		mFs.Write( Const_NilAngleBytes[ 0 ], Length( Const_NilAngleBytes ) );
		Exit;
	end;
	vS := '0x' + IntToHex( ParaP, 0 );
	vB := TEncoding.UTF8.GetBytes( vS );
	mFs.Write( vB[ 0 ], Length( vB ) );
end;

procedure TFormatState.formatPtr( ParaV : TValue );
var
	vAddr : UIntPtr;
	vCycleFound : Boolean;
begin
	vAddr := UIntPtr( ParaV.AsPointer );
	if vAddr = 0 then
	begin
		mFs.Write( Const_NilAngleBytes[ 0 ], Length( Const_NilAngleBytes ) );
		Exit;
	end;

	vCycleFound := mPointers.ContainsKey( vAddr );
	if vCycleFound then
	begin
		mFs.Write( Const_CircularShortBytes[ 0 ], Length( Const_CircularShortBytes ) );
		Exit;
	end;

	mPointers.Add( vAddr, mDepth );
	
	// Simplify: just show pointer address and value
	printHexPtr( vAddr );
	mFs.Write( Const_OpenParenBytes[ 0 ], Length( Const_OpenParenBytes ) );
	// Recursively format what it points to if possible
	// In Delphi TValue for pointers is limited without more info
	mFs.Write( Const_CloseParenBytes[ 0 ], Length( Const_CloseParenBytes ) );
end;

procedure TFormatState.format( ParaV : TValue );
var
	vKind : TTypeKind;
begin
	vKind := ParaV.Kind;
	
	case vKind of
		tkEnumeration:
		begin
			if ParaV.TypeInfo = TypeInfo( Boolean ) then
			begin
				printBool( ParaV.AsBoolean );
			end else
			begin
				printInt( ParaV.AsOrdinal, 10 );
			end;
		end;

		tkInteger, tkInt64:
		begin
			printInt( ParaV.AsOrdinal, 10 );
		end;

		tkFloat:
		begin
			printFloat( ParaV.AsExtended, 64 );
		end;

		tkString, tkLString, tkWString, tkUString:
		begin
			mFs.Write( TEncoding.UTF8.GetBytes( ParaV.AsString )[ 0 ], Length( TEncoding.UTF8.GetBytes( ParaV.AsString ) ) );
		end;

		tkPointer:
		begin
			formatPtr( ParaV );
		end;

		tkClass:
		begin
			mFs.Write( Const_OpenBraceBytes[ 0 ], Length( Const_OpenBraceBytes ) );
			// Simplify: classes handled like structs in Go
			mFs.Write( Const_CloseBraceBytes[ 0 ], Length( Const_CloseBraceBytes ) );
		end;

		tkArray, tkDynArray:
		begin
			mFs.Write( Const_OpenBracketBytes[ 0 ], Length( Const_OpenBracketBytes ) );
			mFs.Write( Const_CloseBracketBytes[ 0 ], Length( Const_CloseBracketBytes ) );
		end;

	else
		begin
			mFs.Write( Const_InvalidAngleBytes[ 0 ], Length( Const_InvalidAngleBytes ) );
		end;
	end;
end;

procedure TFormatState.Execute( ParaFs : TStream; ParaVerb : Char );
begin
	mFs := ParaFs;
	if ParaVerb <> 'v' then
	begin
		// Not supported directly, return default
		Exit;
	end;
	
	if mValue.IsEmpty then
	begin
		mFs.Write( Const_NilAngleBytes[ 0 ], Length( Const_NilAngleBytes ) );
		Exit;
	end;

	format( mValue );
end;

function NewFormatter( ParaV : TValue ) : TFormatState;
begin
	Result := TFormatState.Create( ParaV );
end;

end.
