unit Vendor.Github.Com.Pkg.Errors.Errors;

interface

uses
	System.SysUtils,
	System.Classes,
	Vendor.Github.Com.Pkg.Errors.Stack;

type
	IError = interface
		['{4E50534C-4552-524F-522D-494E-5446-20202020}']
		function Error : string;
	end;

	ICauser = interface
		['{4E534341-5553-4552-2D49-4E54-4620-20202020}']
		function Cause : IError;
	end;

	IWrapper = interface
		['{4E535752-4150-5045-522D-494E-5446-20202020}']
		function Unwrap : IError;
	end;

	TFundamental = class( TInterfacedObject, IError )
	private
		mMsg   : string;
		mStack : TStack;
	public
		constructor Create( ParaMsg : string; ParaStack : TStack );
		destructor Destroy; override;
		function Error : string;
	end;

	TWithStack = class( TInterfacedObject, IError, ICauser, IWrapper )
	private
		mError : IError;
		mStack : TStack;
	public
		constructor Create( ParaError : IError; ParaStack : TStack );
		destructor Destroy; override;
		function Error : string;
		function Cause : IError;
		function Unwrap : IError;
	end;

	TWithMessage = class( TInterfacedObject, IError, ICauser, IWrapper )
	private
		mCause : IError;
		mMsg   : string;
	public
		constructor Create( ParaCause : IError; ParaMsg : string );
		function Error : string;
		function Cause : IError;
		function Unwrap : IError;
	end;

function NewError( ParaMessage : string ) : IError;
function Errorf( ParaFormat : string; const ParaArgs : array of const ) : IError;
function Wrap( ParaErr : IError; ParaMessage : string ) : IError;
function Wrapf( ParaErr : IError; ParaFormat : string; const ParaArgs : array of const ) : IError;
function WithStack( ParaErr : IError ) : IError;
function WithMessage( ParaErr : IError; ParaMessage : string ) : IError;
function Cause( ParaErr : IError ) : IError;

implementation

{ TFundamental }

constructor TFundamental.Create( ParaMsg : string; ParaStack : TStack );
begin
	inherited Create;
	mMsg := ParaMsg;
	mStack := ParaStack;
end;

destructor TFundamental.Destroy;
begin
	if Assigned( mStack ) then
		mStack.Free;
	inherited;
end;

function TFundamental.Error : string;
begin
	Result := mMsg;
end;

{ TWithStack }

constructor TWithStack.Create( ParaError : IError; ParaStack : TStack );
begin
	inherited Create;
	mError := ParaError;
	mStack := ParaStack;
end;

destructor TWithStack.Destroy;
begin
	if Assigned( mStack ) then
		mStack.Free;
	inherited;
end;

function TWithStack.Error : string;
begin
	Result := mError.Error;
end;

function TWithStack.Cause : IError;
begin
	Result := mError;
end;

function TWithStack.Unwrap : IError;
begin
	Result := mError;
end;

{ TWithMessage }

constructor TWithMessage.Create( ParaCause : IError; ParaMsg : string );
begin
	inherited Create;
	mCause := ParaCause;
	mMsg := ParaMsg;
end;

function TWithMessage.Error : string;
begin
	Result := mMsg + ': ' + mCause.Error;
end;

function TWithMessage.Cause : IError;
begin
	Result := mCause;
end;

function TWithMessage.Unwrap : IError;
begin
	Result := mCause;
end;

{ Functions }

function NewError( ParaMessage : string ) : IError;
begin
	Result := TFundamental.Create( ParaMessage, Callers );
end;

function Errorf( ParaFormat : string; const ParaArgs : array of const ) : IError;
begin
	Result := TFundamental.Create( Format( ParaFormat, ParaArgs ), Callers );
end;

function Wrap( ParaErr : IError; ParaMessage : string ) : IError;
var
	vErr : IError;
begin
	if not Assigned( ParaErr ) then
		Exit( nil );
	vErr := TWithMessage.Create( ParaErr, ParaMessage );
	Result := TWithStack.Create( vErr, Callers );
end;

function Wrapf( ParaErr : IError; ParaFormat : string; const ParaArgs : array of const ) : IError;
var
	vErr : IError;
begin
	if not Assigned( ParaErr ) then
		Exit( nil );
	vErr := TWithMessage.Create( ParaErr, Format( ParaFormat, ParaArgs ) );
	Result := TWithStack.Create( vErr, Callers );
end;

function WithStack( ParaErr : IError ) : IError;
begin
	if not Assigned( ParaErr ) then
		Exit( nil );
	Result := TWithStack.Create( ParaErr, Callers );
end;

function WithMessage( ParaErr : IError; ParaMessage : string ) : IError;
begin
	if not Assigned( ParaErr ) then
		Exit( nil );
	Result := TWithMessage.Create( ParaErr, ParaMessage );
end;

function Cause( ParaErr : IError ) : IError;
var
	vCauser : ICauser;
begin
	Result := ParaErr;
	while Assigned( Result ) and Supports( Result, ICauser, vCauser ) do
		Result := vCauser.Cause;
end;

end.
