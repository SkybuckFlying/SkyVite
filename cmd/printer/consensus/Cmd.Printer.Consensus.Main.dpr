program ConsensusPrinter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.Printer.Consensus.Main in 'Cmd.Printer.Consensus.Main.pas';

var
  vApp: TConsensusPrinterApp;
begin
  try
    vApp := TConsensusPrinterApp.Create;
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