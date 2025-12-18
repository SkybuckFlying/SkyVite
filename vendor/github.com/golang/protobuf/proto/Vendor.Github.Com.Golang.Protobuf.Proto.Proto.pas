unit Vendor.Github.Com.Golang.Protobuf.Proto.Proto;

interface

uses
	System.Classes,
	System.SysUtils;

type
	IMessage = interface
		['{B83F1D1E-109E-4F8B-BA7C-402877D41E24}']
		procedure Reset;
		function String : string;
		procedure ProtoMessage;
	end;

	TRequiredNotSetError = class( Exception )
	public
		constructor Create;
	end;

function Clone( ParaSrc : IMessage ) : IMessage;
procedure Merge( ParaDst, ParaSrc : IMessage );
function Equal( ParaX, ParaY : IMessage ) : Boolean;

implementation

function Clone( ParaSrc : IMessage ) : IMessage;
begin
	// Simplified Clone
	Result := nil;
end;

procedure Merge( ParaDst, ParaSrc : IMessage );
begin
	// Simplified Merge
end;

function Equal( ParaX, ParaY : IMessage ) : Boolean;
begin
	// Simplified Equal
	Result := False;
end;

{ TRequiredNotSetError }

constructor TRequiredNotSetError.Create;
begin
	inherited Create( 'proto: required field not set' );
end;

end.
