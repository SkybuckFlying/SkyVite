unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfPosix;

interface

uses
  System.SysUtils;

function sysconfPOSIX(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.Constants;

function sysconfPOSIX(name: Integer): Int64;
begin
  case name of
    SC_ADVISORY_INFO:
      Result := 200809; // _POSIX_ADVISORY_INFO
    SC_ASYNCHRONOUS_IO:
      Result := 200809; // _POSIX_ASYNCHRONOUS_IO
    SC_BARRIERS:
      Result := 200809; // _POSIX_BARRIERS
    SC_CLOCK_SELECTION:
      Result := 200809; // _POSIX_CLOCK_SELECTION
    SC_CPUTIME:
      Result := 200809; // _POSIX_CPUTIME
    SC_FSYNC:
      Result := 200809; // _POSIX_FSYNC
    SC_IPV6:
      Result := 200809; // _POSIX_IPV6
    SC_JOB_CONTROL:
      Result := 200809; // _POSIX_JOB_CONTROL
    SC_MAPPED_FILES:
      Result := 200809; // _POSIX_MAPPED_FILES
    SC_MEMLOCK:
      Result := 200809; // _POSIX_MEMLOCK
    SC_MEMLOCK_RANGE:
      Result := 200809; // _POSIX_MEMLOCK_RANGE
    SC_MONOTONIC_CLOCK:
      Result := 200809; // _POSIX_MONOTONIC_CLOCK
    SC_MEMORY_PROTECTION:
      Result := 200809; // _POSIX_MEMORY_PROTECTION
    SC_MESSAGE_PASSING:
      Result := 200809; // _POSIX_MESSAGE_PASSING
    SC_PRIORITIZED_IO:
      Result := 200809; // _POSIX_PRIORITIZED_IO
    SC_PRIORITY_SCHEDULING:
      Result := 200809; // _POSIX_PRIORITY_SCHEDULING
    SC_RAW_SOCKETS:
      Result := 200809; // _POSIX_RAW_SOCKETS
    SC_READER_WRITER_LOCKS:
      Result := 200809; // _POSIX_READER_WRITER_LOCKS
    SC_REALTIME_SIGNALS:
      Result := 200809; // _POSIX_REALTIME_SIGNALS
    SC_REGEXP:
      Result := 200809; // _POSIX_REGEXP
    SC_SEMAPHORES:
      Result := 200809; // _POSIX_SEMAPHORES
    SC_SHARED_MEMORY_OBJECTS:
      Result := 200809; // _POSIX_SHARED_MEMORY_OBJECTS
    SC_SHELL:
      Result := 200809; // _POSIX_SHELL
    SC_THREADS:
      Result := 200809; // _POSIX_THREADS
    SC_TIMEOUTS:
      Result := 200809; // _POSIX_TIMEOUTS
    SC_TIMERS:
      Result := 200809; // _POSIX_TIMERS
    SC_VERSION:
      Result := 200809; // _POSIX_VERSION

    SC_2_C_BIND:
      Result := 200809; // _POSIX2_C_BIND
    SC_2_C_DEV:
      Result := 200809; // _POSIX2_C_DEV
    SC_2_FORT_DEV:
      Result := -1;
    SC_2_FORT_RUN:
      Result := -1;
    SC_2_LOCALEDEF:
      Result := 200809; // _POSIX2_LOCALEDEF
    SC_2_SW_DEV:
      Result := 200809; // _POSIX2_SW_DEV
    SC_2_VERSION:
      Result := 200809; // _POSIX2_VERSION
  else
    Result := -1;
  end;
end;

end.
