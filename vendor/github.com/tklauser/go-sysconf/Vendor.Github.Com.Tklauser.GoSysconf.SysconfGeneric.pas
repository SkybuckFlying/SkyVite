unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfGeneric;

interface

uses
  System.SysUtils;

function sysconfGeneric(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfPosix,
  Vendor.Github.Com.Tklauser.GoSysconf.Constants;

const
  _BC_BASE_MAX      = 99;
  _BC_DIM_MAX       = 2048;
  _BC_SCALE_MAX     = 99;
  _BC_STRING_MAX    = 1000;
  _COLL_WEIGHTS_MAX = 2;
  _EXPR_NEST_MAX    = 32;
  _LINE_MAX         = 2048;
  _RE_DUP_MAX       = 255;

function sysconfGeneric(name: Integer): Int64;
var
  sc: Int64;
begin
  // POSIX default values
  try
    sc := sysconfPOSIX(name);
    if sc <> -1 then
      Exit(sc);
  except
    // ignore
  end;

  case name of
    SC_BC_BASE_MAX:
      Result := _BC_BASE_MAX;
    SC_BC_DIM_MAX:
      Result := _BC_DIM_MAX;
    SC_BC_SCALE_MAX:
      Result := _BC_SCALE_MAX;
    SC_BC_STRING_MAX:
      Result := _BC_STRING_MAX;
    SC_COLL_WEIGHTS_MAX:
      Result := _COLL_WEIGHTS_MAX;
    SC_EXPR_NEST_MAX:
      Result := _EXPR_NEST_MAX;
    SC_HOST_NAME_MAX:
      Result := 255; // Placeholder for _HOST_NAME_MAX
    SC_LINE_MAX:
      Result := _LINE_MAX;
    SC_LOGIN_NAME_MAX:
      Result := 17; // Placeholder for _LOGIN_NAME_MAX
    SC_PAGESIZE: // same as SC_PAGE_SIZE
      Result := 4096; // Placeholder for os.Getpagesize()
    SC_RE_DUP_MAX:
      Result := _RE_DUP_MAX;
    SC_SYMLOOP_MAX:
      Result := 32; // Placeholder for _SYMLOOP_MAX
  else
    Result := -1;
  end;
end;

end.
