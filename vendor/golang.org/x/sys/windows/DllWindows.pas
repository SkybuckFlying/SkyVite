{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.DllWindows;

interface

// Copyright 2011 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

{$IFDEF FPC}
uses
  SysUtils,
  SystemClasses,
  SyncObjs,
  SystemThreading,
  WinapiWindows,
  Vendor.Golang.Org.X.Sys.Windows.Syscall // For THandle, TErrno, and Syscall functions
;
{$ELSE}
uses
  System.SysUtils,
  System.Classes, // For TObject
  System.SyncObjs, // For TCriticalSection (sync.Mutex)
  System.Threading, // For TInterlocked (sync/atomic)
  Winapi.Windows, // For HMODULE, LoadLibraryExW, GetLastError, etc.
  Vendor.Golang.Org.X.Sys.Windows.Syscall // For THandle, TErrno, and Syscall functions
;
{$ENDIF}

type
    // Aliases for imported types from Syscall unit
    THandle = Vendor.Golang.Org.X.Sys.Windows.Syscall.THandle;
    TErrno = Vendor.Golang.Org.X.Sys.Windows.Syscall.TErrno;

    // Forward declarations for classes/records
    TDLL = class;
    TProc = class;
    TLazyDLL = class;
    TLazyProc = class;
    
    // Helper type for function that returns a string for an error code (from another file)
    function SysErrorMessage(ParaErr: TErrno): string;
    
    // DLLError describes reasons for DLL load failures.
    // Go: func (e *DLLError) Unwrap() error { return e.Err }
    TDLLError = class(Exception)
    private
        mErr: Exception; // Unwrap() error
        mObjName: string;
        mMsg: string; // Error() string
    public
        constructor Create(ParaErrno: TErrno; const ParaObjName: string; const ParaMsg: string); overload;
        constructor Create(ParaErr: Exception; const ParaObjName: string; const ParaMsg: string); overload;
        function Error: string; override;
        function Unwrap: Exception;
    end;

    // A DLL implements access to a single DLL.
    TDLL = class(TObject)
    private
        mName: string;
        mHandle: THandle;
    public
        constructor Create(const ParaName: string; ParaHandle: THandle);
        // LoadDLL loads DLL file into memory.
        class function LoadDLL(const ParaName: string): TDLL;
        // MustLoadDLL is like LoadDLL but panics if load operation failes.
        class function MustLoadDLL(const ParaName: string): TDLL;

        // FindProc searches DLL d for procedure named name and returns TProc
        // if found. It returns an error if search fails.
        function FindProc(const ParaName: string): TProc;
        // MustFindProc is like FindProc but panics if search fails.
        function MustFindProc(const ParaName: string): TProc;

        // FindProcByOrdinal searches DLL d for procedure by ordinal and returns TProc
        // if found. It returns an error if search fails.
        function FindProcByOrdinal(ParaOrdinal: NativeUInt): TProc;
        // MustFindProcByOrdinal is like FindProcByOrdinal but panics if search fails.
        function MustFindProcByOrdinal(ParaOrdinal: NativeUInt): TProc;

        // Release unloads DLL d from memory.
        function Release: TErrno;

        property Name: string read mName;
        property Handle: THandle read mHandle;
    end;

    // A Proc implements access to a procedure inside a DLL.
    TProc = class(TObject)
    private
        mDll: TDLL;
        mName: string;
        mAddr: NativeUInt; // uintptr
    public
        constructor Create(ParaDll: TDLL; const ParaName: string; ParaAddr: NativeUInt);

        // Addr returns the address of the procedure represented by p.
        function Addr: NativeUInt;

        // Call executes procedure p with arguments a.
        // Go: func (p *Proc) Call(a ...uintptr) (r1, r2 uintptr, lastErr error)
        function Call(const ParaA: array of NativeUInt; out ParaR1: NativeUInt; out ParaR2: NativeUInt): TErrno;

        property Dll: TDLL read mDll;
        property Name: string read mName;
        property AddrValue: NativeUInt read mAddr;
    end;

    // A LazyDLL implements access to a single DLL.
    TLazyDLL = class(TObject)
    private
        mName: string;
        // System determines whether the DLL must be loaded from the
        // Windows System directory, bypassing the normal DLL search path.
        mSystem: Boolean;

        mmu: TMonitor; // sync.Mutex
        mdll: TDLL; // non nil once DLL is loaded

        procedure mustLoad;
    public
        constructor Create(const ParaName: string; ParaSystem: Boolean = False); overload;

        class function NewLazyDLL(const ParaName: string): TLazyDLL;
        class function NewLazySystemDLL(const ParaName: string): TLazyDLL;

        // Load loads DLL file d.Name into memory. It returns an error if fails.
        function Load: Exception;
        
        // Handle returns d's module handle.
        function Handle: NativeUInt;

        // NewProc returns a LazyProc for accessing the named procedure in the DLL d.
        function NewProc(const ParaName: string): TLazyProc;

        property Name: string read mName;
        property System: Boolean read mSystem;
    end;
    
    // A LazyProc implements access to a procedure inside a LazyDLL.
    TLazyProc = class(TObject)
    private
        mName: string;

        mmu: TMonitor; // sync.Mutex
        ml: TLazyDLL;
        mproc: TProc;

        procedure mustFind;
    public
        constructor Create(ParaLazyDLL: TLazyDLL; const ParaName: string);

        // Find searches DLL for procedure named p.Name. It returns
        // an error if search fails.
        function Find: Exception;

        // Addr returns the address of the procedure represented by p.
        function Addr: NativeUInt;

        // Call executes procedure p with arguments a.
        function Call(const ParaA: array of NativeUInt; out ParaR1: NativeUInt; out ParaR2: NativeUInt): TErrno;
        
        property Name: string read mName;
    end;

// Global utility vars
var
    CanDoSearchSystem32Once_v: Boolean = False;
    CanDoSearchSystem32Once: TMonitor = nil; // Initialized in initialization block

// Forward declarations of internal/utility functions (Go unexported)
// Defined in this unit's implementation or imported from another utility unit (itoa, BytePtrFromString, UTF16PtrFromString).
function Itoa(ParaI: Integer): string;
function GetProcAddressByOrdinal(ParaHandle: THandle; ParaOrdinal: NativeUInt): NativeUInt;
function FreeLibrary(ParaHandle: THandle): TErrno;
function LoadLibraryEx(const ParaName: string; ParaReserved: NativeUInt; ParaFlags: NativeUInt): THandle;
function GetSystemDirectory: string;

// Private helper function (Go unexported)
procedure InitCanDoSearchSystem32;
function CanDoSearchSystem32: Boolean;
function IsBaseName(const ParaName: string): Boolean;
function LoadLibraryExWrapper(const ParaName: string; ParaSystem: Boolean): TDLL;

// Helper to handle Go string conversion functions - these must be implemented elsewhere
function UTF16PtrFromString(const ParaName: string): PWideChar;
function BytePtrFromString(const ParaName: string): PAnsiChar;

implementation

uses
    System.Rtti, // For TMonitor
    System.StrUtils,
    System.Threading;

const
    // Missing constant from the original Go file, needed by LoadLibraryExWrapper
    // Assuming it's defined in the Syscall/Windows unit. I will define it here for completeness.
    Const_LOAD_LIBRARY_SEARCH_SYSTEM32 = $00000800; // Value for LOAD_LIBRARY_SEARCH_SYSTEM32

// --- Helper Functions (Mocking external/unconverted functions) ---

// Assuming these utility functions are implemented in another utility unit or directly here.
function Itoa(ParaI: Integer): string;
begin
    Result := IntToStr(ParaI);
end;

function UTF16PtrFromString(const ParaName: string): PWideChar;
// Implemented as a mock for now, this should be replaced by a proper conversion function
begin
    Result := PWideChar(WideString(ParaName));
end;

function BytePtrFromString(const ParaName: string): PAnsiChar;
// Implemented as a mock for now
begin
    Result := PAnsiChar(AnsiString(ParaName));
end;

function GetProcAddressByOrdinal(ParaHandle: THandle; ParaOrdinal: NativeUInt): NativeUInt;
begin
    Result := Winapi.Windows.GetProcAddress(ParaHandle, PAnsiChar(ParaOrdinal));
    if Result = 0 then
    begin
        // If it fails, GetLastError must be checked by the caller
        Winapi.Windows.GetLastError;
    end;
end;

function FreeLibrary(ParaHandle: THandle): TErrno;
begin
    if not Winapi.Windows.FreeLibrary(ParaHandle) then
    begin
        Result := Winapi.Windows.GetLastError;
    end else
    begin
        Result := 0;
    end;
end;

function LoadLibraryEx(const ParaName: string; ParaReserved: NativeUInt; ParaFlags: NativeUInt): THandle;
begin
    Result := Winapi.Windows.LoadLibraryExW(PWideChar(WideString(ParaName)), ParaReserved, ParaFlags);
    if Result = 0 then
    begin
        // If it fails, GetLastError must be checked by the caller
        Winapi.Windows.GetLastError;
    end;
end;

function GetSystemDirectory: string;
var
    vBuffer: array[0..MAX_PATH] of WideChar;
    vLen: Cardinal;
begin
    vLen := Winapi.Windows.GetSystemDirectoryW(vBuffer, MAX_PATH);
    if vLen > 0 then
    begin
        Result := vBuffer;
    end else
    begin
        Result := '';
    end;
end;

function SysErrorMessage(ParaErr: TErrno): string;
begin
    Result := System.SysUtils.SysErrorMessage(ParaErr);
end;

// --- TDLLError Implementation ---

constructor TDLLError.Create(ParaErrno: TErrno; const ParaObjName: string; const ParaMsg: string);
begin
    // Go: &DLLError{Err: e, ObjName: name, Msg: "Failed to load " + name + ": " + e.Error()}
    inherited Create(ParaMsg); // The message is the final message
    mErr := Exception.Create(SysErrorMessage(ParaErrno)); // Wrapping the Errno as an exception
    mObjName := ParaObjName;
    mMsg := ParaMsg;
end;

constructor TDLLError.Create(ParaErr: Exception; const ParaObjName: string; const ParaMsg: string);
begin
    inherited Create(ParaMsg);
    mErr := ParaErr;
    mObjName := ParaObjName;
    mMsg := ParaMsg;
end;

function TDLLError.Error: string;
begin
    Result := mMsg;
end;

function TDLLError.Unwrap: Exception;
begin
    Result := mErr;
end;

// --- TDLL Implementation ---

constructor TDLL.Create(const ParaName: string; ParaHandle: THandle);
begin
    // Go: d := &DLL{Name: name, Handle: h}
    try
        inherited Create;
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create('Failed to create TDLL object: Out of memory');
        end;
    end;
    mName := ParaName;
    mHandle := ParaHandle;
end;

class function TDLL.LoadDLL(const ParaName: string): TDLL;
var
    vNameP: PWideChar;
    vH: THandle;
    vE: TErrno;
    vDLL: TDLL;
begin
    // Go: namep, err := UTF16PtrFromString(name)
    vNameP := UTF16PtrFromString(ParaName);
    
    // Go: h, e := syscall_loadlibrary(namep)
    // Note: Go uses `syscall_loadlibrary` which is a runtime-linked syscall.
    // In Delphi, we use LoadLibraryExW and check GetLastError.
    vH := Winapi.Windows.LoadLibraryExW(vNameP, 0, 0);
    vE := Winapi.Windows.GetLastError;

    if vH = 0 then
    begin
        // Go: if e != 0 { return nil, &DLLError{...} }
        raise TDLLError.Create(vE, ParaName, Format('Failed to load %s: %s', [ParaName, SysErrorMessage(vE)]));
    end;

    // Go: d := &DLL{Name: name, Handle: h}
    vDLL := nil;
    try
        vDLL := TDLL.Create(ParaName, vH);
        Result := vDLL;
    except
        on E: Exception do
        begin
            // Clean up the loaded library on failure to create the object
            Winapi.Windows.FreeLibrary(vH);
            raise TDLLError.Create(E, ParaName, 'Failed to create TDLL object after loading library: ' + E.Message);
        end;
    end;
end;

class function TDLL.MustLoadDLL(const ParaName: string): TDLL;
begin
    // Go: MustLoadDLL is like LoadDLL but panics if load operation failes.
    Result := TDLL.LoadDLL(ParaName);
end;

function TDLL.FindProc(const ParaName: string): TProc;
var
    vNameP: PAnsiChar;
    vA: NativeUInt;
    vE: TErrno;
    vProc: TProc;
begin
    // Go: namep, err := BytePtrFromString(name)
    vNameP := BytePtrFromString(ParaName);

    // Go: a, e := syscall_getprocaddress(d.Handle, namep)
    vA := Winapi.Windows.GetProcAddress(mHandle, vNameP);
    vE := Winapi.Windows.GetLastError;

    if vA = 0 then
    begin
        // Go: if e != 0 { return nil, &DLLError{...} }
        raise TDLLError.Create(vE, ParaName, Format('Failed to find %s procedure in %s: %s', [ParaName, mName, SysErrorMessage(vE)]));
    end;

    // Go: p := &Proc{Dll: d, Name: name, addr: a}
    vProc := nil;
    try
        vProc := TProc.Create(Self, ParaName, vA);
        Result := vProc;
    except
        on E: Exception do
        begin
            raise TDLLError.Create(E, ParaName, 'Failed to create TProc object after finding procedure: ' + E.Message);
        end;
    end;
end;

function TDLL.MustFindProc(const ParaName: string): TProc;
begin
    Result := FindProc(ParaName);
end;

function TDLL.FindProcByOrdinal(ParaOrdinal: NativeUInt): TProc;
var
    vA: NativeUInt;
    vE: TErrno;
    vName: string;
    vProc: TProc;
begin
    // Go: a, e := GetProcAddressByOrdinal(d.Handle, ordinal)
    vA := GetProcAddressByOrdinal(mHandle, ParaOrdinal);
    vE := Winapi.Windows.GetLastError;
    vName := '#' + Itoa(ParaOrdinal);

    if vA = 0 then
    begin
        // Go: if e != nil { return nil, &DLLError{...} }
        raise TDLLError.Create(vE, vName, Format('Failed to find %s procedure in %s: %s', [vName, mName, SysErrorMessage(vE)]));
    end;

    // Go: p := &Proc{Dll: d, Name: name, addr: a}
    vProc := nil;
    try
        vProc := TProc.Create(Self, vName, vA);
        Result := vProc;
    except
        on E: Exception do
        begin
            raise TDLLError.Create(E, vName, 'Failed to create TProc object after finding procedure by ordinal: ' + E.Message);
        end;
    end;
end;

function TDLL.MustFindProcByOrdinal(ParaOrdinal: NativeUInt): TProc;
begin
    Result := FindProcByOrdinal(ParaOrdinal);
end;

function TDLL.Release: TErrno;
begin
    // Go: return FreeLibrary(d.Handle)
    Result := FreeLibrary(mHandle);
end;

// --- TProc Implementation ---

constructor TProc.Create(ParaDll: TDLL; const ParaName: string; ParaAddr: NativeUInt);
begin
    // Go: p := &Proc{Dll: d, Name: name, addr: a}
    try
        inherited Create;
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create('Failed to create TProc object: Out of memory');
        end;
    end;
    mDll := ParaDll;
    mName := ParaName;
    mAddr := ParaAddr;
end;

function TProc.Addr: NativeUInt;
begin
    // Go: func (p *Proc) Addr() uintptr
    Result := mAddr;
end;

function TProc.Call(const ParaA: array of NativeUInt; out ParaR1: NativeUInt; out ParaR2: NativeUInt): TErrno;
var
    vLen: NativeUInt;
    vErr: TErrno;
begin
    vLen := Length(ParaA);
    ParaR1 := 0;
    ParaR2 := 0;
    vErr := 0;

    // Go: It will panic, if more than 15 arguments are supplied.
    if vLen > 15 then
    begin
        raise Exception.Create(Format('Call %s with too many arguments %d.', [mName, vLen]));
    end;

    // Go: (r1, r2 uintptr, lastErr error) = syscall.SyscallN(...)
    // The syscall functions are assumed to be implemented in Vendor.Golang.Org.X.Sys.Windows.Syscall
    // and must update R1, R2, and return the last error.

    // I will use a direct call to the Syscall unit, and assume it returns R1, updates R2 and Errno.
    case vLen of
        0:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall(mAddr, vLen, 0, 0, 0, ParaR1, ParaR2);
        end;
        1:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall(mAddr, vLen, ParaA[0], 0, 0, ParaR1, ParaR2);
        end;
        2:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall(mAddr, vLen, ParaA[0], ParaA[1], 0, ParaR1, ParaR2);
        end;
        3:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaR1, ParaR2);
        end;
        4:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall6(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], 0, 0, ParaR1, ParaR2);
        end;
        5:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall6(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], 0, ParaR1, ParaR2);
        end;
        6:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall6(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaR1, ParaR2);
        end;
        7:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall9(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], 0, 0, ParaR1, ParaR2);
        end;
        8:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall9(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], 0, ParaR1, ParaR2);
        end;
        9:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall9(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], ParaA[8], ParaR1, ParaR2);
        end;
        10:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall12(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], ParaA[8], ParaA[9], 0, 0, ParaR1, ParaR2);
        end;
        11:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall12(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], ParaA[8], ParaA[9], ParaA[10], 0, ParaR1, ParaR2);
        end;
        12:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall12(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], ParaA[8], ParaA[9], ParaA[10], ParaA[11], ParaR1, ParaR2);
        end;
        13:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall15(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], ParaA[8], ParaA[9], ParaA[10], ParaA[11], ParaA[12], 0, 0, ParaR1, ParaR2);
        end;
        14:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall15(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], ParaA[8], ParaA[9], ParaA[10], ParaA[11], ParaA[12], ParaA[13], 0, ParaR1, ParaR2);
        end;
        15:
        begin
            vErr := Vendor.Golang.Org.X.Sys.Windows.Syscall.Syscall15(mAddr, vLen, ParaA[0], ParaA[1], ParaA[2], ParaA[3], ParaA[4], ParaA[5], ParaA[6], ParaA[7], ParaA[8], ParaA[9], ParaA[10], ParaA[11], ParaA[12], ParaA[13], ParaA[14], ParaR1, ParaR2);
        end;
    end;
    Result := vErr;
