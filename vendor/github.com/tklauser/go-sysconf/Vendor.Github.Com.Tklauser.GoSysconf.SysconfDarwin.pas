unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfDarwin;

interface

uses
  System.SysUtils;

function sysconf(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfBsd,
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfGeneric,
  Vendor.Github.Com.Tklauser.GoSysconf.Constants;

const
  _HOST_NAME_MAX  = 255; // _MAXHOSTNAMELEN - 1
  _LOGIN_NAME_MAX = 17;  // _MAXLOGNAME
  _SYMLOOP_MAX    = 32;  // _MAXSYMLINKS

function sysconf(name: Integer): Int64;
begin
  case name of
    SC_AIO_LISTIO_MAX,
    SC_AIO_MAX:
      Result := sysctl32('kern.aiomax');
    SC_AIO_PRIO_DELTA_MAX:
      Result := -1;
    SC_ARG_MAX:
      Result := sysctl32('kern.argmax');
    SC_ATEXIT_MAX:
      Result := $7FFFFFFF; // _INT_MAX
    SC_CHILD_MAX:
      Result := -1; // Would need Getrlimit
    SC_CLK_TCK:
      Result := 100; // _CLK_TCK
    SC_DELAYTIMER_MAX:
      Result := -1;
    SC_GETGR_R_SIZE_MAX:
      Result := 4096;
    SC_GETPW_R_SIZE_MAX:
      Result := 4096;
    SC_IOV_MAX:
      Result := 1024; // _IOV_MAX
    SC_MQ_OPEN_MAX:
      Result := -1;
    SC_MQ_PRIO_MAX:
      Result := -1;
    SC_NGROUPS_MAX:
      Result := sysctl32('kern.ngroups');
    SC_OPEN_MAX, SC_STREAM_MAX:
      Result := -1; // Would need Getrlimit
    SC_RTSIG_MAX:
      Result := -1;
    SC_SEM_NSEMS_MAX:
      Result := sysctl32('kern.sysv.semmns');
    SC_SEM_VALUE_MAX:
      Result := 32767; // _POSIX_SEM_VALUE_MAX
    SC_SIGQUEUE_MAX:
      Result := -1;
    SC_THREAD_DESTRUCTOR_ITERATIONS:
      Result := 4; // _PTHREAD_DESTRUCTOR_ITERATIONS
    SC_THREAD_KEYS_MAX:
      Result := 128; // _PTHREAD_KEYS_MAX
    SC_THREAD_PRIO_INHERIT:
      Result := 1; // _POSIX_THREAD_PRIO_INHERIT
    SC_THREAD_PRIO_PROTECT:
      Result := 1; // _POSIX_THREAD_PRIO_PROTECT
    SC_THREAD_STACK_MIN:
      Result := 8192; // _PTHREAD_STACK_MIN
    SC_THREAD_THREADS_MAX:
      Result := -1;
    SC_TIMER_MAX:
      Result := -1;
    SC_TTY_NAME_MAX:
      Result := pathconf('/', 0); // _PC_NAME_MAX
    SC_TZNAME_MAX:
      Result := pathconf('/usr/share/zoneinfo', 0); // _PC_NAME_MAX

    SC_IPV6:
      Result := 200112; // _POSIX_IPV6
    SC_MESSAGE_PASSING:
      Result := yesno(sysctl32('p1003_1b.message_passing'));
    SC_PRIORITIZED_IO:
      Result := yesno(sysctl32('p1003_1b.prioritized_io'));
    SC_PRIORITY_SCHEDULING:
      Result := yesno(sysctl32('p1003_1b.priority_scheduling'));
    SC_REALTIME_SIGNALS:
      Result := yesno(sysctl32('p1003_1b.realtime_signals'));
    SC_SAVED_IDS:
      Result := yesno(sysctl32('kern.saved_ids'));
    SC_SEMAPHORES:
      Result := yesno(sysctl32('p1003_1b.semaphores'));
    SC_SPAWN:
      Result := 200112; // _POSIX_SPAWN
    SC_SPIN_LOCKS:
      Result := 200112; // _POSIX_SPIN_LOCKS
    SC_SPORADIC_SERVER:
      Result := -1; // _POSIX_SPORADIC_SERVER
    SC_SS_REPL_MAX:
      Result := -1; // _POSIX_SS_REPL_MAX
    SC_SYNCHRONIZED_IO:
      Result := yesno(sysctl32('p1003_1b.synchronized_io'));
    SC_THREAD_ATTR_STACKADDR:
      Result := 200112;
    SC_THREAD_ATTR_STACKSIZE:
      Result := 200112;
    SC_THREAD_CPUTIME:
      Result := -1;
    SC_THREAD_PRIORITY_SCHEDULING:
      Result := 200112;
    SC_THREAD_PROCESS_SHARED:
      Result := 200112;
    SC_THREAD_SAFE_FUNCTIONS:
      Result := 200112;
    SC_THREAD_SPORADIC_SERVER:
      Result := -1;
    SC_TIMERS:
      Result := yesno(sysctl32('p1003_1b.timers'));
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
    SC_VERSION:
      Result := 200112; // _POSIX_VERSION

    SC_V6_ILP32_OFF32:
      Result := -1;
    SC_V6_ILP32_OFFBIG:
      Result := -1;
    SC_V6_LP64_OFF64:
      Result := 1;
    SC_V6_LPBIG_OFFBIG:
      Result := 1;

    SC_2_CHAR_TERM:
      Result := 200112;
    SC_2_PBS,
    SC_2_PBS_ACCOUNTING,
    SC_2_PBS_CHECKPOINT,
    SC_2_PBS_LOCATE,
    SC_2_PBS_MESSAGE,
    SC_2_PBS_TRACK:
      Result := -1;
    SC_2_UPE:
      Result := 200112;

    SC_XOPEN_CRYPT:
      Result := 1;
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
      Result := 600;
    SC_XOPEN_XCU_VERSION:
      Result := 4;

    SC_PHYS_PAGES:
      Result := sysctl64('hw.memsize') div 4096; // Assuming 4096 pagesize
    SC_NPROCESSORS_CONF,
    SC_NPROCESSORS_ONLN:
      Result := sysctl32('hw.ncpu');
  else
    Result := sysconfGeneric(name);
  end;
end;

end.
