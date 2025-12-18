uses
  Cmd.SubCmd.Ledger.DumpBalance;
uses
  Cmd.SubCmd.Ledger.DumpBalance;
uses
  Cmd.SubCmd.Ledger.DumpBalance;
program Ledger;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.SubCmd.Ledger in 'Cmd.SubCmd.Ledger.pas';

begin
  try
    // This is a subcommand, so we don't need to do anything here.
    // The command is registered in the initialization section of the unit.
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
