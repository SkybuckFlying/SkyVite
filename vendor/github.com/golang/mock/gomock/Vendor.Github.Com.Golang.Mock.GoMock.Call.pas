unit Vendor.Github.Com.Golang.Mock.GoMock.Call;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections,
	System.RTTI,
	Vendor.Github.Com.Golang.Mock.GoMock.Matchers;

type
	TCall = class
	private
		mReceiver   : Pointer;
		mMethod     : string;
		mArgs       : TList<IMatcher>;
		mMinCalls   : Integer;
		mMaxCalls   : Integer;
		mNumCalls   : Integer;
		mPreReqs    : TList<TCall>;
	public
		constructor Create( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue );
		destructor Destroy; override;

		function Times( ParaN : Integer ) : TCall;
		function AnyTimes : TCall;
		function After( ParaPreReq : TCall ) : TCall;

		function Matches( ParaArgs : array of TValue ) : Boolean;
		procedure Call;
		function Satisfied : Boolean;
		function Exhausted : Boolean;

		property Receiver : Pointer read mReceiver;
		property Method : string read mMethod;
	end;

implementation

{ TCall }

constructor TCall.Create( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue );
var
	vArg : TValue;
begin
	inherited Create;
	mReceiver := ParaReceiver;
	mMethod := ParaMethod;
	mArgs := TList<IMatcher>.Create;
	for vArg in ParaArgs do
		mArgs.Add( Eq( vArg ) );
	mMinCalls := 1;
	mMaxCalls := 1;
	mPreReqs := TList<TCall>.Create;
end;

destructor TCall.Destroy;
begin
	mArgs.Free;
	mPreReqs.Free;
	inherited;
end;

function TCall.Times( ParaN : Integer ) : TCall;
begin
	mMinCalls := ParaN;
	mMaxCalls := ParaN;
	Result := Self;
end;

function TCall.AnyTimes : TCall;
begin
	mMinCalls := 0;
	mMaxCalls := 1000000;
	Result := Self;
end;

function TCall.After( ParaPreReq : TCall ) : TCall;
begin
	mPreReqs.Add( ParaPreReq );
	Result := Self;
end;

function TCall.Matches( ParaArgs : array of TValue ) : Boolean;
var
	vI : Integer;
begin
	if Length( ParaArgs ) <> mArgs.Count then
		Exit( False );
	for vI := 0 to mArgs.Count - 1 do
		if not mArgs[ vI ].Matches( ParaArgs[ vI ] ) then
			Exit( False );
	Result := True;
end;

procedure TCall.Call;
begin
	Inc( mNumCalls );
end;

function TCall.Satisfied : Boolean;
begin
	Result := mNumCalls >= mMinCalls;
end;

function TCall.Exhausted : Boolean;
begin
	Result := mNumCalls >= mMaxCalls;
end;

end.
