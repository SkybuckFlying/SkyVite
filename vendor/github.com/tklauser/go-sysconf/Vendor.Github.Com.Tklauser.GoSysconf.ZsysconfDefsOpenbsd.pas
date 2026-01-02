unit Vendor.Github.Com.Tklauser.GoSysconf.ZsysconfDefsOpenbsd;

interface

const
  SC_AIO_LISTIO_MAX               = $2A;
  SC_AIO_MAX                      = $2B;
  SC_AIO_PRIO_DELTA_MAX           = $2C;
  SC_ARG_MAX                      = $1;
  SC_ATEXIT_MAX                   = $2E;
  SC_BC_BASE_MAX                  = $9;
  SC_BC_DIM_MAX                   = $A;
  SC_BC_SCALE_MAX                 = $B;
  SC_BC_STRING_MAX                = $C;
  SC_CHILD_MAX                    = $2;
  SC_CLK_TCK                      = $3;
  SC_COLL_WEIGHTS_MAX             = $D;
  SC_DELAYTIMER_MAX               = $32;
  SC_EXPR_NEST_MAX                = $E;
  SC_GETGR_R_SIZE_MAX             = $64;
  SC_GETPW_R_SIZE_MAX             = $65;
  SC_HOST_NAME_MAX                = $21;
  SC_IOV_MAX                      = $33;
  SC_LINE_MAX                     = $F;
  SC_LOGIN_NAME_MAX               = $66;
  SC_MQ_OPEN_MAX                  = $3A;
  SC_MQ_PRIO_MAX                  = $3B;
  SC_NGROUPS_MAX                  = $4;
  SC_OPEN_MAX                     = $5;
  SC_PAGE_SIZE                    = $1C;
  SC_PAGESIZE                     = $1C;
  SC_THREAD_DESTRUCTOR_ITERATIONS = $50;
  SC_THREAD_KEYS_MAX              = $51;
  SC_THREAD_STACK_MIN             = $59;
  SC_THREAD_THREADS_MAX           = $5A;
  SC_RE_DUP_MAX                   = $10;
  SC_SEM_NSEMS_MAX                = $1F;
  SC_SEM_VALUE_MAX                = $20;
  SC_SIGQUEUE_MAX                 = $46;
  SC_STREAM_MAX                   = $1A;
  SC_SYMLOOP_MAX                  = $4C;
  SC_TIMER_MAX                    = $5D;
  SC_TTY_NAME_MAX                 = $6B;
  SC_TZNAME_MAX                   = $1B;

  SC_ADVISORY_INFO              = $29;
  SC_ASYNCHRONOUS_IO            = $2D;
  SC_BARRIERS                   = $2F;
  SC_CLOCK_SELECTION            = $30;
  SC_CPUTIME                    = $31;
  SC_FSYNC                      = $1D;
  SC_IPV6                       = $34;
  SC_JOB_CONTROL                = $6;
  SC_MAPPED_FILES               = $35;
  SC_MEMLOCK                    = $36;
  SC_MEMLOCK_RANGE              = $37;
  SC_MEMORY_PROTECTION          = $38;
  SC_MESSAGE_PASSING            = $39;
  SC_MONOTONIC_CLOCK            = $22;
  SC_PRIORITIZED_IO             = $3C;
  SC_PRIORITY_SCHEDULING        = $3D;
  SC_RAW_SOCKETS                = $3E;
  SC_READER_WRITER_LOCKS        = $3F;
  SC_REALTIME_SIGNALS           = $40;
  SC_REGEXP                     = $41;
  SC_SAVED_IDS                  = $7;
  SC_SEMAPHORES                 = $43;
  SC_SHARED_MEMORY_OBJECTS      = $44;
  SC_SHELL                      = $45;
  SC_SPAWN                      = $47;
  SC_SPIN_LOCKS                 = $48;
  SC_SPORADIC_SERVER            = $49;
  SC_SS_REPL_MAX                = $4A;
  SC_SYNCHRONIZED_IO            = $4B;
  SC_THREAD_ATTR_STACKADDR      = $4D;
  SC_THREAD_ATTR_STACKSIZE      = $4E;
  SC_THREAD_CPUTIME             = $4F;
  SC_THREAD_PRIO_INHERIT        = $52;
  SC_THREAD_PRIO_PROTECT        = $53;
  SC_THREAD_PRIORITY_SCHEDULING = $54;
  SC_THREAD_PROCESS_SHARED      = $55;
  SC_THREAD_ROBUST_PRIO_INHERIT = $56;
  SC_THREAD_ROBUST_PRIO_PROTECT = $57;
  SC_THREAD_SAFE_FUNCTIONS      = $67;
  SC_THREAD_SPORADIC_SERVER     = $58;
  SC_THREADS                    = $5B;
  SC_TIMEOUTS                   = $5C;
  SC_TIMERS                     = $5E;
  SC_TRACE                      = $5F;
  SC_TRACE_EVENT_FILTER         = $60;
  SC_TRACE_EVENT_NAME_MAX       = $61;
  SC_TRACE_INHERIT              = $62;
  SC_TRACE_LOG                  = $63;
  SC_TRACE_NAME_MAX             = $68;
  SC_TRACE_SYS_MAX              = $69;
  SC_TRACE_USER_EVENT_MAX       = $6A;
  SC_TYPED_MEMORY_OBJECTS       = $6C;
  SC_VERSION                    = $8;

  SC_V7_ILP32_OFF32  = $71;
  SC_V7_ILP32_OFFBIG = $72;
  SC_V7_LP64_OFF64   = $73;
  SC_V7_LPBIG_OFFBIG = $74;

  SC_V6_ILP32_OFF32  = $6D;
  SC_V6_ILP32_OFFBIG = $6E;
  SC_V6_LP64_OFF64   = $6F;
  SC_V6_LPBIG_OFFBIG = $70;

  SC_2_C_BIND         = $12;
  SC_2_C_DEV          = $13;
  SC_2_CHAR_TERM      = $14;
  SC_2_FORT_DEV       = $15;
  SC_2_FORT_RUN       = $16;
  SC_2_LOCALEDEF      = $17;
  SC_2_PBS            = $23;
  SC_2_PBS_ACCOUNTING = $24;
  SC_2_PBS_CHECKPOINT = $25;
  SC_2_PBS_LOCATE     = $26;
  SC_2_PBS_MESSAGE    = $27;
  SC_2_PBS_TRACK      = $28;
  SC_2_SW_DEV         = $18;
  SC_2_UPE            = $19;
  SC_2_VERSION        = $11;

  SC_XOPEN_CRYPT            = $75;
  SC_XOPEN_ENH_I18N         = $76;
  SC_XOPEN_REALTIME         = $78;
  SC_XOPEN_REALTIME_THREADS = $79;
  SC_XOPEN_SHM              = $1E;
  SC_XOPEN_STREAMS          = $7A;
  SC_XOPEN_UNIX             = $7B;
  SC_XOPEN_UUCP             = $7C;
  SC_XOPEN_VERSION          = $7D;

  SC_AVPHYS_PAGES     = $1F5;
  SC_PHYS_PAGES       = $1F4;
  SC_NPROCESSORS_CONF = $1F6;
  SC_NPROCESSORS_ONLN = $1F7;

implementation

end.
