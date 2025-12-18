unit Vendor.Github.Com.GoStack.Stack.Stack;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections;

type
	TCall = record
	public
		mPC : Pointer;
		mFile : string;
		mLine : Integer;
		mFunction : string;

		function ToString : string;
	end;

	TCallStack = class( TList<TCall> )
	public
		function ToString : string; override;
	end;

function Caller( ParaSkip : Integer ) : TCall;
function Trace : TCallStack;

implementation

function Caller( ParaSkip : Integer ) : TCall;
begin
	// Simplified Caller
	Result.mPC := nil;
	Result.mFile := '';
	Result.mLine := 0;
	Result.mFunction := '';
end;

function Trace : TCallStack;
begin
	Result := TCallStack.Create;
end;

{ TCall }

function TCall.ToString : string;
begin
	Result := Format( '%s:%d', [ mFile, mLine ] );
end;

{ TCallStack }

function TCallStack.ToString : string;
var
	vItems : TStringList;
	vCall : TCall;
begin
	vItems := TStringList.Create;
	try
		for vCall in Self do
			vItems.Add( vCall.ToString );
		Result := '[' + vItems.CommaText + ']';
	finally
		vItems.Free;
	end;
end;

end.
