{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.Eventlog;

interface

// Copyright 2012 The Go Authors. All rights reserved.
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
  Winapi.Windows, // For PWideChar, PByte, LongBool
  Vendor.Golang.Org.X.Sys.Windows.Syscall // For THandle, TErrno
;
{$ENDIF}

// Constants from Go eventlog.go
const
    Const_EVENTLOG_SUCCESS = 0;
    Const_EVENTLOG_ERROR_TYPE = 1;
    Const_EVENTLOG_WARNING_TYPE = 2;
    Const_EVENTLOG_INFORMATION_TYPE = 4;
    Const_EVENTLOG_AUDIT_SUCCESS = 8;
    Const_EVENTLOG_AUDIT_FAILURE = 16;

type
    THandle = Vendor.Golang.Org.X.Sys.Windows.Syscall.THandle;
    TErrno = Vendor.Golang.Org.X.Sys.Windows.Syscall.TErrno;

// Go-style wrappers for syscalls. They return the result and an error (TErrno).
// The actual WinAPI functions are declared in the implementation section.

// Go: RegisterEventSource(uncServerName *uint16, sourceName *uint16) (handle Handle, err error) [failretval==0] = advapi32.RegisterEventSourceW
function RegisterEventSource(ParaUncServerName, ParaSourceName: PWideChar; out ParaHandle: THandle): TErrno;

// Go: DeregisterEventSource(handle Handle) (err error) = advapi32.DeregisterEventSource
function DeregisterEventSource(ParaHandle: THandle): TErrno;

// Go: ReportEvent(log Handle, etype uint16, category uint16, eventId uint32, usrSId uintptr, numStrings uint16, dataSize uint32, strings **uint16, rawData *byte) (err error) = advapi32.ReportEventW
function ReportEvent(ParaLog: THandle; ParaEType: Word; ParaCategory: Word; ParaEventId: Cardinal; ParaUsrSId: NativeUInt; ParaNumStrings: Word; ParaDataSize: Cardinal; ParaStrings: ^PWideChar; ParaRawData: PByte): TErrno;

implementation

uses
    Winapi.Windows; // Required for the external function declarations

// Helper function to get TErrno from GetLastError, or 0 for success
function GetLastErrno: TErrno;
begin
    Result := Winapi.Windows.GetLastError;
    if Result = 0 then
    begin
        // If GetLastError is 0, it means the operation succeeded with no error.
        // Go's syscalls return 0 on success.
        Result := 0;
    end;
end;

// --- WinAPI External Function Declarations (Private to implementation) ---

// sys	RegisterEventSource(uncServerName *uint16, sourceName *uint16) (handle Handle, err error) [failretval==0] = advapi32.RegisterEventSourceW
function Winapi_RegisterEventSourceW(lpUNCServerName, lpSourceName: PWideChar): THandle; stdcall; external 'advapi32.dll' name 'RegisterEventSourceW';

// sys	DeregisterEventSource(handle Handle) (err error) = advapi32.DeregisterEventSource
function Winapi_DeregisterEventSource(hEventLog: THandle): LongBool; stdcall; external 'advapi32.dll' name 'DeregisterEventSource';

// sys	ReportEvent(log Handle, etype uint16, category uint16, eventId uint32, usrSId uintptr, numStrings uint16, dataSize uint32, strings **uint16, rawData *byte) (err error) = advapi32.ReportEventW
function Winapi_ReportEventW(hEventLog: THandle; wType: Word; wCategory: Word; dwEventID: Cardinal; lpUserSid: Pointer; wNumStrings: Word; dwDataSize: Cardinal; lpStrings: Pointer; lpRawData: PByte): LongBool; stdcall; external 'advapi32.dll' name 'ReportEventW';

// --- Go-Style Wrapper Implementations ---

function RegisterEventSource(ParaUncServerName, ParaSourceName: PWideChar; out ParaHandle: THandle): TErrno;
begin
    // Go: (handle Handle, err error) [failretval==0] = advapi32.RegisterEventSourceW
    ParaHandle := Winapi_RegisterEventSourceW(ParaUncServerName, ParaSourceName);

    if ParaHandle = 0 then
    begin
        Result := GetLastErrno;
    end else
    begin
        Result := 0; // Success
    end;
end;

function DeregisterEventSource(ParaHandle: THandle): TErrno;
begin
    // Go: (err error) = advapi32.DeregisterEventSource
    if not Winapi_DeregisterEventSource(ParaHandle) then
    begin
        Result := GetLastErrno;
    end else
    begin
        Result := 0; // Success
    end;
end;

function ReportEvent(ParaLog: THandle; ParaEType: Word; ParaCategory: Word; ParaEventId: Cardinal; ParaUsrSId: NativeUInt; ParaNumStrings: Word; ParaDataSize: Cardinal; ParaStrings: ^PWideChar; ParaRawData: PByte): TErrno;
begin
    // Go: (err error) = advapi32.ReportEventW
    // Note on ParaUsrSId (uintptr in Go, Pointer in WinAPI): The Go type is uintptr, implying it can be a SID pointer or 0. We use NativeUInt.
    // Note on ParaStrings (**uint16 in Go, Pointer in WinAPI): Go uses **uint16, which is a pointer to an array of PWideChar.
    
    // We pass ParaUsrSId as Pointer (NativeUInt implicitly converted) and ParaStrings as Pointer
    if not Winapi_ReportEventW(
        ParaLog,
        ParaEType,
        ParaCategory,
        ParaEventId,
        Pointer(ParaUsrSId), // The uintptr is passed as a Pointer (SID)
        ParaNumStrings,
        ParaDataSize,
        ParaStrings, // ^PWideChar is compatible with Pointer
        ParaRawData
    ) then
    begin
        Result := GetLastErrno;
    end else
    begin
        Result := 0; // Success
    end;
end;

end.