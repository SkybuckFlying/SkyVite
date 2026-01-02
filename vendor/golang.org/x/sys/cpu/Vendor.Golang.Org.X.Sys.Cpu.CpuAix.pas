unit Vendor.Golang.Org.X.Sys.Cpu.CpuAix;

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure archInit;

implementation

const
  _SC_IMPL     = 2;
  _IMPL_POWER8 = $10000;
  _IMPL_POWER9 = $20000;

function getsystemcfg(label: Integer): UInt64;
begin
  // Placeholder for getsystemcfg call
  Result := 0;
end;

procedure archInit;
var
  impl: UInt64;
begin
  impl := getsystemcfg(_SC_IMPL);
  if impl and _IMPL_POWER8 <> 0 then
    PPC64.IsPOWER8 := True;
  if impl and _IMPL_POWER9 <> 0 then
  begin
    PPC64.IsPOWER8 := True;
    PPC64.IsPOWER9 := True;
  end;

  Initialized := True;
end;

end.
