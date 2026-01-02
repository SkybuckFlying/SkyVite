unit Vendor.Github.Com.Tklauser.Numcpus.NumcpusLinux;

interface

uses
  System.SysUtils, System.IOUtils, System.Classes;

function getKernelMax: Integer;
function getOffline: Integer;
function getOnline: Integer;
function getPossible: Integer;
function getPresent: Integer;

implementation

const sysfsCPUBasePath = '/sys/devices/system/cpu';

function parseCPURange(const cpus: string): Integer;
var
  n: Integer;
  cpuRange: string;
  rangeOp: TArray<string>;
  first, last: UInt64;
begin
  n := 0;
  for cpuRange in cpus.Split([',']) do
  begin
    if Length(cpuRange) = 0 then
      continue;
    rangeOp := cpuRange.Split(['-'], 2);
    if not TryStrToUInt64(rangeOp[0], first) then
      Exit(0);
    if Length(rangeOp) = 1 then
    begin
      Inc(n);
      continue;
    end;
    if not TryStrToUInt64(rangeOp[1], last) then
      Exit(0);
    n := n + Integer(last - first + 1);
  end;
  Result := n;
end;

function readCPURange(const file_name: string): Integer;
var
  content: string;
begin
  try
    content := TFile.ReadAllText(TPath.Combine(sysfsCPUBasePath, file_name)).Trim(['#10', ' ']);
    Result := parseCPURange(content);
  except
    Result := 0;
  end;
end;

function getKernelMax: Integer;
var
  content: string;
  n: Int64;
begin
  try
    content := TFile.ReadAllText(TPath.Combine(sysfsCPUBasePath, 'kernel_max')).Trim(['#10', ' ']);
    if TryStrToInt64(content, n) then
      Result := Integer(n)
    else
      Result := 0;
  except
    Result := 0;
  end;
end;

function getOffline: Integer;
begin
  Result := readCPURange('offline');
end;

function getOnline: Integer;
begin
  Result := readCPURange('online');
end;

function getPossible: Integer;
begin
  Result := readCPURange('possible');
end;

function getPresent: Integer;
begin
  Result := readCPURange('present');
end;

end.