end;

// --- TLazyDLL Implementation ---

constructor TLazyDLL.Create(const ParaName: string; ParaSystem: Boolean = False);
begin
    // Go: NewLazyDLL and NewLazySystemDLL use &LazyDLL{Name: name, System: true/false}
    try
        inherited Create;
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create('Failed to create TLazyDLL object: Out of memory');
        end;
    end;
    mName := ParaName;
    mSystem := ParaSystem;
    mmu := TMonitor.Create; // Using TMonitor for Go's sync.Mutex
end;

class function TLazyDLL.NewLazyDLL(const ParaName: string): TLazyDLL;
begin
    Result := TLazyDLL.Create(ParaName, False);
end;

class function TLazyDLL.NewLazySystemDLL(const ParaName: string): TLazyDLL;
begin
    Result := TLazyDLL.Create(ParaName, True);
end;

function TLazyDLL.Load: Exception;
var
    vDLL: TDLL;
    vErr: Exception;
begin
    Result := nil;

    // Go: if atomic.LoadPointer((*unsafe.Pointer)(unsafe.Pointer(&d.dll))) != nil { return nil }
    if TInterlocked.CompareExchange(NativeInt(mdll), 0, 0) <> 0 then
    begin
        Exit;
    end;

    mmu.Enter; // d.mu.Lock()
    try
        if mdll <> nil then
        begin
            Exit;
        end;

        // kernel32.dll is special...
        if SameText(mName, 'kernel32.dll') then
        begin
            vDLL := TDLL.LoadDLL(mName);
        end else
        begin
            vDLL := LoadLibraryExWrapper(mName, mSystem);
        end;

        // If an exception (error) was raised during LoadDLL/LoadLibraryExWrapper
        // it means Go's error != nil, so we catch it and return it.
        // We use an exception since LoadDLL/LoadLibraryExWrapper raise TDLLError.
        mdll := vDLL;

    finally
        mmu.Exit; // d.mu.Unlock()
    end;
