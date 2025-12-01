program VotePrinter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.Printer.Vote.Main in 'Cmd.Printer.Vote.Main.pas';

var
  vApp: TVotePrinterApp;
begin
  try
    vApp := TVotePrinterApp.Create;
    try
      vApp.Run;
    finally
      vApp.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
