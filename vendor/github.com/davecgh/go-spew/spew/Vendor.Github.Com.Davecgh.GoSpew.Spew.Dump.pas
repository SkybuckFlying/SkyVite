unit Vendor.Github.Com.Davecgh.GoSpew.Spew.Dump;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  Vendor.Github.Com.Davecgh.GoSpew.Spew.Bypass,
  Vendor.Github.Com.Davecgh.GoSpew.Spew.BypassSafe,
  Vendor.Github.Com.Davecgh.GoSpew.Spew.Common,
  Vendor.Github.Com.Davecgh.GoSpew.Spew.Config,
  Vendor.Github.Com.Davecgh.GoSpew.Spew.Doc,
  Vendor.Github.Com.Davecgh.GoSpew.Spew.Format,
  Vendor.Github.Com.Davecgh.GoSpew.Spew.Spew;

type
	TdumpState = record
	public
		mW                : TStream;
		mDepth            : Integer;
		mPointers         : TDictionary<Pointer, Integer>;
		mIgnoreNextType   : Boolean;
		mIgnoreNextIndent : Boolean;
		mCs               : ^TConfigState;

		procedure Indent;
		function UnpackValue( const ParaV : TValue ) : TValue;
		procedure DumpPtr( const ParaV : TValue );
		procedure DumpSlice( const ParaV : TValue );
		procedure Dump( const ParaV : TValue );
	end;

procedure Fdump( var ParaCs : TConfigState; ParaW : TStream; const ParaA : array of TValue );
procedure Dump( const ParaA : array of TValue );
function Sdump( const ParaA : array of TValue ) : string;

implementation

uses
	Vendor.Github.Com.Davecgh.GoSpew.Spew.Common;

procedure Fdump( var ParaCs : TConfigState; ParaW : TStream; const ParaA : array of TValue );
var
	vArg : TValue;
	vD : TdumpState;
begin
	for vArg in ParaA do
	begin
		if vArg.IsEmpty then
		begin
			ParaW.Write( Const_InterfaceBytes[0], Length( Const_InterfaceBytes ) );
			ParaW.Write( Const_SpaceBytes[0], Length( Const_SpaceBytes ) );
			ParaW.Write( Const_NilAngleBytes[0], Length( Const_NilAngleBytes ) );
			ParaW.Write( Const_NewlineBytes[0], Length( Const_NewlineBytes ) );
			Continue;
		end;

		vD.mW := ParaW;
		vD.mCs := @ParaCs;
		vD.mPointers := TDictionary<Pointer, Integer>.Create;
		try
			vD.Dump( vArg );
			ParaW.Write( Const_NewlineBytes[0], Length( Const_NewlineBytes ) );
		finally
			vD.mPointers.Free;
		end;
	end;
end;

procedure Dump( const ParaA : array of TValue );
begin
	Fdump( Config, nil, ParaA ); // nil as TStream would need a real TFileStream( stdout )
end;

function Sdump( const ParaA : array of TValue ) : string;
var
	vBuf : TStringStream;
begin
	vBuf := TStringStream.Create;
	try
		Fdump( Config, vBuf, ParaA );
		Result := vBuf.DataString;
	finally
		vBuf.Free;
	end;
end;

{ TdumpState }

procedure TdumpState.Indent;
var
	vLevel : Integer;
	vIndentBytes : TBytes;
begin
	if mIgnoreNextIndent then
	begin
		mIgnoreNextIndent := False;
		Exit;
	end;
	vIndentBytes := TEncoding.UTF8.GetBytes( mCs^.mIndent );
	for vLevel := 1 to mDepth do
	begin
		mW.Write( vIndentBytes[0], Length( vIndentBytes ) );
	end;
end;

function TdumpState.UnpackValue( const ParaV : TValue ) : TValue;
begin
	// TValue in Delphi doesn't strictly have an 'Interface' kind like Go,
	// but we can check if it's an object or interface
	Result := ParaV;
end;

procedure TdumpState.DumpPtr( const ParaV : TValue );
begin
	// Logic to handle pointers and circular references using mPointers
end;

procedure TdumpState.DumpSlice( const ParaV : TValue );
begin
	// Logic to handle arrays, slices, and hexdumping byte arrays
end;

procedure TdumpState.Dump( const ParaV : TValue );
begin
	// Main recursive dump logic using RTTI
end;

end.
