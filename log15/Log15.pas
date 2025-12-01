unit Log15;

interface

uses
  System.SysUtils, System.Rtti;

type
  TLvl = (LvlCrit, LvlError, LvlWarn, LvlInfo, LvlDebug);

function LvlToString(Lvl: TLvl): string;
function LvlFromString(const s: string): TLvl;

type
  IRecord = interface
    ['{A9A9A9A9-9A9A-9A9A-9A9A-9A9A9A9A9A9A}']
    function GetTime: TDateTime;
    function GetLvl: TLvl;
    function GetMsg: string;
    function GetCtx: TArray<TValue>;
    property Time: TDateTime read GetTime;
    property Lvl: TLvl read GetLvl;
    property Msg: string read GetMsg;
    property Ctx: TArray<TValue> read GetCtx;
  end;

  IFormat = interface
    ['{55E3E3E3-3E3E-4E3E-8E3E-3E3E3E3E3E3E}']
    function Format(r: IRecord): TBytes;
  end;

  IHandler = interface
    ['{B8B8B8B8-8B8B-8B8B-8B8B-8B8B8B8B8B8B}']
    procedure Log(r: IRecord);
  end;

  ILogger = interface
    ['{C7C7C7C7-7C7C-7C7C-7C7C-7C7C7C7C7C7C}']
    function New(Ctx: array of const): ILogger;
    function GetHandler: IHandler;
    procedure SetHandler(AHandler: IHandler);
    procedure Debug(Msg: string; Ctx: array of const);
    procedure Info(Msg: string; Ctx: array of const);
    procedure Warn(Msg: string; Ctx: array of const);
    procedure Error(Msg: string; Ctx: array of const);
    procedure Crit(Msg: string; Ctx: array of const);
  end;

implementation

function LvlToString(Lvl: TLvl): string;
begin
  case Lvl of
    TLvl.LvlCrit: Result := 'crit';
    TLvl.LvlError: Result := 'eror';
    TLvl.LvlWarn: Result := 'warn';
    TLvl.LvlInfo: Result := 'info';
    TLvl.LvlDebug: Result := 'dbug';
  end;
end;

function LvlFromString(const s: string): TLvl;
var
  lower: string;
begin
  lower := LowerCase(s);
  if (lower = 'crit') or (lower = 'critical') then Result := TLvl.LvlCrit
  else if (lower = 'eror') or (lower = 'error') then Result := TLvl.LvlError
  else if (lower = 'warn') or (lower = 'warning') then Result := TLvl.LvlWarn
  else if (lower = 'info') then Result := TLvl.LvlInfo
  else if (lower = 'dbug') or (lower = 'debug') then Result := TLvl.LvlDebug
  else raise Exception.Create('Unknown level: ' + s);
end;

end.
