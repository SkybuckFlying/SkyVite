program IndexPrinter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.Printer.Index.Main in 'Cmd.Printer.Index.Main.pas';

var
  vApp: TIndexPrinterApp;
begin
  try
    vApp := TIndexPrinterApp.Create;
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