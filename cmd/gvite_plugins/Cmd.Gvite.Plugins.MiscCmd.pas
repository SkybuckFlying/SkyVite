unit Cmd.GvitePlugins.MiscCmd;

interface

uses
  Cli,
  Cmd.Gvite.Plugins.Load.Plugins,
  Cmd.Gvite.Plugins.SubCmd.Demo,
  Cmd.Utils,
  System.Classes,
  System.SysUtils,
  Version;

var
	versionCommand: ICommand;
	licenseCommand: ICommand;

implementation

uses
	GoToDelphi.Helpers.Runtime;

procedure versionAction( const ParaCtx: IContext );
begin
	WriteLn(UpperCase('gvite'));
	WriteLn('Version:', VITE_BUILD_VERSION);
	WriteLn('Git Commit:', VITE_COMMIT_VERSION);
	WriteLn('Architecture:', GOARCH);
	//WriteLn('Network Id:', ParaCtx.GlobalInt());
	WriteLn('Go Version:', GoVersion);
	WriteLn('Operating System:', GOOS);
	WriteLn('GOPATH=', GetEnvironmentVariable('GOPATH'));
	WriteLn('GOROOT=', GetGoRoot);
end;

procedure licenseAction( const ParaCtx: IContext );
begin
	WriteLn('GVite is free software: you can redistribute it and/or modify');
	WriteLn('it under the terms of the GNU General Public License as published by');
	WriteLn('the Free Software Foundation, either version 3 of the License, or');
	WriteLn('(at your option) any later version.');
	WriteLn('');
	WriteLn('GVite is distributed in the hope that it will be useful,');
	WriteLn('but WITHOUT ANY WARRANTY; without even the implied warranty of');
	WriteLn('MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the');
	WriteLn('GNU General Public License for more details.');
	WriteLn('');
	WriteLn('You should have received chain copy of the GNU General Public License');
	WriteLn('along with gvite. If not, see <http://www.gnu.org/licenses/>.');
end;

initialization
	versionCommand := TCommand.Create(
		'version',
		'Print version numbers',
		' ',
		'MISCELLANEOUS COMMANDS',
		'The output of this command is supposed to be machine-readable.',
		MigrateFlags(versionAction)
	);

	licenseCommand := TCommand.Create(
		'license',
		'Display license information',
		' ',
		'MISCELLANEOUS COMMANDS',
		'',
		MigrateFlags(licenseAction)
	);
end.
