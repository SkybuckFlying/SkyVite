unit Vendor.Github.Com.Tklauser.GoSysconf.ZsysconfDefsSolaris;

interface

const
  SC_AIO_LISTIO_MAX               = $12;
  SC_AIO_MAX                      = $13;
  SC_AIO_PRIO_DELTA_MAX           = $14;
  SC_ARG_MAX                      = $1;
  SC_ATEXIT_MAX                   = $4C;
  SC_BC_BASE_MAX                  = $36;
  SC_BC_DIM_MAX                   = $37;
  SC_BC_SCALE_MAX                 = $38;
  SC_BC_STRING_MAX                = $39;
  SC_CHILD_MAX                    = $2;
  SC_CLK_TCK                      = $3;
  SC_COLL_WEIGHTS_MAX             = $3A;
  SC_DELAYTIMER_MAX               = $16;
  SC_EXPR_NEST_MAX                = $3B;
  SC_GETGR_R_SIZE_MAX             = $239;
  SC_GETPW_R_SIZE_MAX             = $23A;
  SC_HOST_NAME_MAX                = $2DF;
  SC_IOV_MAX                      = $4D;
  SC_LINE_MAX                     = $3C;
  SC_LOGIN_NAME_MAX               = $23B;
  SC_MQ_OPEN_MAX                  = $1D;
  SC_MQ_PRIO_MAX                  = $1E;
  SC_NGROUPS_MAX                  = $4;
  SC_OPEN_MAX                     = $5;
  SC_PAGE_SIZE                    = $B;
  SC_PAGESIZE                     = $B;
  SC_THREAD_DESTRUCTOR_ITERATIONS = $238;
  SC_THREAD_KEYS_MAX              = $23C;
  SC_THREAD_STACK_MIN             = $23D;
  SC_THREAD_THREADS_MAX           = $23E;
  SC_RE_DUP_MAX                   = $3D;
  SC_RTSIG_MAX                    = $22;
  SC_SEM_NSEMS_MAX                = $24;
  SC_SEM_VALUE_MAX                = $25;
  SC_SIGQUEUE_MAX                 = $27;
  SC_STREAM_MAX                   = $10;
  SC_SYMLOOP_MAX                  = $2E8;
  SC_TIMER_MAX                    = $2C;
  SC_TTY_NAME_MAX                 = $23F;
  SC_TZNAME_MAX                   = $11;

  SC_ADVISORY_INFO              = $2DB;
  SC_ASYNCHRONOUS_IO            = $15;
  SC_BARRIERS                   = $2DC;
  SC_CLOCK_SELECTION            = $2DD;
  SC_CPUTIME                    = $2DE;
  SC_FSYNC                      = $17;
  SC_IPV6                       = $2FA;
  SC_JOB_CONTROL                = $6;
  SC_MAPPED_FILES               = $18;
  SC_MEMLOCK                    = $19;
  SC_MEMLOCK_RANGE              = $1A;
  SC_MEMORY_PROTECTION          = $1B;
  SC_MESSAGE_PASSING            = $1C;
  SC_MONOTONIC_CLOCK            = $2E0;
  SC_PRIORITIZED_IO             = $1F;
  SC_PRIORITY_SCHEDULING        = $20;
  SC_RAW_SOCKETS                = $2FB;
  SC_READER_WRITER_LOCKS        = $2E1;
  SC_REALTIME_SIGNALS           = $21;
  SC_REGEXP                     = $2E2;
  SC_SAVED_IDS                  = $7;
  SC_SEMAPHORES                 = $23;
  SC_SHARED_MEMORY_OBJECTS      = $26;
  SC_SHELL                      = $2E3;
  SC_SPAWN                      = $2E4;
  SC_SPIN_LOCKS                 = $2E5;
  SC_SPORADIC_SERVER            = $2E6;
  SC_SS_REPL_MAX                = $2E7;
  SC_SYNCHRONIZED_IO            = $2A;
  SC_THREAD_ATTR_STACKADDR      = $241;
  SC_THREAD_ATTR_STACKSIZE      = $242;
  SC_THREAD_CPUTIME             = $2E9;
  SC_THREAD_PRIO_INHERIT        = $244;
  SC_THREAD_PRIO_PROTECT        = $245;
  SC_THREAD_PRIORITY_SCHEDULING = $243;
  SC_THREAD_PROCESS_SHARED      = $246;
  SC_THREAD_SAFE_FUNCTIONS      = $247;
  SC_THREAD_SPORADIC_SERVER     = $2EA;
  SC_THREADS                    = $240;
  SC_TIMEOUTS                   = $2EB;
  SC_TIMERS                     = $2B;
  SC_TRACE                      = $2EC;
  SC_TRACE_EVENT_FILTER         = $2ED;
  SC_TRACE_EVENT_NAME_MAX       = $2EE;
  SC_TRACE_INHERIT              = $2EF;
  SC_TRACE_LOG                  = $2F0;
  SC_TRACE_NAME_MAX             = $2F1;
  SC_TRACE_SYS_MAX              = $2F2;
  SC_TRACE_USER_EVENT_MAX       = $2F3;
  SC_TYPED_MEMORY_OBJECTS       = $2F4;
  SC_VERSION                    = $8;

  SC_V6_ILP32_OFF32  = $2F5;
  SC_V6_ILP32_OFFBIG = $2F6;
  SC_V6_LP64_OFF64   = $2F7;
  SC_V6_LPBIG_OFFBIG = $2F8;

  SC_2_C_BIND         = $2D;
  SC_2_C_DEV          = $2E;
  SC_2_C_VERSION      = $2F;
  SC_2_CHAR_TERM      = $42;
  SC_2_FORT_DEV       = $30;
  SC_2_FORT_RUN       = $31;
  SC_2_LOCALEDEF      = $32;
  SC_2_PBS            = $2D4;
  SC_2_PBS_ACCOUNTING = $2D5;
  SC_2_PBS_CHECKPOINT = $2D6;
  SC_2_PBS_LOCATE     = $2D8;
  SC_2_PBS_MESSAGE    = $2D9;
  SC_2_PBS_TRACK      = $2DA;
  SC_2_SW_DEV         = $33;
  SC_2_UPE            = $34;
  SC_2_VERSION        = $35;

  SC_XOPEN_CRYPT            = $3E;
  SC_XOPEN_ENH_I18N         = $3F;
  SC_XOPEN_REALTIME         = $2CE;
  SC_XOPEN_REALTIME_THREADS = $2CF;
  SC_XOPEN_SHM              = $40;
  SC_XOPEN_STREAMS          = $2F9;
  SC_XOPEN_UNIX             = $4E;
  SC_XOPEN_VERSION          = $C;
  SC_XOPEN_XCU_VERSION      = $43;

  SC_PHYS_PAGES       = $1F4;
  SC_AVPHYS_PAGES     = $1F5;
  SC_NPROCESSORS_CONF = $E;
  SC_NPROCESSORS_ONLN = $F;

implementation

end.