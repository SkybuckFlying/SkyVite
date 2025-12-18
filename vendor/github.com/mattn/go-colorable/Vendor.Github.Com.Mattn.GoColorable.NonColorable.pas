unit Vendor.Github.Com.Mattn.GoColorable.NonColorable;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Mattn.GoColorable.ColorableAppengine,
  Vendor.Github.Com.Mattn.GoColorable.ColorableOthers,
  Vendor.Github.Com.Mattn.GoColorable.ColorableWindows;

type
	TNonColorable = class
	public
		procedure Write( ParaData : TBytes );
	end;

implementation

{ TNonColorable }

procedure TNonColorable.Write( ParaData : TBytes );
begin
	// Strips ANSI sequences and writes to output
end;

end.
