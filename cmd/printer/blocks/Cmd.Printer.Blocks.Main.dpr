program BlocksPrinter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.Printer.Blocks.Main in 'Cmd.Printer.Blocks.Main.pas';

var
  vApp: TBlocksPrinterApp;
begin
  try
    vApp := TBlocksPrinterApp.Create;
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