unit Vendor.Github.Com.Tklauser.GoSysconf.ZsysconfDefsLinux;

interface

const
  SC_AIO_LISTIO_MAX               = $17;
  SC_AIO_MAX                      = $18;
  SC_AIO_PRIO_DELTA_MAX           = $19;
  SC_ARG_MAX                      = $0;
  SC_ATEXIT_MAX                   = $57;
  SC_BC_BASE_MAX                  = $24;
  SC_BC_DIM_MAX                   = $25;
  SC_BC_SCALE_MAX                 = $26;
  SC_BC_STRING_MAX                = $27;
  SC_CHILD_MAX                    = $1;
  SC_CLK_TCK                      = $2;
  SC_COLL_WEIGHTS_MAX             = $28;
  SC_DELAYTIMER_MAX               = $1A;
  SC_EXPR_NEST_MAX                = $2A;
  SC_GETGR_R_SIZE_MAX             = $45;
  SC_GETPW_R_SIZE_MAX             = $46;
  SC_HOST_NAME_MAX                = $B4;
  SC_IOV_MAX                      = $3C;
  SC_LINE_MAX                     = $2B;
  SC_LOGIN_NAME_MAX               = $47;
  SC_MQ_OPEN_MAX                  = $1B;
  SC_MQ_PRIO_MAX                  = $1C;
  SC_NGROUPS_MAX                  = $3;
  SC_OPEN_MAX                     = $4;
  SC_PAGE_SIZE                    = $1E;
  SC_PAGESIZE                     = $1E;
  SC_THREAD_DESTRUCTOR_ITERATIONS = $49;
  SC_THREAD_KEYS_MAX              = $4A;
  SC_THREAD_STACK_MIN             = $4B;
  SC_THREAD_THREADS_MAX           = $4C;
  SC_RE_DUP_MAX                   = $2C;
  SC_RTSIG_MAX                    = $1F;
  SC_SEM_NSEMS_MAX                = $20;
  SC_SEM_VALUE_MAX                = $21;
  SC_SIGQUEUE_MAX                 = $22;
  SC_STREAM_MAX                   = $5;
  SC_SYMLOOP_MAX                  = $AD;
  SC_TIMER_MAX                    = $23;
  SC_TTY_NAME_MAX                 = $48;
  SC_TZNAME_MAX                   = $6;

  SC_ADVISORY_INFO              = $84;
  SC_ASYNCHRONOUS_IO            = $0C;
  SC_BARRIERS                   = $85;
  SC_CLOCK_SELECTION            = $89;
  SC_CPUTIME                    = $8A;
  SC_FSYNC                      = $0F;
  SC_IPV6                       = $EB;
  SC_JOB_CONTROL                = $7;
  SC_MAPPED_FILES               = $10;
  SC_MEMLOCK                    = $11;
  SC_MEMLOCK_RANGE              = $12;
  SC_MEMORY_PROTECTION          = $13;
  SC_MESSAGE_PASSING            = $14;
  SC_MONOTONIC_CLOCK            = $95;
  SC_PRIORITIZED_IO             = $0D;
  SC_PRIORITY_SCHEDULING        = $0A;
  SC_RAW_SOCKETS                = $EC;
  SC_READER_WRITER_LOCKS        = $99;
  SC_REALTIME_SIGNALS           = $9;
  SC_REGEXP                     = $9B;
  SC_SAVED_IDS                  = $8;
  SC_SEMAPHORES                 = $15;
  SC_SHARED_MEMORY_OBJECTS      = $16;
  SC_SHELL                      = $9D;
  SC_SPAWN                      = $9F;
  SC_SPIN_LOCKS                 = $9A;
  SC_SPORADIC_SERVER            = $A0;
  SC_SS_REPL_MAX                = $F1;
  SC_SYNCHRONIZED_IO            = $0E;
  SC_THREAD_ATTR_STACKADDR      = $4D;
  SC_THREAD_ATTR_STACKSIZE      = $4E;
  SC_THREAD_CPUTIME             = $8B;
  SC_THREAD_PRIO_INHERIT        = $50;
  SC_THREAD_PRIO_PROTECT        = $51;
  SC_THREAD_PRIORITY_SCHEDULING = $4F;
  SC_THREAD_PROCESS_SHARED      = $52;
  SC_THREAD_ROBUST_PRIO_INHERIT = $F7;
  SC_THREAD_ROBUST_PRIO_PROTECT = $F8;
  SC_THREAD_SAFE_FUNCTIONS      = $44;
  SC_THREAD_SPORADIC_SERVER     = $A1;
  SC_THREADS                    = $43;
  SC_TIMEOUTS                   = $A4;
  SC_TIMERS                     = $0B;
  SC_TRACE                      = $B5;
  SC_TRACE_EVENT_FILTER         = $B6;
  SC_TRACE_EVENT_NAME_MAX       = $F2;
  SC_TRACE_INHERIT              = $B7;
  SC_TRACE_LOG                  = $B8;
  SC_TRACE_NAME_MAX             = $F3;
  SC_TRACE_SYS_MAX              = $F4;
  SC_TRACE_USER_EVENT_MAX       = $F5;
  SC_TYPED_MEMORY_OBJECTS       = $A5;
  SC_VERSION                    = $1D;

  SC_V7_ILP32_OFF32  = $ED;
  SC_V7_ILP32_OFFBIG = $EE;
  SC_V7_LP64_OFF64   = $EF;
  SC_V7_LPBIG_OFFBIG = $F0;

  SC_V6_ILP32_OFF32  = $B0;
  SC_V6_ILP32_OFFBIG = $B1;
  SC_V6_LP64_OFF64   = $B2;
  SC_V6_LPBIG_OFFBIG = $B3;

  SC_2_C_BIND         = $2F;
  SC_2_C_DEV          = $30;
  SC_2_C_VERSION      = $60;
  SC_2_CHAR_TERM      = $5F;
  SC_2_FORT_DEV       = $31;
  SC_2_FORT_RUN       = $32;
  SC_2_LOCALEDEF      = $34;
  SC_2_PBS            = $A8;
  SC_2_PBS_ACCOUNTING = $A9;
  SC_2_PBS_CHECKPOINT = $AF;
  SC_2_PBS_LOCATE     = $AA;
  SC_2_PBS_MESSAGE    = $AB;
  SC_2_PBS_TRACK      = $AC;
  SC_2_SW_DEV         = $33;
  SC_2_UPE            = $61;
  SC_2_VERSION        = $2E;

  SC_XOPEN_CRYPT            = $5C;
  SC_XOPEN_ENH_I18N         = $5D;
  SC_XOPEN_REALTIME         = $82;
  SC_XOPEN_REALTIME_THREADS = $83;
  SC_XOPEN_SHM              = $5E;
  SC_XOPEN_STREAMS          = $F6;
  SC_XOPEN_UNIX             = $5B;
  SC_XOPEN_VERSION          = $59;
  SC_XOPEN_XCU_VERSION      = $5A;

  SC_PHYS_PAGES       = $55;
  SC_AVPHYS_PAGES     = $56;
  SC_NPROCESSORS_CONF = $53;
  SC_NPROCESSORS_ONLN = $54;
  SC_UIO_MAXIOV       = $3C;

implementation

end.