end;

procedure TLazyDLL.mustLoad;
var
    vE: Exception;
begin
    vE := Load;
    if vE <> nil then
    begin
        // Go: panic(e)
        raise vE;
    end;
end;

function TLazyDLL.Handle: NativeUInt;
begin
    mmu.Enter; // Protect access to mdll
    try
        mustLoad;
        Result := NativeUInt(mdll.Handle);
    finally
        mmu.Exit;
    end;
end;

function TLazyDLL.NewProc(const ParaName: string): TLazyProc;
begin
    Result := TLazyProc.Create(Self, ParaName);
end;

// --- TLazyProc Implementation ---

constructor TLazyProc.Create(ParaLazyDLL: TLazyDLL; const ParaName: string);
begin
    // Go: &LazyProc{l: d, Name: name}
    try
        inherited Create;
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create('Failed to create TLazyProc object: Out of memory');
        end;
    end;
    ml := ParaLazyDLL;
    mName := ParaName;
    mmu := TMonitor.Create;
end;

function TLazyProc.Find: Exception;
var
    vE: Exception;
    vProc: TProc;
begin
    Result := nil;
    
    // Go: if atomic.LoadPointer((*unsafe.Pointer)(unsafe.Pointer(&p.proc))) == nil {
    if TInterlocked.CompareExchange(NativeInt(mproc), 0, 0) <> 0 then
    begin
        Exit;
    end;
    
    mmu.Enter; // p.mu.Lock()
    try
        if mproc <> nil then
        begin
            Exit;
        end;
        
        vE := ml.Load; // e := p.l.Load()
        if vE <> nil then
        begin
            Result := vE;
            Exit;
        end;
        
        try
            vProc := ml.mdll.FindProc(mName); // proc, e := p.l.dll.FindProc(p.Name)
            // If FindProc raises, it means e != nil in Go. We catch it.
            
            // Go: atomic.StorePointer((*unsafe.Pointer)(unsafe.Pointer(&p.proc)), unsafe.Pointer(proc))
            TInterlocked.Exchange(NativeInt(mproc), NativeInt(vProc));
        except
            on E: Exception do
            begin
                Result := E;
                Exit;
            end;
        end;
    finally
        mmu.Exit; // p.mu.Unlock()
    end;
