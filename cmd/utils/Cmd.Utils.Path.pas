unit Cmd.Utils.Path;

interface

uses
	System.SysUtils,
	System.IOUtils;

function AbsolutePath(const ParaDataDir, ParaFileName: string): string;

implementation

function AbsolutePath(const ParaDataDir, ParaFileName: string): string;
begin
	if TPath.IsPathRooted(ParaFileName) then
	begin
		Result := ParaFileName;
	end
	else
	begin
		Result := TPath.Combine(ParaDataDir, ParaFileName);
	end;
end;

end.
