unit Cmd.Utils.Path;

interface

uses
  Cmd.Utils.Cli,
  Cmd.Utils.Customflags,
  Cmd.Utils.Customflags.Test,
  Cmd.Utils.Flags,
  System.IOUtils,
  System.SysUtils;

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
