{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.Aliases;

interface

// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

{$IFDEF FPC}
uses
  SysUtils,
  Vendor.Golang.Org.X.Sys.Windows.Syscall
;
{$ELSE}
uses
  System.SysUtils,
  Vendor.Golang.Org.X.Sys.Windows.Syscall
;
{$ENDIF}

type
    // type Errno = syscall.Errno
    // Assuming the type in the Syscall unit is TErrno
    TErrno = Vendor.Golang.Org.X.Sys.Windows.Syscall.TErrno;

    // type SysProcAttr = syscall.SysProcAttr
    // Assuming the type in the Syscall unit is TSysProcAttr
    TSysProcAttr = Vendor.Golang.Org.X.Sys.Windows.Syscall.TSysProcAttr;

implementation

end.