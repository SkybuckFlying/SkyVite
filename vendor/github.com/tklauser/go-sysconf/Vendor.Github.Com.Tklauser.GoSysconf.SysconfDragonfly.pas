unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfDragonfly;

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
    SC_AIO_LISTIO_MAX:
      Result := sysctl32('p1003_1b.aio_listio_max');
    SC_AIO_MAX:
      Result := sysctl32('p1003_1b.aio_max');
    SC_AIO_PRIO_DELTA_MAX:
      Result := sysctl32('p1003_1b.aio_prio_delta_max');
    SC_ARG_MAX:
      Result := sysctl32('kern.argmax');
    SC_ATEXIT_MAX:
      Result := 32; // _ATEXIT_SIZE
    SC_CHILD_MAX:
      Result := -1;
    SC_CLK_TCK:
      Result := 100; // _CLK_TCK
    SC_DELAYTIMER_MAX:
      Result := yesno(sysctl32('p1003_1b.delaytimer_max'));
    SC_GETGR_R_SIZE_MAX, SC_GETPW_R_SIZE_MAX:
      Result := -1;
    SC_IOV_MAX:
      Result := sysctl32('kern.iov_max');
    SC_MQ_OPEN_MAX:
      Result := sysctl32('kern.mqueue.mq_open_max');
    SC_MQ_PRIO_MAX:
      Result := sysctl32('kern.mqueue.mq_prio_max');
    SC_NGROUPS_MAX:
      Result := sysctl32('kern.ngroups');
    SC_OPEN_MAX:
      Result := -1;
    SC_RTSIG_MAX:
      Result := yesno(sysctl32('p1003_1b.rtsig_max'));
    SC_SEM_NSEMS_MAX:
      Result := -1;
    SC_SEM_VALUE_MAX:
      Result := -1;
    SC_SIGQUEUE_MAX:
      Result := yesno(sysctl32('p1003_1b.sigqueue_max'));
    SC_STREAM_MAX:
      Result := -1;
    SC_THREAD_DESTRUCTOR_ITERATIONS:
      Result := 4;
    SC_THREAD_KEYS_MAX:
      Result := 256;
    SC_THREAD_PRIO_INHERIT:
      Result := 200112;
    SC_THREAD_PRIO_PROTECT:
      Result := 200112;
    SC_THREAD_STACK_MIN:
      Result := 1024;
    SC_THREAD_THREADS_MAX:
      Result := -1;
    SC_TIMER_MAX:
      Result := yesno(sysctl32('p1003_1b.timer_max'));
    SC_TTY_NAME_MAX:
      Result := pathconf('/dev', 0);
    SC_TZNAME_MAX:
      Result := pathconf('/usr/share/zoneinfo', 0);

    SC_ASYNCHRONOUS_IO:
      Result := sysctl64('p1003_1b.asynchronous_io');
    SC_IPV6:
      Result := 200112;
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
      Result := 200112;
    SC_SPIN_LOCKS:
      Result := 200112;
    SC_SPORADIC_SERVER:
      Result := -1;
    SC_SYNCHRONIZED_IO:
      Result := yesno(sysctl32('p1003_1b.synchronized_io'));
    SC_THREAD_ATTR_STACKADDR:
      Result := 200112;
    SC_THREAD_ATTR_STACKSIZE:
      Result := 200112;
    SC_THREAD_CPUTIME:
      Result := 200112;
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
    SC_TYPED_MEMORY_OBJECTS:
      Result := 200112;
    SC_VERSION:
      Result := 200112;

    SC_2_CHAR_TERM:
      Result := 200112;
    SC_2_PBS,
    SC_2_PBS_ACCOUNTING,
    SC_2_PBS_CHECKPOINT,
    SC_2_PBS_LOCATE,
    SC_2_PBS_MESSAGE,
    SC_2_PBS_TRACK:
      Result := 200112;
    SC_2_UPE:
      Result := 200112;

    SC_XOPEN_CRYPT:
      Result := 600;
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

    SC_PHYS_PAGES:
      Result := sysctl64('hw.availpages');
    SC_NPROCESSORS_CONF,
    SC_NPROCESSORS_ONLN:
      Result := sysctl32('hw.ncpu');
  else
    Result := sysconfGeneric(name);
  end;
end;

end.
