// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallAixPpc;

interface

uses
{$IFDEF FPC}
  SysUtils,
  Vendor.Golang.Org.X.Sys.Unix.Types // Assumed unit for Rlimit, Stat_t, etc.
{$ELSE}
  System.SysUtils,
  Vendor.Golang.Org.X.Sys.Unix.Types; // Assumed unit for Rlimit, Stat_t, etc.
{$ENDIF}

type
  // The types Rlimit and Stat_t are assumed to be defined in Vendor.Golang.Org.X.Sys.Unix.Types,
  // so no forward declaration is strictly needed here if we import it, but for safety in case
  // of a complex structure, we rely on the imported unit.

// Exported Go functions (Capitalized)

// Fstat is a wrapper for the fstat system call.
function Fstat
(
	ParaFD : Integer;
	var ParaStat : Stat_t
) : Integer; // Returns error (errno)

// Fstatat is a wrapper for the fstatat system call.
function Fstatat
(
	ParaDirFD : Integer;
	ParaPath : string;
	var ParaStat : Stat_t;
	ParaFlags : Integer
) : Integer; // Returns error (errno)

// Lstat is a wrapper for the lstat system call.
function Lstat
(
	ParaPath : string;
	var ParaStat : Stat_t
) : Integer; // Returns error (errno)

// Stat is a wrapper for the stat system call.
function Stat
(
	ParaPath : string;
	var ParaStatPtr : Stat_t
) : Integer; // Returns error (errno)


implementation

// We place this local uses clause in the implementation section as per the rules
// since the types below and the syscall wrappers are only used internally.
uses
{$IFDEF FPC}
  RTLConsts;
{$ELSE}
  System.RTLConsts;
{$ENDIF}

// Forward declarations of internal types for unexported functions
type
  Timespec = record
    mSec : LongInt; // int32
    mNsec : LongInt; // int32
  end;

  Timeval = record
    mSec : LongInt; // int32
    mUsec : LongInt; // int32
  end;

  Iovec = record
    mLen : LongWord; // uint32
    // Assuming other necessary fields are here
  end;

  Msghdr = record
    mControllen : LongWord; // uint32
    mIovlen : LongInt; // int32
    // Assuming other necessary fields are here
  end;

  Cmsghdr = record
    mLen : LongWord; // uint32
    // Assuming other necessary fields are here
  end;

// Syscall stubs (assuming they are standard C-style functions)
// The Go file's //sys directives imply C-linkage.
function fstat(ParaFD : Integer; ParaStat : Pointer) : Integer; external;
function fstatat(ParaDirFD : Integer; ParaPath : PChar; ParaStat : Pointer; ParaFlags : Integer) : Integer; external;
function lstat(ParaPath : PChar; ParaStat : Pointer) : Integer; external;
function stat(ParaPath : PChar; ParaStatPtr : Pointer) : Integer; external;


// Unexported Go functions (Lowercase)

// setTimespec creates a Timespec struct from sec and nsec.
function setTimespec
(
	ParaSec : Int64;
	ParaNSec : Int64
) : Timespec;
begin
	Result.mSec := LongInt(ParaSec);
	Result.mNsec := LongInt(ParaNSec);
end;

// setTimeval creates a Timeval struct from sec and usec.
function setTimeval
(
	ParaSec : Int64;
	ParaUSec : Int64
) : Timeval;
begin
	Result.mSec := LongInt(ParaSec);
	Result.mUsec := LongInt(ParaUSec);
end;

// SetIovecLen sets the length for an Iovec structure. (Go method (iov *Iovec) SetLen(length int))
procedure SetIovecLen
(
	var ParaIOV : Iovec;
	ParaLength : Integer
);
begin
	ParaIOV.mLen := LongWord(ParaLength);
end;

// SetMsghdrControllen sets the controllen for an Msghdr structure. (Go method (msghdr *Msghdr) SetControllen(length int))
procedure SetMsghdrControllen
(
	var ParaMsghdr : Msghdr;
	ParaLength : Integer
);
begin
	ParaMsghdr.mControllen := LongWord(ParaLength);
end;

// SetMsghdrIovlen sets the iovlen for an Msghdr structure. (Go method (msghdr *Msghdr) SetIovlen(length int))
procedure SetMsghdrIovlen
(
	var ParaMsghdr : Msghdr;
	ParaLength : Integer
);
begin
	ParaMsghdr.mIovlen := LongInt(ParaLength);
end;

// SetCmsghdrLen sets the length for a Cmsghdr structure. (Go method (cmsg *Cmsghdr) SetLen(length int))
procedure SetCmsghdrLen
(
	var ParaCmsg : Cmsghdr;
	ParaLength : Integer
);
begin
	ParaCmsg.mLen := LongWord(ParaLength);
end;


// Exported Go function implementations (Capitalized)

function Fstat
(
	ParaFD : Integer;
	var ParaStat : Stat_t
) : Integer;
begin
    // The Go function returns an error interface. We map to an Integer result (errno).
    Result := fstat
    (
        ParaFD,
        @ParaStat // Pass the Stat_t by reference/pointer
    );
end;

function Fstatat
(
	ParaDirFD : Integer;
	ParaPath : string;
	var ParaStat : Stat_t;
	ParaFlags : Integer
) : Integer;
var
	vPathPChar : PChar;
begin
	vPathPChar := PChar(ParaPath);
	Result := fstatat
	(
		ParaDirFD,
		vPathPChar, // Pass as C string
		@ParaStat,
		ParaFlags
	);
end;

function Lstat
(
	ParaPath : string;
	var ParaStat : Stat_t
) : Integer;
var
	vPathPChar : PChar;
begin
	vPathPChar := PChar(ParaPath);
	Result := lstat
	(
		vPathPChar,
		@ParaStat
	);
end;

function Stat
(
	ParaPath : string;
	var ParaStatPtr : Stat_t
) : Integer;
var
	vPathPChar : PChar;
begin
	vPathPChar := PChar(ParaPath);
	Result := stat
	(
		vPathPChar,
		@ParaStatPtr
	);
end;


end.