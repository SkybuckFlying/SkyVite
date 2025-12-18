unit Vendor.Github.Com.Davecgh.GoSpew.Spew.Common;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Rtti,
	Vendor.Github.Com.Davecgh.GoSpew.Spew.Config;

var
	Const_PanicBytes            : TBytes;
	Const_PlusBytes             : TBytes;
	Const_IBytes                : TBytes;
	Const_TrueBytes             : TBytes;
	Const_FalseBytes            : TBytes;
	Const_InterfaceBytes        : TBytes;
	Const_CommaNewlineBytes     : TBytes;
	Const_NewlineBytes          : TBytes;
	Const_OpenBraceBytes        : TBytes;
	Const_OpenBraceNewlineBytes : TBytes;
	Const_CloseBraceBytes       : TBytes;
	Const_AsteriskBytes         : TBytes;
	Const_ColonBytes            : TBytes;
	Const_ColonSpaceBytes       : TBytes;
	Const_OpenParenBytes        : TBytes;
	Const_CloseParenBytes       : TBytes;
	Const_SpaceBytes            : TBytes;
	Const_PointerChainBytes     : TBytes;
	Const_NilAngleBytes         : TBytes;
	Const_MaxNewlineBytes       : TBytes;
	Const_MaxShortBytes         : TBytes;
	Const_CircularBytes         : TBytes;
	Const_CircularShortBytes    : TBytes;
	Const_InvalidAngleBytes     : TBytes;
	Const_OpenBracketBytes      : TBytes;
	Const_CloseBracketBytes     : TBytes;
	Const_PercentBytes          : TBytes;
	Const_PrecisionBytes        : TBytes;
	Const_OpenAngleBytes        : TBytes;
	Const_CloseAngleBytes       : TBytes;
	Const_OpenMapBytes          : TBytes;
	Const_CloseMapBytes         : TBytes;
	Const_LenEqualsBytes        : TBytes;
	Const_CapEqualsBytes        : TBytes;

const
	Const_HexDigits = '0123456789abcdef';

procedure CatchPanic( ParaW : TStream; const ParaV : TValue );
function HandleMethods( var ParaCs : TConfigState; ParaW : TStream; const ParaV : TValue ) : Boolean;

implementation

procedure CatchPanic( ParaW : TStream; const ParaV : TValue );
begin
	// Simplified panic handling for Delphi
end;

function HandleMethods( var ParaCs : TConfigState; ParaW : TStream; const ParaV : TValue ) : Boolean;
begin
	Result := False;
	// Implementation would use RTTI to check for 'ToString' or 'Error' methods
end;

initialization
	Const_PanicBytes := TEncoding.UTF8.GetBytes( '(PANIC=' );
	Const_PlusBytes := TEncoding.UTF8.GetBytes( '+' );
	Const_IBytes := TEncoding.UTF8.GetBytes( 'i' );
	Const_TrueBytes := TEncoding.UTF8.GetBytes( 'true' );
	Const_FalseBytes := TEncoding.UTF8.GetBytes( 'false' );
	Const_InterfaceBytes := TEncoding.UTF8.GetBytes( '(interface {})' );
	Const_CommaNewlineBytes := TEncoding.UTF8.GetBytes( ',\n' );
	Const_NewlineBytes := TEncoding.UTF8.GetBytes( '\n' );
	Const_OpenBraceBytes := TEncoding.UTF8.GetBytes( '{' );
	Const_OpenBraceNewlineBytes := TEncoding.UTF8.GetBytes( '{\n' );
	Const_CloseBraceBytes := TEncoding.UTF8.GetBytes( '}' );
	Const_AsteriskBytes := TEncoding.UTF8.GetBytes( '*' );
	Const_ColonBytes := TEncoding.UTF8.GetBytes( ':' );
	Const_ColonSpaceBytes := TEncoding.UTF8.GetBytes( ': ' );
	Const_OpenParenBytes := TEncoding.UTF8.GetBytes( '(' );
	Const_CloseParenBytes := TEncoding.UTF8.GetBytes( ')' );
	Const_SpaceBytes := TEncoding.UTF8.GetBytes( ' ' );
	Const_PointerChainBytes := TEncoding.UTF8.GetBytes( '->' );
	Const_NilAngleBytes := TEncoding.UTF8.GetBytes( '<nil>' );
	Const_MaxNewlineBytes := TEncoding.UTF8.GetBytes( '<max depth reached>\n' );
	Const_MaxShortBytes := TEncoding.UTF8.GetBytes( '<max>' );
	Const_CircularBytes := TEncoding.UTF8.GetBytes( '<already shown>' );
	Const_CircularShortBytes := TEncoding.UTF8.GetBytes( '<shown>' );
	Const_InvalidAngleBytes := TEncoding.UTF8.GetBytes( '<invalid>' );
	Const_OpenBracketBytes := TEncoding.UTF8.GetBytes( '[' );
	Const_CloseBracketBytes := TEncoding.UTF8.GetBytes( ']' );
	Const_PercentBytes := TEncoding.UTF8.GetBytes( '%' );
	Const_PrecisionBytes := TEncoding.UTF8.GetBytes( '.' );
	Const_OpenAngleBytes := TEncoding.UTF8.GetBytes( '<' );
	Const_CloseAngleBytes := TEncoding.UTF8.GetBytes( '>' );
	Const_OpenMapBytes := TEncoding.UTF8.GetBytes( 'map[' );
	Const_CloseMapBytes := TEncoding.UTF8.GetBytes( ']' );
	Const_LenEqualsBytes := TEncoding.UTF8.GetBytes( 'len=' );
	Const_CapEqualsBytes := TEncoding.UTF8.GetBytes( 'cap=' );

end.
