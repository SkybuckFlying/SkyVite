unit Vendor.Github.Com.Mattn.GoColorable.NonColorable;

interface

uses
	System.Classes,
	System.SysUtils;

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
