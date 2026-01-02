unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfLinux;

interface

uses
  System.SysUtils;

function sysconf(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfGeneric,
  Vendor.Github.Com.Tklauser.GoSysconf.Constants;

const
  _SYSTEM_CLK_TCK = 100;

function sysconf(name: Integer): Int64;
begin
  case name of
    SC_AIO_LISTIO_MAX:
      Result := -1;
    SC_AIO_MAX:
      Result := -1;
    SC_AIO_PRIO_DELTA_MAX:
      Result := 20; // _AIO_PRIO_DELTA_MAX
    SC_ARG_MAX:
      Result := 131072; // Placeholder for argMax
    SC_ATEXIT_MAX:
      Result := $7FFFFFFF;
    SC_CHILD_MAX:
      Result := -1;
    SC_CLK_TCK:
      Result := _SYSTEM_CLK_TCK;
    SC_DELAYTIMER_MAX:
      Result := 32;
    SC_GETGR_R_SIZE_MAX:
      Result := 1024;
    SC_GETPW_R_SIZE_MAX:
      Result := 1024;
    SC_MQ_OPEN_MAX:
      Result := -1;
    SC_MQ_PRIO_MAX:
      Result := 32768;
    SC_NGROUPS_MAX:
      Result := 65536;
    SC_OPEN_MAX:
      Result := 1024;
    SC_RTSIG_MAX:
      Result := 32;
    SC_SEM_NSEMS_MAX:
      Result := -1;
    SC_SEM_VALUE_MAX:
      Result := $7FFFFFFF;
    SC_SIGQUEUE_MAX:
      Result := 32;
    SC_STREAM_MAX:
      Result := 16;
    SC_THREAD_DESTRUCTOR_ITERATIONS:
      Result := 4;
    SC_THREAD_KEYS_MAX:
      Result := 1024;
    SC_THREAD_PRIO_INHERIT:
      Result := 1;
    SC_THREAD_PRIO_PROTECT:
      Result := 1;
    SC_THREAD_STACK_MIN:
      Result := 16384;
    SC_THREAD_THREADS_MAX:
      Result := -1;
    SC_TIMER_MAX:
      Result := -1;
    SC_TTY_NAME_MAX:
      Result := 32;
    SC_TZNAME_MAX:
      Result := -1;

    SC_CPUTIME:
      Result := 200809;
    SC_MONOTONIC_CLOCK:
      Result := 200809;
    SC_SAVED_IDS:
      Result := 1;
    SC_SPAWN:
      Result := 200809;
    SC_SPIN_LOCKS:
      Result := 200809;
    SC_SPORADIC_SERVER:
      Result := -1;
    SC_SYNCHRONIZED_IO:
      Result := 200809;
    SC_THREAD_ATTR_STACKADDR:
      Result := 200809;
    SC_THREAD_ATTR_STACKSIZE:
      Result := 200809;
    SC_THREAD_CPUTIME:
      Result := 200809;
    SC_THREAD_PRIORITY_SCHEDULING:
      Result := 200809;
    SC_THREAD_PROCESS_SHARED:
      Result := 200809;
    SC_THREAD_SAFE_FUNCTIONS:
      Result := 200809;
    SC_THREAD_SPORADIC_SERVER:
      Result := -1;
    SC_TRACE:
      Result := -1;
    SC_TRACE_EVENT_FILTER:
      Result := -1;
    SC_TRACE_EVENT_NAME_MAX:
      Result := -1;
    SC_TRACE_INHERIT:
      Result := -1;
    SC_TRACE_LOG:
      Result := -1;
    SC_TRACE_NAME_MAX:
      Result := -1;
    SC_TRACE_SYS_MAX:
      Result := -1;
    SC_TRACE_USER_EVENT_MAX:
      Result := -1;
    SC_TYPED_MEMORY_OBJECTS:
      Result := -1;

    SC_V7_ILP32_OFF32, SC_V7_ILP32_OFFBIG, SC_V7_LP64_OFF64, SC_V7_LPBIG_OFFBIG:
      Result := -1;

    SC_V6_ILP32_OFF32, SC_V6_ILP32_OFFBIG, SC_V6_LP64_OFF64, SC_V6_LPBIG_OFFBIG:
      Result := -1;

    SC_2_C_VERSION:
      Result := 200809;
    SC_2_CHAR_TERM:
      Result := 200809;
    SC_2_PBS, SC_2_PBS_ACCOUNTING, SC_2_PBS_CHECKPOINT, SC_2_PBS_LOCATE, SC_2_PBS_MESSAGE, SC_2_PBS_TRACK:
      Result := -1;
    SC_2_UPE:
      Result := -1;

    SC_XOPEN_CRYPT:
      Result := -1;
    SC_XOPEN_ENH_I18N:
      Result := 1;
    SC_XOPEN_REALTIME:
      Result := 1;
    SC_XOPEN_REALTIME_THREADS:
      Result := 1;
    SC_XOPEN_SHM:
      Result := 1;
    SC_XOPEN_STREAMS:
      Result := -1;
    SC_XOPEN_UNIX:
      Result := 1;
    SC_XOPEN_VERSION:
      Result := 700;
    SC_XOPEN_XCU_VERSION:
      Result := 4;

    SC_PHYS_PAGES:
      Result := 0; // Placeholder
    SC_AVPHYS_PAGES:
      Result := 0; // Placeholder
    SC_NPROCESSORS_CONF:
      Result := 1; // Placeholder
    SC_NPROCESSORS_ONLN:
      Result := 1; // Placeholder
    SC_UIO_MAXIOV:
      Result := 1024;
  else
    Result := sysconfGeneric(name);
  end;
end;

end.
