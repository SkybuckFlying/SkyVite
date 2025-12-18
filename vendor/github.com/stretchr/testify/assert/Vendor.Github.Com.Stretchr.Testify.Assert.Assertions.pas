unit Vendor.Github.Com.Stretchr.Testify.Assert.Assertions;

interface

uses
	System.SysUtils,
	System.Rtti,
	System.TypInfo,
	System.Generics.Collections,
	System.Classes;

type
	ITestingT = interface
		['{E9A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F6A}']
		procedure Errorf( const ParaFormat : string; const ParaArgs : array of const );
	end;

	TTestingT = class( TInterfacedObject, ITestingT )
	public
		procedure Errorf( const ParaFormat : string; const ParaArgs : array of const );
	end;

function ObjectsAreEqual( const ParaExpected, ParaActual : TValue ) : Boolean;
function Equal( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
function NotEqual( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
function IsNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
function NotNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
function IsTrue( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const ) : Boolean;
function IsFalse( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const ) : Boolean;
function Empty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
function NotEmpty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;

implementation

{ TTestingT }

procedure TTestingT.Errorf( const ParaFormat : string; const ParaArgs : array of const );
begin
	WriteLn( Format( ParaFormat, ParaArgs ) );
end;

function ObjectsAreEqual( const ParaExpected, ParaActual : TValue ) : Boolean;
begin
	if ParaExpected.IsEmpty or ParaActual.IsEmpty then
		Exit( ParaExpected.IsEmpty = ParaActual.IsEmpty );

	if ParaExpected.TypeInfo <> ParaActual.TypeInfo then
		Exit( False );

	case ParaExpected.Kind of
		tkInteger, tkInt64: Exit( ParaExpected.AsExtended = ParaActual.AsExtended );
		tkFloat: Exit( ParaExpected.AsExtended = ParaActual.AsExtended );
		tkUString, tkString, tkWString, tkLString: Exit( ParaExpected.AsString = ParaActual.AsString );
		tkEnumeration: Exit( ParaExpected.AsOrdinal = ParaActual.AsOrdinal );
		tkSet: Exit( ParaExpected.AsOrdinal = ParaActual.AsOrdinal );
	else
		Result := ParaExpected.ToString = ParaActual.ToString; // Fallback
	end;
end;

function MessageFromMsgAndArgs( const ParaMsgAndArgs : array of const ) : string;
begin
	if Length( ParaMsgAndArgs ) = 0 then
		Exit( '' );
	if ( Length( ParaMsgAndArgs ) = 1 ) and ( ParaMsgAndArgs[ 0 ].VType = vtUnicodeString ) then
		Exit( string( ParaMsgAndArgs[ 0 ].VUnicodeString ) );
	
	// Complex message formatting would go here
	Result := 'Assertion failed';
end;

function Equal( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := ObjectsAreEqual( ParaExpected, ParaActual );
	if not Result then
		ParaT.Errorf( 'Not equal: expected %s, actual %s. %s', [ ParaExpected.ToString, ParaActual.ToString, MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

function NotEqual( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := not ObjectsAreEqual( ParaExpected, ParaActual );
	if not Result then
		ParaT.Errorf( 'Should not be equal: %s. %s', [ ParaActual.ToString, MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

function IsNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := ParaObject.IsEmpty or ( ( ParaObject.Kind = tkPointer ) and ( ParaObject.AsPointer = nil ) ) or
	          ( ( ParaObject.Kind = tkInterface ) and ( ParaObject.AsInterface = nil ) ) or
	          ( ( ParaObject.Kind = tkClass ) and ( ParaObject.AsObject = nil ) );
	if not Result then
		ParaT.Errorf( 'Expected nil, but got %s. %s', [ ParaObject.ToString, MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

function NotNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := not ( ParaObject.IsEmpty or ( ( ParaObject.Kind = tkPointer ) and ( ParaObject.AsPointer = nil ) ) or
	          ( ( ParaObject.Kind = tkInterface ) and ( ParaObject.AsInterface = nil ) ) or
	          ( ( ParaObject.Kind = tkClass ) and ( ParaObject.AsObject = nil ) ) );
	if not Result then
		ParaT.Errorf( 'Expected not nil. %s', [ MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

function IsTrue( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := ParaValue;
	if not Result then
		ParaT.Errorf( 'Should be true. %s', [ MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

function IsFalse( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := not ParaValue;
	if not Result then
		ParaT.Errorf( 'Should be false. %s', [ MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

function Empty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := ParaObject.IsEmpty or ( ParaObject.ToString = '' ); // Simplified
	if not Result then
		ParaT.Errorf( 'Should be empty, but was %s. %s', [ ParaObject.ToString, MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

function NotEmpty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const ) : Boolean;
begin
	Result := not ( ParaObject.IsEmpty or ( ParaObject.ToString = '' ) ); // Simplified
	if not Result then
		ParaT.Errorf( 'Should not be empty. %s', [ MessageFromMsgAndArgs( ParaMsgAndArgs ) ] );
end;

end.
