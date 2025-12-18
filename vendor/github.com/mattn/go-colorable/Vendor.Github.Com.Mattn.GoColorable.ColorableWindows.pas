unit Vendor.Github.Com.Mattn.GoColorable.ColorableWindows;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Mattn.GoColorable.ColorableAppengine,
  Vendor.Github.Com.Mattn.GoColorable.ColorableOthers,
  Vendor.Github.Com.Mattn.GoColorable.NonColorable,
  Winapi.Windows;

type
	TWriter = class
	private
		mHandle : THandle;
		mOldAttr : WORD;
	public
		constructor Create( ParaHandle : THandle );
		procedure Write( ParaData : TBytes );
	end;

function NewColorableStdout : TWriter;
function NewColorableStderr : TWriter;

implementation

function NewColorableStdout : TWriter;
begin
	Result := TWriter.Create( GetStdHandle( STD_OUTPUT_HANDLE ) );
end;

function NewColorableStderr : TWriter;
begin
	Result := TWriter.Create( GetStdHandle( STD_ERROR_HANDLE ) );
end;

{ TWriter }

constructor TWriter.Create( ParaHandle : THandle );
var
	vCSBI : TConsoleScreenBufferInfo;
begin
	inherited Create;
	mHandle := ParaHandle;
	if GetConsoleScreenBufferInfo( mHandle, vCSBI ) then
		mOldAttr := vCSBI.wAttributes;
end;

procedure TWriter.Write( ParaData : TBytes );
begin
	// Simplified ANSI sequence parsing and color setting
	// In a real scenario, this would parse ParaData for \x1b[...m sequences
end;

end.