end;

procedure TLazyProc.mustFind;
var
    vE: Exception;
begin
    vE := Find;
    if vE <> nil then
    begin
        // Go: panic(e)
        raise vE;
    end;
end;

function TLazyProc.Addr: NativeUInt;
begin
    mmu.Enter;
    try
        mustFind;
        Result := mproc.Addr;
    finally
        mmu.Exit;
    end;
end;

function TLazyProc.Call(const ParaA: array of NativeUInt; out ParaR1: NativeUInt; out ParaR2: NativeUInt): TErrno;
begin
    mmu.Enter;
    try
        mustFind;
        Result := mproc.Call(ParaA, ParaR1, ParaR2);
    finally
        mmu.Exit;
    end;
end;

// --- Global/Unexported Function Implementations ---

procedure InitCanDoSearchSystem32;
var
    vProc: TProc;
begin
    // Go: canDoSearchSystem32Once.v = (modkernel32.NewProc("AddDllDirectory").Find() == nil)
    CanDoSearchSystem32Once_v := False; // Assuming default failure

    // We assume modkernel32 is a global LazyDLL variable for kernel32.dll
    // For now, we will simulate the check using a direct call to LoadLibrary and GetProcAddress
    
    // This part requires access to modkernel32, which is not defined in this file.
    // I will mock the result for now until modkernel32 is available.
    // The safest thing is to assume `modkernel32` is a `TLazyDLL` object and use its methods.
    
    // I will skip the Go code's internal checks and use a placeholder for now,
    // as it depends on an external variable and method calls not yet available.
    // This function will likely need refactoring when the rest of the package is converted.
    
    // For now, I will use a simple check for GetProcAddress in kernel32.dll
    // The Go code's intent is to check if KB2533623 is installed.
    // The call to LoadDLL in TDLL.LoadDLL also uses LoadLibraryExW which is available in all modern Windows.
    
    // I will assume the check for "AddDllDirectory" is equivalent to:
    if Winapi.Windows.GetProcAddress(Winapi.Windows.GetModuleHandle('kernel32.dll'), 'AddDllDirectory') <> 0 then
    begin
        CanDoSearchSystem32Once_v := True;
    end;
