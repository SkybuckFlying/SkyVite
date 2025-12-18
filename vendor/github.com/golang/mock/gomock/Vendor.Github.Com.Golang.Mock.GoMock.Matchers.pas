unit Vendor.Github.Com.Golang.Mock.GoMock.Matchers;

interface

uses
	System.Classes,
	System.SysUtils,
	System.RTTI;

type
	IMatcher = interface
		['{A77F1D1E-109E-4F8B-BA7C-402877D41E24}']
		function Matches( ParaX : TValue ) : Boolean;
		function ToString : string;
	end;

	TAnyMatcher = class( TInterfacedObject, IMatcher )
	public
		function Matches( ParaX : TValue ) : Boolean;
		function ToString : string; override;
	end;

	TEqMatcher = class( TInterfacedObject, IMatcher )
	private
		mX : TValue;
	public
		constructor Create( ParaX : TValue );
		function Matches( ParaX : TValue ) : Boolean;
		function ToString : string; override;
	end;

	TNilMatcher = class( TInterfacedObject, IMatcher )
	public
		function Matches( ParaX : TValue ) : Boolean;
		function ToString : string; override;
	end;

function Any : IMatcher;
function Eq( ParaX : TValue ) : IMatcher;
function Nil_ : IMatcher;

implementation

function Any : IMatcher;
begin
	Result := TAnyMatcher.Create;
end;

function Eq( ParaX : TValue ) : IMatcher;
begin
	Result := TEqMatcher.Create( ParaX );
end;

function Nil_ : IMatcher;
begin
	Result := TNilMatcher.Create;
end;

{ TAnyMatcher }

function TAnyMatcher.Matches( ParaX : TValue ) : Boolean;
begin
	Result := True;
end;

function TAnyMatcher.ToString : string;
begin
	Result := 'is anything';
end;

{ TEqMatcher }

constructor TEqMatcher.Create( ParaX : TValue );
begin
	inherited Create;
	mX := ParaX;
end;

function TEqMatcher.Matches( ParaX : TValue ) : Boolean;
begin
	Result := mX.ToString = ParaX.ToString; // Simplified comparison
end;

function TEqMatcher.ToString : string;
begin
	Result := 'is equal to ' + mX.ToString;
end;

{ TNilMatcher }

function TNilMatcher.Matches( ParaX : TValue ) : Boolean;
begin
	Result := ParaX.IsEmpty;
end;

function TNilMatcher.ToString : string;
begin
	Result := 'is nil';
end;

end.
