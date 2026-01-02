unit Vendor.Golang.Org.X.Sys.Unix.ZsyscallDarwinAmd64;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Sys.Unix.Types; // Assuming types are here

type
  // Placeholder types if not available in Types unit
  PGid_t = Pointer;
  PC_int = Pointer;
  PRusage = Pointer;
  PRawSockaddrAny = Pointer;
  PSocklen = Pointer;
  PMsghdr = Pointer;
  PTimespec = Pointer;
  PTimeval = Pointer;
  PPollFd = Pointer;
  PRlimit = Pointer;
  PFdSet = Pointer;
  PStat_t = Pointer;
  PStatfs_t = Pointer;

// Exported functions
function Wait4(ParaPid: Integer; ParaWstatus: PC_int; ParaOptions: Integer; ParaRusage: PRusage; out ParaWpid: Integer; out ParaErr: Integer): Boolean;
function Accept(ParaS: Integer; ParaRsa: PRawSockaddrAny; ParaAddrlen: PSocklen; out ParaFd: Integer; out ParaErr: Integer): Boolean;
function Bind(ParaS: Integer; ParaAddr: Pointer; ParaAddrlen: Integer; out ParaErr: Integer): Boolean;
function Connect(ParaS: Integer; ParaAddr: Pointer; ParaAddrlen: Integer; out ParaErr: Integer): Boolean;
function Socket(ParaDomain: Integer; ParaTyp: Integer; ParaProto: Integer; out ParaFd: Integer; out ParaErr: Integer): Boolean;
function Getsockopt(ParaS: Integer; ParaLevel: Integer; ParaName: Integer; ParaVal: Pointer; ParaVallen: PSocklen; out ParaErr: Integer): Boolean;
function Setsockopt(ParaS: Integer; ParaLevel: Integer; ParaName: Integer; ParaVal: Pointer; ParaVallen: Integer; out ParaErr: Integer): Boolean;
function Getpeername(ParaFd: Integer; ParaRsa: PRawSockaddrAny; ParaAddrlen: PSocklen; out ParaErr: Integer): Boolean;
function Getsockname(ParaFd: Integer; ParaRsa: PRawSockaddrAny; ParaAddrlen: PSocklen; out ParaErr: Integer): Boolean;
function Shutdown(ParaS: Integer; ParaHow: Integer; out ParaErr: Integer): Boolean;
function Socketpair(ParaDomain: Integer; ParaTyp: Integer; ParaProto: Integer; ParaFd: Pointer; out ParaErr: Integer): Boolean;
function Recvfrom(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; ParaFlags: Integer; ParaFrom: PRawSockaddrAny; ParaFromlen: PSocklen; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Sendto(ParaS: Integer; ParaBuf: Pointer; ParaLen: Integer; ParaFlags: Integer; ParaTo: Pointer; ParaAddrlen: Integer; out ParaErr: Integer): Boolean;
function Recvmsg(ParaS: Integer; ParaMsg: PMsghdr; ParaFlags: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Sendmsg(ParaS: Integer; ParaMsg: PMsghdr; ParaFlags: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Kevent(ParaKq: Integer; ParaChange: Pointer; ParaNchange: Integer; ParaEvent: Pointer; ParaNevent: Integer; ParaTimeout: PTimespec; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Utimes(ParaPath: string; ParaTimeval: PTimeval; out ParaErr: Integer): Boolean;
function Futimes(ParaFd: Integer; ParaTimeval: PTimeval; out ParaErr: Integer): Boolean;
function Poll(ParaFds: PPollFd; ParaNfds: Integer; ParaTimeout: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Madvise(ParaB: Pointer; ParaLen: Integer; ParaBehav: Integer; out ParaErr: Integer): Boolean;
function Mlock(ParaB: Pointer; ParaLen: Integer; out ParaErr: Integer): Boolean;
function Mlockall(ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Mprotect(ParaB: Pointer; ParaLen: Integer; ParaProt: Integer; out ParaErr: Integer): Boolean;
function Msync(ParaB: Pointer; ParaLen: Integer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Munlock(ParaB: Pointer; ParaLen: Integer; out ParaErr: Integer): Boolean;
function Munlockall(out ParaErr: Integer): Boolean;
function Pipe(ParaP: Pointer; out ParaErr: Integer): Boolean; // p is *[2]int32
function Getxattr(ParaPath: string; ParaAttr: string; ParaDest: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
function Fgetxattr(ParaFd: Integer; ParaAttr: string; ParaDest: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
function Setxattr(ParaPath: string; ParaAttr: string; ParaData: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaErr: Integer): Boolean;
function Fsetxattr(ParaFd: Integer; ParaAttr: string; ParaData: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaErr: Integer): Boolean;
function Removexattr(ParaPath: string; ParaAttr: string; ParaOptions: Integer; out ParaErr: Integer): Boolean;
function Fremovexattr(ParaFd: Integer; ParaAttr: string; ParaOptions: Integer; out ParaErr: Integer): Boolean;
function Listxattr(ParaPath: string; ParaDest: Pointer; ParaSize: Integer; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
function Flistxattr(ParaFd: Integer; ParaDest: Pointer; ParaSize: Integer; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
function Setattrlist(ParaPath: string; ParaList: Pointer; ParaBuf: Pointer; ParaSize: UIntPtr; ParaOptions: Integer; out ParaErr: Integer): Boolean;
function Fcntl(ParaFd: Integer; ParaCmd: Integer; ParaArg: Integer; out ParaVal: Integer; out ParaErr: Integer): Boolean;
function Kill(ParaPid: Integer; ParaSignum: Integer; ParaPosix: Integer; out ParaErr: Integer): Boolean;
function Ioctl(ParaFd: Integer; ParaReq: Cardinal; ParaArg: UIntPtr; out ParaErr: Integer): Boolean;
function Sysctl(ParaMib: Pointer; ParaMibLen: Integer; ParaOld: Pointer; ParaOldlen: UIntPtr; ParaNew: Pointer; ParaNewlen: UIntPtr; out ParaErr: Integer): Boolean;
function Sendfile(ParaInfd: Integer; ParaOutfd: Integer; ParaOffset: Int64; ParaLen: PInt64; ParaHdtr: Pointer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Access(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
function Adjtime(ParaDelta: PTimeval; ParaOlddelta: PTimeval; out ParaErr: Integer): Boolean;
function Chdir(ParaPath: string; out ParaErr: Integer): Boolean;
function Chflags(ParaPath: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Chmod(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
function Chown(ParaPath: string; ParaUid: Integer; ParaGid: Integer; out ParaErr: Integer): Boolean;
function Chroot(ParaPath: string; out ParaErr: Integer): Boolean;
function ClockGettime(ParaClockid: Integer; ParaTime: PTimespec; out ParaErr: Integer): Boolean;
function Close(ParaFd: Integer; out ParaErr: Integer): Boolean;
function Clonefile(ParaSrc: string; ParaDst: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Clonefileat(ParaSrcDirfd: Integer; ParaSrc: string; ParaDstDirfd: Integer; ParaDst: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Dup(ParaFd: Integer; out ParaNfd: Integer; out ParaErr: Integer): Boolean;
function Dup2(ParaFrom: Integer; ParaTo: Integer; out ParaErr: Integer): Boolean;
function Exchangedata(ParaPath1: string; ParaPath2: string; ParaOptions: Integer; out ParaErr: Integer): Boolean;
procedure Exit(ParaCode: Integer);
function Faccessat(ParaDirfd: Integer; ParaPath: string; ParaMode: Cardinal; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Fchdir(ParaFd: Integer; out ParaErr: Integer): Boolean;
function Fchflags(ParaFd: Integer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Fchmod(ParaFd: Integer; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
function Fchmodat(ParaDirfd: Integer; ParaPath: string; ParaMode: Cardinal; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Fchown(ParaFd: Integer; ParaUid: Integer; ParaGid: Integer; out ParaErr: Integer): Boolean;
function Fchownat(ParaDirfd: Integer; ParaPath: string; ParaUid: Integer; ParaGid: Integer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Fclonefileat(ParaSrcDirfd: Integer; ParaDstDirfd: Integer; ParaDst: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Flock(ParaFd: Integer; ParaHow: Integer; out ParaErr: Integer): Boolean;
function Fpathconf(ParaFd: Integer; ParaName: Integer; out ParaVal: Integer; out ParaErr: Integer): Boolean;
function Fsync(ParaFd: Integer; out ParaErr: Integer): Boolean;
function Ftruncate(ParaFd: Integer; ParaLength: Int64; out ParaErr: Integer): Boolean;
function Getcwd(ParaBuf: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Getdtablesize: Integer;
function Getegid: Integer;
function Geteuid: Integer;
function Getgid: Integer;
function Getpgid(ParaPid: Integer; out ParaPgid: Integer; out ParaErr: Integer): Boolean;
function Getpgrp: Integer;
function Getpid: Integer;
function Getppid: Integer;
function Getpriority(ParaWhich: Integer; ParaWho: Integer; out ParaPrio: Integer; out ParaErr: Integer): Boolean;
function Getrlimit(ParaWhich: Integer; ParaLim: PRlimit; out ParaErr: Integer): Boolean;
function Getrusage(ParaWho: Integer; ParaRusage: PRusage; out ParaErr: Integer): Boolean;
function Getsid(ParaPid: Integer; out ParaSid: Integer; out ParaErr: Integer): Boolean;
function Gettimeofday(ParaTp: PTimeval; out ParaErr: Integer): Boolean;
function Getuid: Integer;
function Issetugid: Boolean;
function Kqueue(out ParaFd: Integer; out ParaErr: Integer): Boolean;
function Lchown(ParaPath: string; ParaUid: Integer; ParaGid: Integer; out ParaErr: Integer): Boolean;
function Link(ParaPath: string; ParaLink: string; out ParaErr: Integer): Boolean;
function Linkat(ParaPathfd: Integer; ParaPath: string; ParaLinkfd: Integer; ParaLink: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Listen(ParaS: Integer; ParaBacklog: Integer; out ParaErr: Integer): Boolean;
function Mkdir(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
function Mkdirat(ParaDirfd: Integer; ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
function Mkfifo(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
function Mknod(ParaPath: string; ParaMode: Cardinal; ParaDev: Integer; out ParaErr: Integer): Boolean;
function Open(ParaPath: string; ParaMode: Integer; ParaPerm: Cardinal; out ParaFd: Integer; out ParaErr: Integer): Boolean;
function Openat(ParaDirfd: Integer; ParaPath: string; ParaMode: Integer; ParaPerm: Cardinal; out ParaFd: Integer; out ParaErr: Integer): Boolean;
function Pathconf(ParaPath: string; ParaName: Integer; out ParaVal: Integer; out ParaErr: Integer): Boolean;
function Pread(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; ParaOffset: Int64; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Pwrite(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; ParaOffset: Int64; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Read(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Readlink(ParaPath: string; ParaBuf: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Readlinkat(ParaDirfd: Integer; ParaPath: string; ParaBuf: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Rename(ParaFrom: string; ParaTo: string; out ParaErr: Integer): Boolean;
function Renameat(ParaFromfd: Integer; ParaFrom: string; ParaTofd: Integer; ParaTo: string; out ParaErr: Integer): Boolean;
function Revoke(ParaPath: string; out ParaErr: Integer): Boolean;
function Rmdir(ParaPath: string; out ParaErr: Integer): Boolean;
function Seek(ParaFd: Integer; ParaOffset: Int64; ParaWhence: Integer; out ParaNewoffset: Int64; out ParaErr: Integer): Boolean;
function Select(ParaNfd: Integer; ParaR: PFdSet; ParaW: PFdSet; ParaE: PFdSet; ParaTimeout: PTimeval; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Setegid(ParaEgid: Integer; out ParaErr: Integer): Boolean;
function Seteuid(ParaEuid: Integer; out ParaErr: Integer): Boolean;
function Setgid(ParaGid: Integer; out ParaErr: Integer): Boolean;
function Setlogin(ParaName: string; out ParaErr: Integer): Boolean;
function Setpgid(ParaPid: Integer; ParaPgid: Integer; out ParaErr: Integer): Boolean;
function Setpriority(ParaWhich: Integer; ParaWho: Integer; ParaPrio: Integer; out ParaErr: Integer): Boolean;
function Setprivexec(ParaFlag: Integer; out ParaErr: Integer): Boolean;
function Setregid(ParaRgid: Integer; ParaEgid: Integer; out ParaErr: Integer): Boolean;
function Setreuid(ParaRuid: Integer; ParaEuid: Integer; out ParaErr: Integer): Boolean;
function Setrlimit(ParaWhich: Integer; ParaLim: PRlimit; out ParaErr: Integer): Boolean;
function Setsid(out ParaPid: Integer; out ParaErr: Integer): Boolean;
function Settimeofday(ParaTp: PTimeval; out ParaErr: Integer): Boolean;
function Setuid(ParaUid: Integer; out ParaErr: Integer): Boolean;
function Symlink(ParaPath: string; ParaLink: string; out ParaErr: Integer): Boolean;
function Symlinkat(ParaOldpath: string; ParaNewdirfd: Integer; ParaNewpath: string; out ParaErr: Integer): Boolean;
function Sync(out ParaErr: Integer): Boolean;
function Truncate(ParaPath: string; ParaLength: Int64; out ParaErr: Integer): Boolean;
function Umask(ParaNewmask: Integer): Integer;
function Undelete(ParaPath: string; out ParaErr: Integer): Boolean;
function Unlink(ParaPath: string; out ParaErr: Integer): Boolean;
function Unlinkat(ParaDirfd: Integer; ParaPath: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Unmount(ParaPath: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Write(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Mmap(ParaAddr: UIntPtr; ParaLength: UIntPtr; ParaProt: Integer; ParaFlag: Integer; ParaFd: Integer; ParaPos: Int64; out ParaRet: UIntPtr; out ParaErr: Integer): Boolean;
function Munmap(ParaAddr: UIntPtr; ParaLength: UIntPtr; out ParaErr: Integer): Boolean;
function Readlen(ParaFd: Integer; ParaBuf: Pointer; ParaNbuf: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Writelen(ParaFd: Integer; ParaBuf: Pointer; ParaNbuf: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Fstat(ParaFd: Integer; ParaStat: PStat_t; out ParaErr: Integer): Boolean;
function Fstatat(ParaFd: Integer; ParaPath: string; ParaStat: PStat_t; ParaFlags: Integer; out ParaErr: Integer): Boolean;
function Fstatfs(ParaFd: Integer; ParaStat: PStatfs_t; out ParaErr: Integer): Boolean;
function Getfsstat(ParaBuf: Pointer; ParaSize: UIntPtr; ParaFlags: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
function Lstat(ParaPath: string; ParaStat: PStat_t; out ParaErr: Integer): Boolean;
function Ptrace1(ParaRequest: Integer; ParaPid: Integer; ParaAddr: UIntPtr; ParaData: UIntPtr; out ParaErr: Integer): Boolean;
function Stat(ParaPath: string; ParaStat: PStat_t; out ParaErr: Integer): Boolean;
function Statfs(ParaPath: string; ParaStat: PStatfs_t; out ParaErr: Integer): Boolean;

// Unexported functions (also available for internal use if needed)
function getgroups(ParaNgid: Integer; ParaGid: PGid_t; out ParaN: Integer; out ParaErr: Integer): Boolean;
function setgroups(ParaNgid: Integer; ParaGid: PGid_t; out ParaErr: Integer): Boolean;

implementation

const
  libSystem = '/usr/lib/libSystem.B.dylib';

// Helper for errno
function GetErrno: Integer;
begin
{$IFDEF MSWINDOWS}
  Result := GetLastOSError;
{$ELSE}
  Result := GetLastOSError; // FPC/Unix uses this too or fpGetErrno
{$ENDIF}
end;

// Helper for string
function PCharFromStr(const s: string): PAnsiChar;
begin
  Result := PAnsiChar(UTF8String(s));
end;

// External C Declarations
function libc_getgroups(ngid: Integer; gid: PGid_t): Integer; cdecl; external libSystem name 'getgroups';
function libc_setgroups(ngid: Integer; gid: PGid_t): Integer; cdecl; external libSystem name 'setgroups';
function libc_wait4(pid: Integer; wstatus: PC_int; options: Integer; rusage: PRusage): Integer; cdecl; external libSystem name 'wait4';
function libc_accept(s: Integer; rsa: PRawSockaddrAny; addrlen: PSocklen): Integer; cdecl; external libSystem name 'accept';
function libc_bind(s: Integer; addr: Pointer; addrlen: Integer): Integer; cdecl; external libSystem name 'bind';
function libc_connect(s: Integer; addr: Pointer; addrlen: Integer): Integer; cdecl; external libSystem name 'connect';
function libc_socket(domain: Integer; typ: Integer; proto: Integer): Integer; cdecl; external libSystem name 'socket';
function libc_getsockopt(s: Integer; level: Integer; name: Integer; val: Pointer; vallen: PSocklen): Integer; cdecl; external libSystem name 'getsockopt';
function libc_setsockopt(s: Integer; level: Integer; name: Integer; val: Pointer; vallen: Integer): Integer; cdecl; external libSystem name 'setsockopt';
function libc_getpeername(fd: Integer; rsa: PRawSockaddrAny; addrlen: PSocklen): Integer; cdecl; external libSystem name 'getpeername';
function libc_getsockname(fd: Integer; rsa: PRawSockaddrAny; addrlen: PSocklen): Integer; cdecl; external libSystem name 'getsockname';
function libc_shutdown(s: Integer; how: Integer): Integer; cdecl; external libSystem name 'shutdown';
function libc_socketpair(domain: Integer; typ: Integer; proto: Integer; fd: Pointer): Integer; cdecl; external libSystem name 'socketpair';
function libc_recvfrom(fd: Integer; p: Pointer; len: Integer; flags: Integer; from: PRawSockaddrAny; fromlen: PSocklen): Integer; cdecl; external libSystem name 'recvfrom';
function libc_sendto(s: Integer; buf: Pointer; len: Integer; flags: Integer; to_: Pointer; addrlen: Integer): Integer; cdecl; external libSystem name 'sendto';
function libc_recvmsg(s: Integer; msg: PMsghdr; flags: Integer): Integer; cdecl; external libSystem name 'recvmsg';
function libc_sendmsg(s: Integer; msg: PMsghdr; flags: Integer): Integer; cdecl; external libSystem name 'sendmsg';
function libc_kevent(kq: Integer; change: Pointer; nchange: Integer; event: Pointer; nevent: Integer; timeout: PTimespec): Integer; cdecl; external libSystem name 'kevent';
function libc_utimes(path: PAnsiChar; timeval: PTimeval): Integer; cdecl; external libSystem name 'utimes';
function libc_futimes(fd: Integer; timeval: PTimeval): Integer; cdecl; external libSystem name 'futimes';
function libc_poll(fds: PPollFd; nfds: Integer; timeout: Integer): Integer; cdecl; external libSystem name 'poll';
function libc_madvise(b: Pointer; len: Integer; behav: Integer): Integer; cdecl; external libSystem name 'madvise';
function libc_mlock(b: Pointer; len: Integer): Integer; cdecl; external libSystem name 'mlock';
function libc_mlockall(flags: Integer): Integer; cdecl; external libSystem name 'mlockall';
function libc_mprotect(b: Pointer; len: Integer; prot: Integer): Integer; cdecl; external libSystem name 'mprotect';
function libc_msync(b: Pointer; len: Integer; flags: Integer): Integer; cdecl; external libSystem name 'msync';
function libc_munlock(b: Pointer; len: Integer): Integer; cdecl; external libSystem name 'munlock';
function libc_munlockall: Integer; cdecl; external libSystem name 'munlockall';
function libc_pipe(p: Pointer): Integer; cdecl; external libSystem name 'pipe';
function libc_getxattr(path: PAnsiChar; attr: PAnsiChar; dest: Pointer; size: Integer; position: Cardinal; options: Integer): Integer; cdecl; external libSystem name 'getxattr';
function libc_fgetxattr(fd: Integer; attr: PAnsiChar; dest: Pointer; size: Integer; position: Cardinal; options: Integer): Integer; cdecl; external libSystem name 'fgetxattr';
function libc_setxattr(path: PAnsiChar; attr: PAnsiChar; data: Pointer; size: Integer; position: Cardinal; options: Integer): Integer; cdecl; external libSystem name 'setxattr';
function libc_fsetxattr(fd: Integer; attr: PAnsiChar; data: Pointer; size: Integer; position: Cardinal; options: Integer): Integer; cdecl; external libSystem name 'fsetxattr';
function libc_removexattr(path: PAnsiChar; attr: PAnsiChar; options: Integer): Integer; cdecl; external libSystem name 'removexattr';
function libc_fremovexattr(fd: Integer; attr: PAnsiChar; options: Integer): Integer; cdecl; external libSystem name 'fremovexattr';
function libc_listxattr(path: PAnsiChar; dest: Pointer; size: Integer; options: Integer): Integer; cdecl; external libSystem name 'listxattr';
function libc_flistxattr(fd: Integer; dest: Pointer; size: Integer; options: Integer): Integer; cdecl; external libSystem name 'flistxattr';
function libc_setattrlist(path: PAnsiChar; list: Pointer; buf: Pointer; size: UIntPtr; options: Integer): Integer; cdecl; external libSystem name 'setattrlist';
function libc_fcntl(fd: Integer; cmd: Integer; arg: Integer): Integer; cdecl; external libSystem name 'fcntl';
function libc_kill(pid: Integer; signum: Integer; posix: Integer): Integer; cdecl; external libSystem name 'kill';
function libc_ioctl(fd: Integer; req: Cardinal; arg: UIntPtr): Integer; cdecl; external libSystem name 'ioctl';
function libc_sysctl(mib: Pointer; miblen: Integer; old: Pointer; oldlen: UIntPtr; new: Pointer; newlen: UIntPtr): Integer; cdecl; external libSystem name 'sysctl';
function libc_sendfile(infd: Integer; outfd: Integer; offset: Int64; len: PInt64; hdtr: Pointer; flags: Integer): Integer; cdecl; external libSystem name 'sendfile';
function libc_access(path: PAnsiChar; mode: Cardinal): Integer; cdecl; external libSystem name 'access';
function libc_adjtime(delta: PTimeval; olddelta: PTimeval): Integer; cdecl; external libSystem name 'adjtime';
function libc_chdir(path: PAnsiChar): Integer; cdecl; external libSystem name 'chdir';
function libc_chflags(path: PAnsiChar; flags: Integer): Integer; cdecl; external libSystem name 'chflags';
function libc_chmod(path: PAnsiChar; mode: Cardinal): Integer; cdecl; external libSystem name 'chmod';
function libc_chown(path: PAnsiChar; uid: Integer; gid: Integer): Integer; cdecl; external libSystem name 'chown';
function libc_chroot(path: PAnsiChar): Integer; cdecl; external libSystem name 'chroot';
function libc_clock_gettime(clockid: Integer; time: PTimespec): Integer; cdecl; external libSystem name 'clock_gettime';
function libc_close(fd: Integer): Integer; cdecl; external libSystem name 'close';
function libc_clonefile(src: PAnsiChar; dst: PAnsiChar; flags: Integer): Integer; cdecl; external libSystem name 'clonefile';
function libc_clonefileat(srcDirfd: Integer; src: PAnsiChar; dstDirfd: Integer; dst: PAnsiChar; flags: Integer): Integer; cdecl; external libSystem name 'clonefileat';
function libc_dup(fd: Integer): Integer; cdecl; external libSystem name 'dup';
function libc_dup2(from: Integer; to_: Integer): Integer; cdecl; external libSystem name 'dup2';
function libc_exchangedata(path1: PAnsiChar; path2: PAnsiChar; options: Integer): Integer; cdecl; external libSystem name 'exchangedata';
procedure libc_exit(code: Integer); cdecl; external libSystem name 'exit';
function libc_faccessat(dirfd: Integer; path: PAnsiChar; mode: Cardinal; flags: Integer): Integer; cdecl; external libSystem name 'faccessat';
function libc_fchdir(fd: Integer): Integer; cdecl; external libSystem name 'fchdir';
function libc_fchflags(fd: Integer; flags: Integer): Integer; cdecl; external libSystem name 'fchflags';
function libc_fchmod(fd: Integer; mode: Cardinal): Integer; cdecl; external libSystem name 'fchmod';
function libc_fchmodat(dirfd: Integer; path: PAnsiChar; mode: Cardinal; flags: Integer): Integer; cdecl; external libSystem name 'fchmodat';
function libc_fchown(fd: Integer; uid: Integer; gid: Integer): Integer; cdecl; external libSystem name 'fchown';
function libc_fchownat(dirfd: Integer; path: PAnsiChar; uid: Integer; gid: Integer; flags: Integer): Integer; cdecl; external libSystem name 'fchownat';
function libc_fclonefileat(srcDirfd: Integer; dstDirfd: Integer; dst: PAnsiChar; flags: Integer): Integer; cdecl; external libSystem name 'fclonefileat';
function libc_flock(fd: Integer; how: Integer): Integer; cdecl; external libSystem name 'flock';
function libc_fpathconf(fd: Integer; name: Integer): Integer; cdecl; external libSystem name 'fpathconf';
function libc_fsync(fd: Integer): Integer; cdecl; external libSystem name 'fsync';
function libc_ftruncate(fd: Integer; length: Int64): Integer; cdecl; external libSystem name 'ftruncate';
function libc_getcwd(buf: Pointer; len: Integer): Integer; cdecl; external libSystem name 'getcwd';
function libc_getdtablesize: Integer; cdecl; external libSystem name 'getdtablesize';
function libc_getegid: Integer; cdecl; external libSystem name 'getegid';
function libc_geteuid: Integer; cdecl; external libSystem name 'geteuid';
function libc_getgid: Integer; cdecl; external libSystem name 'getgid';
function libc_getpgid(pid: Integer): Integer; cdecl; external libSystem name 'getpgid';
function libc_getpgrp: Integer; cdecl; external libSystem name 'getpgrp';
function libc_getpid: Integer; cdecl; external libSystem name 'getpid';
function libc_getppid: Integer; cdecl; external libSystem name 'getppid';
function libc_getpriority(which: Integer; who: Integer): Integer; cdecl; external libSystem name 'getpriority';
function libc_getrlimit(which: Integer; lim: PRlimit): Integer; cdecl; external libSystem name 'getrlimit';
function libc_getrusage(who: Integer; rusage: PRusage): Integer; cdecl; external libSystem name 'getrusage';
function libc_getsid(pid: Integer): Integer; cdecl; external libSystem name 'getsid';
function libc_gettimeofday(tp: PTimeval; tzp: Pointer): Integer; cdecl; external libSystem name 'gettimeofday'; // tzp is ignored in wrappers usually
function libc_getuid: Integer; cdecl; external libSystem name 'getuid';
function libc_issetugid: Integer; cdecl; external libSystem name 'issetugid';
function libc_kqueue: Integer; cdecl; external libSystem name 'kqueue';
function libc_lchown(path: PAnsiChar; uid: Integer; gid: Integer): Integer; cdecl; external libSystem name 'lchown';
function libc_link(path: PAnsiChar; link: PAnsiChar): Integer; cdecl; external libSystem name 'link';
function libc_linkat(pathfd: Integer; path: PAnsiChar; linkfd: Integer; link: PAnsiChar; flags: Integer): Integer; cdecl; external libSystem name 'linkat';
function libc_listen(s: Integer; backlog: Integer): Integer; cdecl; external libSystem name 'listen';
function libc_mkdir(path: PAnsiChar; mode: Cardinal): Integer; cdecl; external libSystem name 'mkdir';
function libc_mkdirat(dirfd: Integer; path: PAnsiChar; mode: Cardinal): Integer; cdecl; external libSystem name 'mkdirat';
function libc_mkfifo(path: PAnsiChar; mode: Cardinal): Integer; cdecl; external libSystem name 'mkfifo';
function libc_mknod(path: PAnsiChar; mode: Cardinal; dev: Integer): Integer; cdecl; external libSystem name 'mknod';
function libc_open(path: PAnsiChar; mode: Integer; perm: Cardinal): Integer; cdecl; external libSystem name 'open';
function libc_openat(dirfd: Integer; path: PAnsiChar; mode: Integer; perm: Cardinal): Integer; cdecl; external libSystem name 'openat';
function libc_pathconf(path: PAnsiChar; name: Integer): Integer; cdecl; external libSystem name 'pathconf';
function libc_pread(fd: Integer; p: Pointer; len: Integer; offset: Int64): Integer; cdecl; external libSystem name 'pread';
function libc_pwrite(fd: Integer; p: Pointer; len: Integer; offset: Int64): Integer; cdecl; external libSystem name 'pwrite';
function libc_read(fd: Integer; p: Pointer; len: Integer): Integer; cdecl; external libSystem name 'read';
function libc_readlink(path: PAnsiChar; buf: Pointer; len: Integer): Integer; cdecl; external libSystem name 'readlink';
function libc_readlinkat(dirfd: Integer; path: PAnsiChar; buf: Pointer; len: Integer): Integer; cdecl; external libSystem name 'readlinkat';
function libc_rename(from: PAnsiChar; to_: PAnsiChar): Integer; cdecl; external libSystem name 'rename';
function libc_renameat(fromfd: Integer; from: PAnsiChar; tofd: Integer; to_: PAnsiChar): Integer; cdecl; external libSystem name 'renameat';
function libc_revoke(path: PAnsiChar): Integer; cdecl; external libSystem name 'revoke';
function libc_rmdir(path: PAnsiChar): Integer; cdecl; external libSystem name 'rmdir';
function libc_lseek(fd: Integer; offset: Int64; whence: Integer): Int64; cdecl; external libSystem name 'lseek';
function libc_select(nfd: Integer; r: PFdSet; w: PFdSet; e: PFdSet; timeout: PTimeval): Integer; cdecl; external libSystem name 'select';
function libc_setegid(egid: Integer): Integer; cdecl; external libSystem name 'setegid';
function libc_seteuid(euid: Integer): Integer; cdecl; external libSystem name 'seteuid';
function libc_setgid(gid: Integer): Integer; cdecl; external libSystem name 'setgid';
function libc_setlogin(name: PAnsiChar): Integer; cdecl; external libSystem name 'setlogin';
function libc_setpgid(pid: Integer; pgid: Integer): Integer; cdecl; external libSystem name 'setpgid';
function libc_setpriority(which: Integer; who: Integer; prio: Integer): Integer; cdecl; external libSystem name 'setpriority';
function libc_setprivexec(flag: Integer): Integer; cdecl; external libSystem name 'setprivexec';
function libc_setregid(rgid: Integer; egid: Integer): Integer; cdecl; external libSystem name 'setregid';
function libc_setreuid(ruid: Integer; euid: Integer): Integer; cdecl; external libSystem name 'setreuid';
function libc_setrlimit(which: Integer; lim: PRlimit): Integer; cdecl; external libSystem name 'setrlimit';
function libc_setsid: Integer; cdecl; external libSystem name 'setsid';
function libc_settimeofday(tp: PTimeval; tzp: Pointer): Integer; cdecl; external libSystem name 'settimeofday';
function libc_setuid(uid: Integer): Integer; cdecl; external libSystem name 'setuid';
function libc_symlink(path: PAnsiChar; link: PAnsiChar): Integer; cdecl; external libSystem name 'symlink';
function libc_symlinkat(oldpath: PAnsiChar; newdirfd: Integer; newpath: PAnsiChar): Integer; cdecl; external libSystem name 'symlinkat';
function libc_sync: Integer; cdecl; external libSystem name 'sync';
function libc_truncate(path: PAnsiChar; length: Int64): Integer; cdecl; external libSystem name 'truncate';
function libc_umask(newmask: Integer): Integer; cdecl; external libSystem name 'umask';
function libc_undelete(path: PAnsiChar): Integer; cdecl; external libSystem name 'undelete';
function libc_unlink(path: PAnsiChar): Integer; cdecl; external libSystem name 'unlink';
function libc_unlinkat(dirfd: Integer; path: PAnsiChar; flags: Integer): Integer; cdecl; external libSystem name 'unlinkat';
function libc_unmount(path: PAnsiChar; flags: Integer): Integer; cdecl; external libSystem name 'unmount';
function libc_write(fd: Integer; p: Pointer; len: Integer): Integer; cdecl; external libSystem name 'write';
function libc_mmap(addr: UIntPtr; length: UIntPtr; prot: Integer; flag: Integer; fd: Integer; pos: Int64): UIntPtr; cdecl; external libSystem name 'mmap';
function libc_munmap(addr: UIntPtr; length: UIntPtr): Integer; cdecl; external libSystem name 'munmap';
function libc_fstat64(fd: Integer; stat: PStat_t): Integer; cdecl; external libSystem name 'fstat64';
function libc_fstatat64(fd: Integer; path: PAnsiChar; stat: PStat_t; flags: Integer): Integer; cdecl; external libSystem name 'fstatat64';
function libc_fstatfs64(fd: Integer; stat: PStatfs_t): Integer; cdecl; external libSystem name 'fstatfs64';
function libc_getfsstat64(buf: Pointer; size: UIntPtr; flags: Integer): Integer; cdecl; external libSystem name 'getfsstat64';
function libc_lstat64(path: PAnsiChar; stat: PStat_t): Integer; cdecl; external libSystem name 'lstat64';
function libc_ptrace(request: Integer; pid: Integer; addr: UIntPtr; data: UIntPtr): Integer; cdecl; external libSystem name 'ptrace';
function libc_stat64(path: PAnsiChar; stat: PStat_t): Integer; cdecl; external libSystem name 'stat64';
function libc_statfs64(path: PAnsiChar; stat: PStatfs_t): Integer; cdecl; external libSystem name 'statfs64';

// Implementations

function getgroups(ParaNgid: Integer; ParaGid: PGid_t; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getgroups(ParaNgid, ParaGid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function setgroups(ParaNgid: Integer; ParaGid: PGid_t; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setgroups(ParaNgid, ParaGid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Wait4(ParaPid: Integer; ParaWstatus: PC_int; ParaOptions: Integer; ParaRusage: PRusage; out ParaWpid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_wait4(ParaPid, ParaWstatus, ParaOptions, ParaRusage);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaWpid := 0;
    Result := False;
  end else
  begin
    ParaWpid := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Accept(ParaS: Integer; ParaRsa: PRawSockaddrAny; ParaAddrlen: PSocklen; out ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_accept(ParaS, ParaRsa, ParaAddrlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaFd := 0;
    Result := False;
  end else
  begin
    ParaFd := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Bind(ParaS: Integer; ParaAddr: Pointer; ParaAddrlen: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_bind(ParaS, ParaAddr, ParaAddrlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Connect(ParaS: Integer; ParaAddr: Pointer; ParaAddrlen: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_connect(ParaS, ParaAddr, ParaAddrlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Socket(ParaDomain: Integer; ParaTyp: Integer; ParaProto: Integer; out ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_socket(ParaDomain, ParaTyp, ParaProto);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaFd := 0;
    Result := False;
  end else
  begin
    ParaFd := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Getsockopt(ParaS: Integer; ParaLevel: Integer; ParaName: Integer; ParaVal: Pointer; ParaVallen: PSocklen; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getsockopt(ParaS, ParaLevel, ParaName, ParaVal, ParaVallen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setsockopt(ParaS: Integer; ParaLevel: Integer; ParaName: Integer; ParaVal: Pointer; ParaVallen: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setsockopt(ParaS, ParaLevel, ParaName, ParaVal, ParaVallen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getpeername(ParaFd: Integer; ParaRsa: PRawSockaddrAny; ParaAddrlen: PSocklen; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getpeername(ParaFd, ParaRsa, ParaAddrlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getsockname(ParaFd: Integer; ParaRsa: PRawSockaddrAny; ParaAddrlen: PSocklen; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getsockname(ParaFd, ParaRsa, ParaAddrlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Shutdown(ParaS: Integer; ParaHow: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_shutdown(ParaS, ParaHow);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Socketpair(ParaDomain: Integer; ParaTyp: Integer; ParaProto: Integer; ParaFd: Pointer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_socketpair(ParaDomain, ParaTyp, ParaProto, ParaFd);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Recvfrom(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; ParaFlags: Integer; ParaFrom: PRawSockaddrAny; ParaFromlen: PSocklen; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_recvfrom(ParaFd, ParaP, ParaLen, ParaFlags, ParaFrom, ParaFromlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Sendto(ParaS: Integer; ParaBuf: Pointer; ParaLen: Integer; ParaFlags: Integer; ParaTo: Pointer; ParaAddrlen: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_sendto(ParaS, ParaBuf, ParaLen, ParaFlags, ParaTo, ParaAddrlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Recvmsg(ParaS: Integer; ParaMsg: PMsghdr; ParaFlags: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_recvmsg(ParaS, ParaMsg, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Sendmsg(ParaS: Integer; ParaMsg: PMsghdr; ParaFlags: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_sendmsg(ParaS, ParaMsg, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Kevent(ParaKq: Integer; ParaChange: Pointer; ParaNchange: Integer; ParaEvent: Pointer; ParaNevent: Integer; ParaTimeout: PTimespec; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_kevent(ParaKq, ParaChange, ParaNchange, ParaEvent, ParaNevent, ParaTimeout);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Utimes(ParaPath: string; ParaTimeval: PTimeval; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_utimes(PCharFromStr(ParaPath), ParaTimeval);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Futimes(ParaFd: Integer; ParaTimeval: PTimeval; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_futimes(ParaFd, ParaTimeval);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Poll(ParaFds: PPollFd; ParaNfds: Integer; ParaTimeout: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_poll(ParaFds, ParaNfds, ParaTimeout);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Madvise(ParaB: Pointer; ParaLen: Integer; ParaBehav: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_madvise(ParaB, ParaLen, ParaBehav);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Mlock(ParaB: Pointer; ParaLen: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_mlock(ParaB, ParaLen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Mlockall(ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_mlockall(ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Mprotect(ParaB: Pointer; ParaLen: Integer; ParaProt: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_mprotect(ParaB, ParaLen, ParaProt);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Msync(ParaB: Pointer; ParaLen: Integer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_msync(ParaB, ParaLen, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Munlock(ParaB: Pointer; ParaLen: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_munlock(ParaB, ParaLen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Munlockall(out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_munlockall;
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Pipe(ParaP: Pointer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_pipe(ParaP);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getxattr(ParaPath: string; ParaAttr: string; ParaDest: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getxattr(PCharFromStr(ParaPath), PCharFromStr(ParaAttr), ParaDest, ParaSize, ParaPosition, ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaSz := 0;
    Result := False;
  end else
  begin
    ParaSz := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Fgetxattr(ParaFd: Integer; ParaAttr: string; ParaDest: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fgetxattr(ParaFd, PCharFromStr(ParaAttr), ParaDest, ParaSize, ParaPosition, ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaSz := 0;
    Result := False;
  end else
  begin
    ParaSz := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Setxattr(ParaPath: string; ParaAttr: string; ParaData: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setxattr(PCharFromStr(ParaPath), PCharFromStr(ParaAttr), ParaData, ParaSize, ParaPosition, ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fsetxattr(ParaFd: Integer; ParaAttr: string; ParaData: Pointer; ParaSize: Integer; ParaPosition: Cardinal; ParaOptions: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fsetxattr(ParaFd, PCharFromStr(ParaAttr), ParaData, ParaSize, ParaPosition, ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Removexattr(ParaPath: string; ParaAttr: string; ParaOptions: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_removexattr(PCharFromStr(ParaPath), PCharFromStr(ParaAttr), ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fremovexattr(ParaFd: Integer; ParaAttr: string; ParaOptions: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fremovexattr(ParaFd, PCharFromStr(ParaAttr), ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Listxattr(ParaPath: string; ParaDest: Pointer; ParaSize: Integer; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_listxattr(PCharFromStr(ParaPath), ParaDest, ParaSize, ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaSz := 0;
    Result := False;
  end else
  begin
    ParaSz := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Flistxattr(ParaFd: Integer; ParaDest: Pointer; ParaSize: Integer; ParaOptions: Integer; out ParaSz: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_flistxattr(ParaFd, ParaDest, ParaSize, ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaSz := 0;
    Result := False;
  end else
  begin
    ParaSz := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Setattrlist(ParaPath: string; ParaList: Pointer; ParaBuf: Pointer; ParaSize: UIntPtr; ParaOptions: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setattrlist(PCharFromStr(ParaPath), ParaList, ParaBuf, ParaSize, ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fcntl(ParaFd: Integer; ParaCmd: Integer; ParaArg: Integer; out ParaVal: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fcntl(ParaFd, ParaCmd, ParaArg);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaVal := 0;
    Result := False;
  end else
  begin
    ParaVal := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Kill(ParaPid: Integer; ParaSignum: Integer; ParaPosix: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_kill(ParaPid, ParaSignum, ParaPosix);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Ioctl(ParaFd: Integer; ParaReq: Cardinal; ParaArg: UIntPtr; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_ioctl(ParaFd, ParaReq, ParaArg);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Sysctl(ParaMib: Pointer; ParaMibLen: Integer; ParaOld: Pointer; ParaOldlen: UIntPtr; ParaNew: Pointer; ParaNewlen: UIntPtr; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_sysctl(ParaMib, ParaMibLen, ParaOld, ParaOldlen, ParaNew, ParaNewlen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Sendfile(ParaInfd: Integer; ParaOutfd: Integer; ParaOffset: Int64; ParaLen: PInt64; ParaHdtr: Pointer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_sendfile(ParaInfd, ParaOutfd, ParaOffset, ParaLen, ParaHdtr, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Access(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_access(PCharFromStr(ParaPath), ParaMode);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Adjtime(ParaDelta: PTimeval; ParaOlddelta: PTimeval; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_adjtime(ParaDelta, ParaOlddelta);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Chdir(ParaPath: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_chdir(PCharFromStr(ParaPath));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Chflags(ParaPath: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_chflags(PCharFromStr(ParaPath), ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Chmod(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_chmod(PCharFromStr(ParaPath), ParaMode);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Chown(ParaPath: string; ParaUid: Integer; ParaGid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_chown(PCharFromStr(ParaPath), ParaUid, ParaGid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Chroot(ParaPath: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_chroot(PCharFromStr(ParaPath));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function ClockGettime(ParaClockid: Integer; ParaTime: PTimespec; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_clock_gettime(ParaClockid, ParaTime);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Close(ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_close(ParaFd);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Clonefile(ParaSrc: string; ParaDst: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_clonefile(PCharFromStr(ParaSrc), PCharFromStr(ParaDst), ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Clonefileat(ParaSrcDirfd: Integer; ParaSrc: string; ParaDstDirfd: Integer; ParaDst: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_clonefileat(ParaSrcDirfd, PCharFromStr(ParaSrc), ParaDstDirfd, PCharFromStr(ParaDst), ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Dup(ParaFd: Integer; out ParaNfd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_dup(ParaFd);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaNfd := 0;
    Result := False;
  end else
  begin
    ParaNfd := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Dup2(ParaFrom: Integer; ParaTo: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_dup2(ParaFrom, ParaTo);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Exchangedata(ParaPath1: string; ParaPath2: string; ParaOptions: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_exchangedata(PCharFromStr(ParaPath1), PCharFromStr(ParaPath2), ParaOptions);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

procedure Exit(ParaCode: Integer);
begin
  libc_exit(ParaCode);
end;

function Faccessat(ParaDirfd: Integer; ParaPath: string; ParaMode: Cardinal; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_faccessat(ParaDirfd, PCharFromStr(ParaPath), ParaMode, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fchdir(ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fchdir(ParaFd);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fchflags(ParaFd: Integer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fchflags(ParaFd, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fchmod(ParaFd: Integer; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fchmod(ParaFd, ParaMode);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fchmodat(ParaDirfd: Integer; ParaPath: string; ParaMode: Cardinal; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fchmodat(ParaDirfd, PCharFromStr(ParaPath), ParaMode, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fchown(ParaFd: Integer; ParaUid: Integer; ParaGid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fchown(ParaFd, ParaUid, ParaGid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fchownat(ParaDirfd: Integer; ParaPath: string; ParaUid: Integer; ParaGid: Integer; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fchownat(ParaDirfd, PCharFromStr(ParaPath), ParaUid, ParaGid, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fclonefileat(ParaSrcDirfd: Integer; ParaDstDirfd: Integer; ParaDst: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fclonefileat(ParaSrcDirfd, ParaDstDirfd, PCharFromStr(ParaDst), ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Flock(ParaFd: Integer; ParaHow: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_flock(ParaFd, ParaHow);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fpathconf(ParaFd: Integer; ParaName: Integer; out ParaVal: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fpathconf(ParaFd, ParaName);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaVal := 0;
    Result := False;
  end else
  begin
    ParaVal := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Fsync(ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fsync(ParaFd);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Ftruncate(ParaFd: Integer; ParaLength: Int64; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_ftruncate(ParaFd, ParaLength);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getcwd(ParaBuf: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getcwd(ParaBuf, ParaLen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Getdtablesize: Integer;
begin
  Result := libc_getdtablesize;
end;

function Getegid: Integer;
begin
  Result := libc_getegid;
end;

function Geteuid: Integer;
begin
  Result := libc_geteuid;
end;

function Getgid: Integer;
begin
  Result := libc_getgid;
end;

function Getpgid(ParaPid: Integer; out ParaPgid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getpgid(ParaPid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaPgid := 0;
    Result := False;
  end else
  begin
    ParaPgid := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Getpgrp: Integer;
begin
  Result := libc_getpgrp;
end;

function Getpid: Integer;
begin
  Result := libc_getpid;
end;

function Getppid: Integer;
begin
  Result := libc_getppid;
end;

function Getpriority(ParaWhich: Integer; ParaWho: Integer; out ParaPrio: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getpriority(ParaWhich, ParaWho);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaPrio := 0;
    Result := False;
  end else
  begin
    ParaPrio := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Getrlimit(ParaWhich: Integer; ParaLim: PRlimit; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getrlimit(ParaWhich, ParaLim);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getrusage(ParaWho: Integer; ParaRusage: PRusage; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getrusage(ParaWho, ParaRusage);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getsid(ParaPid: Integer; out ParaSid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getsid(ParaPid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaSid := 0;
    Result := False;
  end else
  begin
    ParaSid := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Gettimeofday(ParaTp: PTimeval; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_gettimeofday(ParaTp, nil);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getuid: Integer;
begin
  Result := libc_getuid;
end;

function Issetugid: Boolean;
begin
  Result := libc_issetugid <> 0;
end;

function Kqueue(out ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_kqueue;
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaFd := 0;
    Result := False;
  end else
  begin
    ParaFd := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Lchown(ParaPath: string; ParaUid: Integer; ParaGid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_lchown(PCharFromStr(ParaPath), ParaUid, ParaGid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Link(ParaPath: string; ParaLink: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_link(PCharFromStr(ParaPath), PCharFromStr(ParaLink));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Linkat(ParaPathfd: Integer; ParaPath: string; ParaLinkfd: Integer; ParaLink: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_linkat(ParaPathfd, PCharFromStr(ParaPath), ParaLinkfd, PCharFromStr(ParaLink), ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Listen(ParaS: Integer; ParaBacklog: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_listen(ParaS, ParaBacklog);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Mkdir(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_mkdir(PCharFromStr(ParaPath), ParaMode);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Mkdirat(ParaDirfd: Integer; ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_mkdirat(ParaDirfd, PCharFromStr(ParaPath), ParaMode);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Mkfifo(ParaPath: string; ParaMode: Cardinal; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_mkfifo(PCharFromStr(ParaPath), ParaMode);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Mknod(ParaPath: string; ParaMode: Cardinal; ParaDev: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_mknod(PCharFromStr(ParaPath), ParaMode, ParaDev);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Open(ParaPath: string; ParaMode: Integer; ParaPerm: Cardinal; out ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_open(PCharFromStr(ParaPath), ParaMode, ParaPerm);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaFd := 0;
    Result := False;
  end else
  begin
    ParaFd := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Openat(ParaDirfd: Integer; ParaPath: string; ParaMode: Integer; ParaPerm: Cardinal; out ParaFd: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_openat(ParaDirfd, PCharFromStr(ParaPath), ParaMode, ParaPerm);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaFd := 0;
    Result := False;
  end else
  begin
    ParaFd := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Pathconf(ParaPath: string; ParaName: Integer; out ParaVal: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_pathconf(PCharFromStr(ParaPath), ParaName);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaVal := 0;
    Result := False;
  end else
  begin
    ParaVal := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Pread(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; ParaOffset: Int64; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_pread(ParaFd, ParaP, ParaLen, ParaOffset);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Pwrite(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; ParaOffset: Int64; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_pwrite(ParaFd, ParaP, ParaLen, ParaOffset);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Read(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_read(ParaFd, ParaP, ParaLen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Readlink(ParaPath: string; ParaBuf: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_readlink(PCharFromStr(ParaPath), ParaBuf, ParaLen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Readlinkat(ParaDirfd: Integer; ParaPath: string; ParaBuf: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_readlinkat(ParaDirfd, PCharFromStr(ParaPath), ParaBuf, ParaLen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Rename(ParaFrom: string; ParaTo: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_rename(PCharFromStr(ParaFrom), PCharFromStr(ParaTo));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Renameat(ParaFromfd: Integer; ParaFrom: string; ParaTofd: Integer; ParaTo: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_renameat(ParaFromfd, PCharFromStr(ParaFrom), ParaTofd, PCharFromStr(ParaTo));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Revoke(ParaPath: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_revoke(PCharFromStr(ParaPath));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Rmdir(ParaPath: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_rmdir(PCharFromStr(ParaPath));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Seek(ParaFd: Integer; ParaOffset: Int64; ParaWhence: Integer; out ParaNewoffset: Int64; out ParaErr: Integer): Boolean;
var
  vRes: Int64;
begin
  vRes := libc_lseek(ParaFd, ParaOffset, ParaWhence);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaNewoffset := 0;
    Result := False;
  end else
  begin
    ParaNewoffset := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Select(ParaNfd: Integer; ParaR: PFdSet; ParaW: PFdSet; ParaE: PFdSet; ParaTimeout: PTimeval; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_select(ParaNfd, ParaR, ParaW, ParaE, ParaTimeout);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Setegid(ParaEgid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setegid(ParaEgid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Seteuid(ParaEuid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_seteuid(ParaEuid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setgid(ParaGid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setgid(ParaGid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setlogin(ParaName: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setlogin(PCharFromStr(ParaName));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setpgid(ParaPid: Integer; ParaPgid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setpgid(ParaPid, ParaPgid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setpriority(ParaWhich: Integer; ParaWho: Integer; ParaPrio: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setpriority(ParaWhich, ParaWho, ParaPrio);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setprivexec(ParaFlag: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setprivexec(ParaFlag);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setregid(ParaRgid: Integer; ParaEgid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setregid(ParaRgid, ParaEgid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setreuid(ParaRuid: Integer; ParaEuid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setreuid(ParaRuid, ParaEuid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setrlimit(ParaWhich: Integer; ParaLim: PRlimit; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setrlimit(ParaWhich, ParaLim);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setsid(out ParaPid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setsid;
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaPid := 0;
    Result := False;
  end else
  begin
    ParaPid := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Settimeofday(ParaTp: PTimeval; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_settimeofday(ParaTp, nil);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Setuid(ParaUid: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_setuid(ParaUid);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Symlink(ParaPath: string; ParaLink: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_symlink(PCharFromStr(ParaPath), PCharFromStr(ParaLink));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Symlinkat(ParaOldpath: string; ParaNewdirfd: Integer; ParaNewpath: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_symlinkat(PCharFromStr(ParaOldpath), ParaNewdirfd, PCharFromStr(ParaNewpath));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Sync(out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_sync;
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Truncate(ParaPath: string; ParaLength: Int64; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_truncate(PCharFromStr(ParaPath), ParaLength);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Umask(ParaNewmask: Integer): Integer;
begin
  Result := libc_umask(ParaNewmask);
end;

function Undelete(ParaPath: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_undelete(PCharFromStr(ParaPath));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Unlink(ParaPath: string; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_unlink(PCharFromStr(ParaPath));
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Unlinkat(ParaDirfd: Integer; ParaPath: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_unlinkat(ParaDirfd, PCharFromStr(ParaPath), ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Unmount(ParaPath: string; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_unmount(PCharFromStr(ParaPath), ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Write(ParaFd: Integer; ParaP: Pointer; ParaLen: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_write(ParaFd, ParaP, ParaLen);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Mmap(ParaAddr: UIntPtr; ParaLength: UIntPtr; ParaProt: Integer; ParaFlag: Integer; ParaFd: Integer; ParaPos: Int64; out ParaRet: UIntPtr; out ParaErr: Integer): Boolean;
var
  vRes: UIntPtr;
begin
  vRes := libc_mmap(ParaAddr, ParaLength, ParaProt, ParaFlag, ParaFd, ParaPos);
  // mmap returns MAP_FAILED (usually -1) on error.
  if vRes = UIntPtr(-1) then
  begin
    ParaErr := GetErrno;
    ParaRet := 0;
    Result := False;
  end else
  begin
    ParaRet := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Munmap(ParaAddr: UIntPtr; ParaLength: UIntPtr; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_munmap(ParaAddr, ParaLength);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Readlen(ParaFd: Integer; ParaBuf: Pointer; ParaNbuf: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_read(ParaFd, ParaBuf, ParaNbuf);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Writelen(ParaFd: Integer; ParaBuf: Pointer; ParaNbuf: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_write(ParaFd, ParaBuf, ParaNbuf);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Fstat(ParaFd: Integer; ParaStat: PStat_t; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fstat64(ParaFd, ParaStat);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fstatat(ParaFd: Integer; ParaPath: string; ParaStat: PStat_t; ParaFlags: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fstatat64(ParaFd, PCharFromStr(ParaPath), ParaStat, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Fstatfs(ParaFd: Integer; ParaStat: PStatfs_t; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_fstatfs64(ParaFd, ParaStat);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Getfsstat(ParaBuf: Pointer; ParaSize: UIntPtr; ParaFlags: Integer; out ParaN: Integer; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_getfsstat64(ParaBuf, ParaSize, ParaFlags);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    ParaN := 0;
    Result := False;
  end else
  begin
    ParaN := vRes;
    ParaErr := 0;
    Result := True;
  end;
end;

function Lstat(ParaPath: string; ParaStat: PStat_t; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_lstat64(PCharFromStr(ParaPath), ParaStat);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Ptrace1(ParaRequest: Integer; ParaPid: Integer; ParaAddr: UIntPtr; ParaData: UIntPtr; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_ptrace(ParaRequest, ParaPid, ParaAddr, ParaData);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Stat(ParaPath: string; ParaStat: PStat_t; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_stat64(PCharFromStr(ParaPath), ParaStat);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

function Statfs(ParaPath: string; ParaStat: PStatfs_t; out ParaErr: Integer): Boolean;
var
  vRes: Integer;
begin
  vRes := libc_statfs64(PCharFromStr(ParaPath), ParaStat);
  if vRes < 0 then
  begin
    ParaErr := GetErrno;
    Result := False;
  end else
  begin
    ParaErr := 0;
    Result := True;
  end;
end;

end.
