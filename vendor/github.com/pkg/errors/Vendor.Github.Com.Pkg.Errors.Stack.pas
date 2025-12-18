unit Vendor.Github.Com.Pkg.Errors.Stack;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections;

type
	/// <summary>
	/// Frame represents a program counter inside a stack frame.
	/// </summary>
	TFrame = NativeUInt;

	TStackTrace = TArray<TFrame>;

	TStack = class
	private
		mFrames : TStackTrace;
	public
		constructor Create( ParaFrames : TStackTrace );
		property Frames : TStackTrace read mFrames;

		function StackTrace : TStackTrace;
	end;

function Callers : TStack;

implementation

{ TStack }

constructor TStack.Create( ParaFrames : TStackTrace );
begin
	inherited Create;
	mFrames := ParaFrames;
end;

function TStack.StackTrace : TStackTrace;
begin
	Result := mFrames;
end;

function Callers : TStack;
var
	vFrames : TStackTrace;
begin
	// In Delphi, we don't have a direct equivalent to runtime.Callers that works exactly like Go.
	// However, we can use Exception.StackTrace or external libraries if available.
	// For this conversion, we will return an empty stack or a stub.
	SetLength( vFrames, 0 );
	Result := TStack.Create( vFrames );
end;

end.
