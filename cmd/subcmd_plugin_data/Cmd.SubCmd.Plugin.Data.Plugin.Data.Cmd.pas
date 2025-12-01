program PluginData;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.SubCmd.PluginData in 'Cmd.SubCmd.PluginData.pas';

begin
  try
    // This is a subcommand, so we don't need to do anything here.
    // The command is registered in the initialization section of the unit.
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
