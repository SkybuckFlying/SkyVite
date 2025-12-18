unit Vendor.Github.Com.Golang.Mock.GoMock.Controller;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.RTTI,
  System.SysUtils,
  Vendor.Github.Com.Golang.Mock.GoMock.Call,
  Vendor.Github.Com.Golang.Mock.GoMock.Callset,
  Vendor.Github.Com.Golang.Mock.GoMock.Matchers;

type
	TController = class
	private
		mExpectedCalls : TList<TCall>;
		mFinished      : Boolean;
	public
		constructor Create;
		destructor Destroy; override;

		function RecordCall( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue ) : TCall;
		procedure Call( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue );
		procedure Finish;
	end;

implementation

{ TController }

constructor TController.Create;
begin
	inherited Create;
	mExpectedCalls := TList<TCall>.Create;
end;

destructor TController.Destroy;
begin
	mExpectedCalls.Free;
	inherited;
end;

function TController.RecordCall( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue ) : TCall;
begin
	Result := TCall.Create( ParaReceiver, ParaMethod, ParaArgs );
	mExpectedCalls.Add( Result );
end;

procedure TController.Call( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue );
var
	vCall : TCall;
begin
	for vCall in mExpectedCalls do
	begin
		if ( vCall.Receiver = ParaReceiver ) and ( vCall.Method = ParaMethod ) and vCall.Matches( ParaArgs ) then
		begin
			vCall.Call;
			if vCall.Exhausted then
				mExpectedCalls.Remove( vCall );
			Exit;
		end;
	end;
	raise Exception.Create( 'Unexpected call to ' + ParaMethod );
end;

procedure TController.Finish;
var
	vCall : TCall;
begin
	for vCall in mExpectedCalls do
		if not vCall.Satisfied then
			raise Exception.Create( 'Missing call to ' + vCall.Method );
	mFinished := True;
end;

end.
