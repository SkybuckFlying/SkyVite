unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfOpenbsd;

interface

uses
  System.SysUtils;

function sysconf(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfBsd,
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfGeneric,
  Vendor.Github.Com.Tklauser.GoSysconf.Constants;

function sysconf(name: Integer): Int64;
begin
  case name of
    SC_AIO_LISTIO_MAX,
    SC_AIO_MAX,
    SC_AIO_PRIO_DELTA_MAX:
      Result := -1;
    SC_ARG_MAX:
      Result := sysctl32('kern.argmax');
    SC_ATEXIT_MAX:
      Result := -1;
    SC_CHILD_MAX:
      Result := -1; // Would need unix.Getrlimit
    SC_CLK_TCK:
      Result := 100; // _CLK_TCK
    SC_DELAYTIMER_MAX:
      Result := -1;
    SC_GETGR_R_SIZE_MAX:
      Result := 2624; // _GR_BUF_LEN
    SC_GETPW_R_SIZE_MAX:
      Result := 1024; // _PW_BUF_LEN
    SC_IOV_MAX:
      Result := 1024; // _IOV_MAX
    SC_LOGIN_NAME_MAX:
      Result := 32; // _LOGIN_NAME_MAX
    SC_NGROUPS_MAX:
      Result := sysctl32('kern.ngroups');
    SC_OPEN_MAX:
      Result := -1; // Would need unix.Getrlimit
    SC_SEM_NSEMS_MAX:
      Result := -1;
    SC_SEM_VALUE_MAX:
      Result := $FFFFFFFF; // _SEM_VALUE_MAX
    SC_SIGQUEUE_MAX:
      Result := -1;
    SC_STREAM_MAX:
      Result := -1; // Would need unix.Getrlimit
    SC_THREAD_DESTRUCTOR_ITERATIONS:
      Result := 4; // _PTHREAD_DESTRUCTOR_ITERATIONS
    SC_THREAD_KEYS_MAX:
      Result := 256; // _PTHREAD_KEYS_MAX
    SC_THREAD_STACK_MIN:
      Result := 4096; // _PTHREAD_STACK_MIN
    SC_THREAD_THREADS_MAX:
      Result := -1;
    SC_TIMER_MAX:
      Result := -1;
    SC_TTY_NAME_MAX:
      Result := 260; // _TTY_NAME_MAX
    SC_TZNAME_MAX:
      Result := 27; // _NAME_MAX

    SC_BARRIERS:
      Result := 200809; // _POSIX_BARRIERS
    SC_FSYNC:
      Result := 200809; // _POSIX_FSYNC
    SC_IPV6:
      Result := 0; // _POSIX_IPV6
    SC_JOB_CONTROL:
      Result := 1; // _POSIX_JOB_CONTROL
    SC_MAPPED_FILES:
      Result := 200809; // _POSIX_MAPPED_FILES
    SC_MONOTONIC_CLOCK:
      Result := 200809; // _POSIX_MONOTONIC_CLOCK
    SC_SAVED_IDS:
      Result := 1; // _POSIX_SAVED_IDS
    SC_SEMAPHORES:
      Result := 200809; // _POSIX_SEMAPHORES
    SC_SPAWN:
      Result := 200809; // _POSIX_SPAWN
    SC_SPIN_LOCKS:
      Result := 200809; // _POSIX_SPIN_LOCKS
    SC_SPORADIC_SERVER:
      Result := -1; // _POSIX_SPORADIC_SERVER
    SC_SYNCHRONIZED_IO:
      Result := -1; // _POSIX_SYNCHRONIZED_IO
    SC_THREAD_ATTR_STACKADDR:
      Result := 200809;
    SC_THREAD_ATTR_STACKSIZE:
      Result := 200809;
    SC_THREAD_CPUTIME:
      Result := 200809;
    SC_THREAD_PRIO_INHERIT:
      Result := -1;
    SC_THREAD_PRIO_PROTECT:
      Result := -1;
    SC_THREAD_PRIORITY_SCHEDULING:
      Result := -1;
    SC_THREAD_PROCESS_SHARED:
      Result := -1;
    SC_THREAD_ROBUST_PRIO_INHERIT:
      Result := -1;
    SC_THREAD_ROBUST_PRIO_PROTECT:
      Result := -1;
    SC_THREAD_SAFE_FUNCTIONS:
      Result := 200809;
    SC_THREAD_SPORADIC_SERVER:
      Result := -1;
    SC_THREADS:
      Result := 200809;
    SC_TIMEOUTS:
      Result := 200809;
    SC_TIMERS:
      Result := -1;
    SC_TRACE,
    SC_TRACE_EVENT_FILTER,
    SC_TRACE_EVENT_NAME_MAX,
    SC_TRACE_INHERIT,
    SC_TRACE_LOG:
      Result := -1; // _POSIX_TRACE
    SC_TYPED_MEMORY_OBJECTS:
      Result := -1;

    SC_V7_ILP32_OFF32:
      Result := -1;
    SC_V7_ILP32_OFFBIG:
      Result := 0;
    SC_V7_LP64_OFF64:
      Result := 0;
    SC_V7_LPBIG_OFFBIG:
      Result := 0;

    SC_V6_ILP32_OFF32:
      Result := -1;
    SC_V6_ILP32_OFFBIG:
      Result := 0;
    SC_V6_LP64_OFF64:
      Result := 0;
    SC_V6_LPBIG_OFFBIG:
      Result := 0;

    SC_2_CHAR_TERM:
      Result := 1;
    SC_2_PBS,
    SC_2_PBS_ACCOUNTING,
    SC_2_PBS_CHECKPOINT,
    SC_2_PBS_LOCATE,
    SC_2_PBS_MESSAGE,
    SC_2_PBS_TRACK:
      Result := -1;
    SC_2_UPE:
      Result := 200809;
    SC_2_VERSION:
      Result := 200809;

    SC_XOPEN_CRYPT:
      Result := 1;
    SC_XOPEN_ENH_I18N:
      Result := -1;
    SC_XOPEN_REALTIME:
      Result := -1;
    SC_XOPEN_REALTIME_THREADS:
      Result := -1;
    SC_XOPEN_SHM:
      Result := 1;
    SC_XOPEN_STREAMS:
      Result := -1;
    SC_XOPEN_UNIX:
      Result := -1;
    SC_XOPEN_UUCP:
      Result := -1;

    SC_AVPHYS_PAGES:
      Result := -1; // Would need unix.SysctlUvmexp
    SC_PHYS_PAGES:
      Result := sysctl64('hw.physmem') div 4096; // Assuming 4096 pagesize
    SC_NPROCESSORS_CONF:
      Result := sysctl32('hw.ncpu');
    SC_NPROCESSORS_ONLN:
      Result := sysctl32('hw.ncpuonline');
  else
    Result := sysconfGeneric(name);
  end;
end;

end.
