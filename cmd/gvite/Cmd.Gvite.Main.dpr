unit Cmd.Gvite.Main;

interface

uses
  System.SysUtils;

type
  TMainCmd = class
  public
    class function Execute: Integer;
  end;

implementation

uses
  Cmd.GvitePlugins.LoadPlugins in '..\gvite_plugins\Cmd.GvitePlugins.LoadLedger.Chain.Plugins.Plugins',
  Version.Version in '..\..\version\Version.Common.Db.Xleveldb.Version';

{ TMainCmd }

class function TMainCmd.Execute: Integer;
begin
  Result := 0;
  try
    PrintBuildVersion;
    Loading;
  except
    on E: Exception do
    begin
      WriteLn(E.Message);
      Result := 1;
    end;
  end;
end;

end.