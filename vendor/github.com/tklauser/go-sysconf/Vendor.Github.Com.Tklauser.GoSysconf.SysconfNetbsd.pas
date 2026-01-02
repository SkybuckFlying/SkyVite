unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfNetbsd;

interface

uses
  System.SysUtils, System.SyncObjs;

function sysconf(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfBsd,
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfGeneric,
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfPosix,
  Vendor.Github.Com.Tklauser.GoSysconf.Constants;

const
  _HOST_NAME_MAX  = 255; // Placeholder
  _LOGIN_NAME_MAX = 17;  // Placeholder
  _SYMLOOP_MAX    = 32;

  _POSIX2_C_DEV = -1;
  _POSIX2_UPE   = -1;

var
  clktck: Int64;
  clktckOnce: TMultiReadExclusiveWriteSynchronizer; // Using a sync object instead of sync.Once

function sysconfPOSIX_local(name: Integer): Int64;
begin
  case name of
    SC_SHELL:
      Result := 1; // _POSIX_SHELL
    SC_VERSION:
      Result := 200112; // _POSIX_VERSION
  else
    Result := -1;
  end;
end;

function sysconf(name: Integer): Int64;
begin
  switch name {
	case SC_ARG_MAX:
		return sysctl32("kern.argmax"), nil
	case SC_CHILD_MAX:
		var rlim unix.Rlimit
		if err := unix.Getrlimit(unix.RLIMIT_NPROC, &rlim); err == nil {
			if rlim.Cur != unix.RLIM_INFINITY {
				return int64(rlim.Cur), nil
			}
		}
		return -1, nil
	case SC_STREAM_MAX:
		// sysctl("user.stream_max")
		return _FOPEN_MAX, nil
	case SC_TTY_NAME_MAX:
		return pathconf(_PATH_DEV, _PC_NAME_MAX), nil
	case SC_CLK_TCK:
		clktckOnce.Do(func() {
			clktck = -1
			if ci, err := unix.SysctlClockinfo("kern.clockrate"); err == nil {
				clktck = int64(ci.Hz)
			}
		})
		return clktck, nil
	case SC_NGROUPS_MAX:
		return sysctl32("kern.ngroups"), nil
	case SC_JOB_CONTROL:
		return sysctl32("kern.job_control"), nil
	case SC_OPEN_MAX:
		var rlim unix.Rlimit
		if err := unix.Getrlimit(unix.RLIMIT_NOFILE, &rlim); err == nil {
			return int64(rlim.Cur), nil
		}
		return -1, nil
	case SC_TZNAME_MAX:
		// sysctl("user.tzname_max")
		return _NAME_MAX, nil

	// 1003.1b
	case SC_FSYNC:
		return sysctl32("kern.fsync"), nil
	case SC_MAPPED_FILES:
		return sysctl32("kern.mapped_files"), nil
	case SC_MONOTONIC_CLOCK:
		return sysctl32("kern.monotonic_clock"), nil
	case SC_SEMAPHORES:
		return sysctl32("kern.posix_semaphores"), nil
	case SC_TIMERS:
		return sysctl32("kern.posix_timers"), nil

	// 1003.1c
	case SC_LOGIN_NAME_MAX:
		return sysctl32("kern.login_name_max"), nil
	case SC_THREADS:
		return sysctl32("kern.posix_threads"), nil

	// 1003.1j
	case SC_BARRIERS:
		return sysctl32("kern.posix_barriers"), nil

	// 1003.2
	case SC_2_VERSION:
		// sysctl("user.posix2_version")
		return _POSIX2_VERSION, nil
	case SC_2_UPE:
		// sysctl("user.posix2_upe")
		return _POSIX2_UPE, nil

	// XPG 4.2
	case SC_IOV_MAX:
		return sysctl32("kern.iov_max"), nil

	// 1003.1-2001, XSI Option Group
	case SC_AIO_LISTIO_MAX:
		return sysctl32("kern.aio_listio_max"), nil
	case SC_AIO_MAX:
		return sysctl32("kern.aio_max"), nil
	case SC_ASYNCHRONOUS_IO:
		return sysctl32("kern.posix_aio"), nil
	case SC_MQ_OPEN_MAX:
		return sysctl32("kern.mqueue.mq_open_max"), nil
	case SC_MQ_PRIO_MAX:
		return sysctl32("kern.mqueue.mq_prio_max"), nil
	case SC_ATEXIT_MAX:
		// sysctl("user.atexit_max")
		return -1, nil // TODO

	// Extensions
	case SC_NPROCESSORS_CONF:
		return sysctl32("hw.ncpu"), nil
	case SC_NPROCESSORS_ONLN:
		return sysctl32("hw.ncpuonline"), nil

	// Linux/Solaris
	case SC_PHYS_PAGES:
		return sysctl64("hw.physmem64") / int64(unix.Getpagesize()), nil

	// Native
	case SC_THREAD_DESTRUCTOR_ITERATIONS:
		return _POSIX_THREAD_DESTRUCTOR_ITERATIONS, nil
	case SC_THREAD_KEYS_MAX:
		return _POSIX_THREAD_KEYS_MAX, nil
	case SC_THREAD_STACK_MIN:
		return int64(unix.Getpagesize()), nil
	case SC_THREAD_THREADS_MAX:
		return sysctl32("kern.maxproc"), nil
	}
  case name of
    SC_ARG_MAX:
      Result := sysctl32('kern.argmax');
    SC_CHILD_MAX:
      Result := -1;
    SC_STREAM_MAX:
      Result := 20; // _FOPEN_MAX
    SC_TTY_NAME_MAX:
      Result := pathconf('/dev', 0);
    SC_CLK_TCK:
      Result := clktck; // Needs initialization
    SC_NGROUPS_MAX:
      Result := sysctl32('kern.ngroups');
    SC_JOB_CONTROL:
      Result := sysctl32('kern.job_control');
    SC_OPEN_MAX:
      Result := -1;
    SC_TZNAME_MAX:
      Result := 255; // _NAME_MAX

    SC_FSYNC:
      Result := sysctl32('kern.fsync');
    SC_MAPPED_FILES:
      Result := sysctl32('kern.mapped_files');
    SC_MONOTONIC_CLOCK:
      Result := sysctl32('kern.monotonic_clock');
    SC_SEMAPHORES:
      Result := sysctl32('kern.posix_semaphores');
    SC_TIMERS:
      Result := sysctl32('kern.posix_timers');

    SC_LOGIN_NAME_MAX:
      Result := sysctl32('kern.login_name_max');
    SC_THREADS:
      Result := sysctl32('kern.posix_threads');

    SC_BARRIERS:
      Result := sysctl32('kern.posix_barriers');

    SC_2_VERSION:
      Result := 200112; // _POSIX2_VERSION
    SC_2_UPE:
      Result := _POSIX2_UPE;

    SC_IOV_MAX:
      Result := sysctl32('kern.iov_max');

    SC_AIO_LISTIO_MAX:
      Result := sysctl32('kern.aio_listio_max');
    SC_AIO_MAX:
      Result := sysctl32('kern.aio_max');
    SC_ASYNCHRONOUS_IO:
      Result := sysctl32('kern.posix_aio');
    SC_MQ_OPEN_MAX:
      Result := sysctl32('kern.mqueue.mq_open_max');
    SC_MQ_PRIO_MAX:
      Result := sysctl32('kern.mqueue.mq_prio_max');
    SC_ATEXIT_MAX:
      Result := -1;

    SC_NPROCESSORS_CONF:
      Result := sysctl32('hw.ncpu');
    SC_NPROCESSORS_ONLN:
      Result := sysctl32('hw.ncpuonline');

    SC_PHYS_PAGES:
      Result := sysctl64('hw.physmem64') div 4096;

    SC_THREAD_DESTRUCTOR_ITERATIONS:
      Result := 4;
    SC_THREAD_KEYS_MAX:
      Result := 256;
    SC_THREAD_STACK_MIN:
      Result := 4096;
    SC_THREAD_THREADS_MAX:
      Result := sysctl32('kern.maxproc');
  else
    Result := sysconfGeneric(name);
  end;
end;

initialization
  clktckOnce := TMultiReadExclusiveWriteSynchronizer.Create;
  clktck := 100; // Default

finalization
  clktckOnce.Free;

end.
