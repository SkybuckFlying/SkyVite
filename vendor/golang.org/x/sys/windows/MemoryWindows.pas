{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.MemoryWindows;

interface

// Copyright 2017 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

{$IFDEF FPC}
uses
  SysUtils
;
{$ELSE}
uses
  System.SysUtils
;
{$ENDIF}

const
    // Memory Allocation Type Constants (MEM_*)
    Const_MEM_COMMIT = $00001000;
    Const_MEM_RESERVE = $00002000;
    Const_MEM_DECOMMIT = $00004000;
    Const_MEM_RELEASE = $00008000;
    Const_MEM_RESET = $00080000;
    Const_MEM_TOP_DOWN = $00100000;
    Const_MEM_WRITE_WATCH = $00200000;
    Const_MEM_PHYSICAL = $00400000;
    Const_MEM_RESET_UNDO = $01000000;
    Const_MEM_LARGE_PAGES = $20000000;

    // Memory Protection Constants (PAGE_*)
    Const_PAGE_NOACCESS = $00000001;
    Const_PAGE_READONLY = $00000002;
    Const_PAGE_READWRITE = $00000004;
    Const_PAGE_WRITECOPY = $00000008;
    Const_PAGE_EXECUTE = $00000010;
    Const_PAGE_EXECUTE_READ = $00000020;
    Const_PAGE_EXECUTE_READWRITE = $00000040;
    Const_PAGE_EXECUTE_WRITECOPY = $00000080;
    Const_PAGE_GUARD = $00000100;
    Const_PAGE_NOCACHE = $00000200;
    Const_PAGE_WRITECOMBINE = $00000400;
    Const_PAGE_TARGETS_INVALID = $40000000;
    Const_PAGE_TARGETS_NO_UPDATE = $40000000; // Same value as PAGE_TARGETS_INVALID

    // Quota Limit Constants (QUOTA_LIMITS_*)
    Const_QUOTA_LIMITS_HARDWS_MIN_DISABLE = $00000002;
    Const_QUOTA_LIMITS_HARDWS_MIN_ENABLE = $00000001;
    Const_QUOTA_LIMITS_HARDWS_MAX_DISABLE = $00000008;
    Const_QUOTA_LIMITS_HARDWS_MAX_ENABLE = $00000004;

implementation

end.