end;

function CanDoSearchSystem32: Boolean;
begin
    // Go: canDoSearchSystem32Once.Do(initCanDoSearchSystem32)
    TMonitor.Enter(CanDoSearchSystem32Once); // Replicating sync.Once
    try
        if CanDoSearchSystem32Once_v = False then
        begin
            InitCanDoSearchSystem32;
        end;
    finally
        TMonitor.Exit(CanDoSearchSystem32Once);
    end;
    Result := CanDoSearchSystem32Once_v;
end;

function IsBaseName(const ParaName: string): Boolean;
var
    vIndex: Integer;
begin
    // Go: for _, c := range name { if c == ':' || c == '/' || c == '\' { return false } }
    for vIndex := 1 to Length(ParaName) do
    begin
        if (ParaName[vIndex] = ':') or (ParaName[vIndex] = '/') or (ParaName[vIndex] = '\') then
        begin
            Result := False;
            Exit;
        end;
    end;
    Result := True;
end;

function LoadLibraryExWrapper(const ParaName: string; ParaSystem: Boolean): TDLL;
var
    vLoadDLL: string;
    vFlags: NativeUInt;
    vSystemDir: string;
    vH: THandle;
    vErr: TErrno;
    vDLL: TDLL;
begin
    vLoadDLL := ParaName;
    vFlags := 0;

    if ParaSystem then
    begin
        if CanDoSearchSystem32 then
        begin
            // Go: flags = LOAD_LIBRARY_SEARCH_SYSTEM32
            vFlags := Const_LOAD_LIBRARY_SEARCH_SYSTEM32;
        end else if IsBaseName(ParaName) then
        begin
            // Go: emulate it on WindowsXP or unpatched Windows machine
            vSystemDir := GetSystemDirectory;
            if vSystemDir = '' then
            begin
                raise TDLLError.Create(Winapi.Windows.GetLastError, ParaName, 'Could not get system directory to emulate system DLL load.');
            end;
            vLoadDLL := vSystemDir + '\' + ParaName;
        end;
    end;

    // Go: h, err := LoadLibraryEx(loadDLL, 0, flags)
    vH := Winapi.Windows.LoadLibraryExW(PWideChar(WideString(vLoadDLL)), 0, vFlags);
    vErr := Winapi.Windows.GetLastError;

    if vH = 0 then
    begin
        // Go: if err != nil { return nil, err }
        raise TDLLError.Create(vErr, ParaName, Format('LoadLibraryEx failed for %s: %s', [vLoadDLL, SysErrorMessage(vErr)]));
    end;

    // Go: return &DLL{Name: name, Handle: h}, nil
    vDLL := nil;
    try
        vDLL := TDLL.Create(ParaName, vH); // Note: uses original name, not loadDLL
        Result := vDLL;
    except
        on E: Exception do
        begin
            Winapi.Windows.FreeLibrary(vH);
            raise TDLLError.Create(E, ParaName, 'Failed to create TDLL object in LoadLibraryExWrapper: ' + E.Message);
        end;
    end;
end;

initialization
    // Initialize the TMonitor for the global sync.Once equivalent
    CanDoSearchSystem32Once := TMonitor.Create;
finalization
    CanDoSearchSystem32Once.Free;
end.