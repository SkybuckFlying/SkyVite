program Printer;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.Printer.Main in 'Cmd.Printer.Main.pas';

var
  vApp: TPrinterApp;
begin
  try
    vApp := TPrinterApp.Create;
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