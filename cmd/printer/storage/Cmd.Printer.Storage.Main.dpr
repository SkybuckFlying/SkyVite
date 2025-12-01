program StoragePrinter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Cmd.Printer.Storage.Main in 'Cmd.Pinter.Storage.Main.pas';

var
  vApp: TStoragePrinterApp;
begin
  try
    vApp := TStoragePrinterApp.Create;
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