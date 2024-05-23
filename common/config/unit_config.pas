unit unit_config;

interface

uses
  SysUtils,
  Classes,
  IniFiles,
  unit_Producer;

type
  TConfig = class
  private
    FProducer: TProducer;
    FChain: TChain;
    FVm: TVm;
    FSubscribe: TSubscribe;
    FNet: TNet;
    FNodeReward: TNodeReward;
    FGenesis: TGenesis;
    FDataDir: string;
    FLogLevel: string;
  public
    function RunLogDir: string;
    class function DefaultDataDir: string;
    class function HomeDir: string;
    property DataDir: string read FDataDir write FDataDir;
    property LogLevel: string read FLogLevel write FLogLevel;
  end;

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  FileUtil;

function TConfig.RunLogDir: string;
begin
  Result := ConcatPaths([FDataDir, 'runlog']);
end;

class function TConfig.DefaultDataDir: string;
var
  Home: string;
begin
  Home := HomeDir;
  if Home <> '' then
  begin
    {$IFDEF DARWIN}
    Result := ConcatPaths([Home, 'Library', 'GVite']);
    {$ELSE}
    {$IFDEF WINDOWS}
    Result := ConcatPaths([Home, 'AppData', 'Roaming', 'GVite']);
    {$ELSE}
    Result := ConcatPaths([Home, '.gvite']);
    {$ENDIF}
    {$ENDIF}
  end
  else
    Result := '';
end;

class function TConfig.HomeDir: string;
begin
  Result := GetEnvironmentVariable('HOME');
  if Result = '' then
    Result := GetUserDir;
end;

end.



