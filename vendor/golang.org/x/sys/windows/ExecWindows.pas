{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.ExecWindows;

interface

// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Fork, exec, wait, etc.

{$IFDEF FPC}
uses
  SysUtils,
  SystemClasses,
  Vendor.Golang.Org.X.Sys.Windows.Syscall,
  Vendor.Golang.Org.X.Sys.Windows.TypesWindows // Assuming Handle is defined here
;
{$ELSE}
uses
  System.SysUtils,
  System.Classes,
  System.Math,
  Winapi.Windows, // For HANDLE_FLAG_INHERIT, Pointer, LongBool
  Vendor.Golang.Org.X.Sys.Windows.Syscall, // For THandle, TErrno
  Vendor.Golang.Org.X.Sys.Internal.Unsafeheader // For TSliceHeader (internal conversion)
;
{$ENDIF}

type
    // Aliases for types
    THandle = Vendor.Golang.Org.X.Sys.Windows.Syscall.THandle;
    TErrno = Vendor.Golang.Org.X.Sys.Windows.Syscall.TErrno;
    TStringArray = TArray<string>;

    // ProcThreadAttributeListContainer is an exported type in Go, used for managing a list of process and thread attributes.
    // It is internal to the package's logic but its type is exported.
    TProcThreadAttributeListContainer = class
    private
        mdata: Pointer; // *ProcThreadAttributeList is represented as a raw Pointer
        mHeapAllocations: TArray<Pointer>; // Go's []Handle, stored as Pointer for LocalAlloc results

        // Helper to mimic Go's internal slice header for unsafe operations
        function GetSliceHeader(ParaPtr: Pointer; ParaSize: NativeUInt): Vendor.Golang.Org.X.Sys.Internal.Unsafeheader.TSliceHeader;
    public
        // NewProcThreadAttributeList allocates a new ProcThreadAttributeListContainer, with the requested maximum number of attributes.
        class function NewProcThreadAttributeList(ParaMaxAttrCount: Cardinal): TProcThreadAttributeListContainer;

        // Update modifies the ProcThreadAttributeList using UpdateProcThreadAttribute.
        function Update(ParaAttribute: NativeUInt; ParaValue: Pointer; ParaSize: NativeUInt): TErrno;

        // Delete frees ProcThreadAttributeList's resources.
        procedure Delete;
        
        // List returns the actual ProcThreadAttributeList (as Pointer) to be passed to StartupInfoEx.
        function List: Pointer;
    end;

// Exported functions (Go capitalized functions)

// EscapeArg rewrites command line argument s as prescribed in http://msdn.microsoft.com/en-us/library/ms880421.
function EscapeArg(const ParaS: string): string;

// ComposeCommandLine escapes and joins the given arguments suitable for use as a Windows command line.
function ComposeCommandLine(const ParaArgs: TStringArray): string;

// DecomposeCommandLine breaks apart its argument command line into unescaped parts using CommandLineToArgv.
function DecomposeCommandLine(const ParaCommandLine: string; out ParaArgs: TStringArray): TErrno;

// CloseOnExec sets the HANDLE_FLAG_INHERIT flag to 0 for the given handle.
procedure CloseOnExec(ParaFd: THandle);

// FullPath retrieves the full path of the specified file.
function FullPath(const ParaName: string; out ParaPath: string): TErrno;

implementation

uses
    // Other system-level units for WinAPI calls
    System.StrUtils;

const
    // Constants from WinAPI that are not in Go code but needed for implementation
    Const_ERROR_INSUFFICIENT_BUFFER = 122;
    Const_LMEM_FIXED = $0000;
    Const_HANDLE_FLAG_INHERIT = 1;

// --- WinAPI/Syscall Wrappers (Assumed to be defined in Syscall/Core Windows units) ---

// Assuming these are implemented in the Syscall unit or are direct WinAPI calls.
// The Go source implies these are low-level WinAPI functions.

function CommandLineToArgv(lpCmdLine: PWideChar; out pNumArgs: Integer): PWideChar; stdcall; external 'shell32.dll' name 'CommandLineToArgvW';
function LocalFree(hMem: THandle): THandle; stdcall; external 'kernel32.dll' name 'LocalFree';
function SetHandleInformation(hObject: THandle; dwMask: Cardinal; dwFlags: Cardinal): LongBool; stdcall; external 'kernel32.dll' name 'SetHandleInformation';
function GetFullPathName(lpFileName: PWideChar; nBufferLength: Cardinal; lpBuffer: PWideChar; lpFilePart: PWideChar): Cardinal; stdcall; external 'kernel32.dll' name 'GetFullPathNameW';
function InitializeProcThreadAttributeList(lpAttributeList: Pointer; dwAttributeCount: Cardinal; dwFlags: Cardinal; out lpSize: NativeUInt): LongBool; stdcall; external 'kernel32.dll' name 'InitializeProcThreadAttributeList';
function LocalAlloc(uFlags: Cardinal; uBytes: Cardinal): Pointer; stdcall; external 'kernel32.dll' name 'LocalAlloc';
function UpdateProcThreadAttribute(lpAttributeList: Pointer; dwFlags: Cardinal; Attribute: NativeUInt; lpValue: Pointer; cbSize: NativeUInt; lpPreviousValue: Pointer; lpReturnSize: Pointer): LongBool; stdcall; external 'kernel32.dll' name 'UpdateProcThreadAttribute';
procedure DeleteProcThreadAttributeList(lpAttributeList: Pointer); stdcall; external 'kernel32.dll' name 'DeleteProcThreadAttributeList';

function GetLastErrno: TErrno;
begin
    Result := Winapi.Windows.GetLastError;
    if Result = 0 then
        Result := 0;
end;

// Assuming these utility functions are available from other converted units:
function UTF16PtrToString(ParaPtr: PWideChar): string; // From EnvWindows
begin
    Result := ParaPtr;
end;

function StringToUTF16Ptr(const ParaName: string): PWideChar;
begin
    // Assuming this utility is implemented to return a temporary wide string pointer
    Result := PWideChar(WideString(ParaName));
end;

function UTF16PtrFromString(const ParaName: string): PWideChar;
begin
    Result := PWideChar(WideString(ParaName));
end;

// --- Exported Function Implementations ---

function EscapeArg(const ParaS: string): string;
var
    vN: Integer;
    vHasSpace: Boolean;
    vQS: TBytes;
    vJ: Integer;
    vSlashes: Integer;
    vI: Integer;
begin
    if Length(ParaS) = 0 then
    begin
        Result := '""';
        Exit;
    end;

    vN := Length(ParaS);
    vHasSpace := False;

    // Calculate required size vN
    for vI := 1 to Length(ParaS) do
    begin
        case ParaS[vI] of
            '"', '\':
                Inc(vN);
            ' ', #9: // space or tab
                vHasSpace := True;
        end;
    end;

    if vHasSpace then
        Inc(vN, 2);

    if vN = Length(ParaS) then
    begin
        Result := ParaS;
        Exit;
    end;

    SetLength(vQS, vN);
    vJ := 0;
    if vHasSpace then
    begin
        vQS[vJ] := Ord('"');
        Inc(vJ);
    end;

    vSlashes := 0;
    for vI := 1 to Length(ParaS) do
    begin
        case ParaS[vI] of
            ' ':
            begin
                vSlashes := 0;
                vQS[vJ] := Ord(' ');
            end;
            #9:
            begin
                vSlashes := 0;
                vQS[vJ] := Ord(#9);
            end;
            '\':
            begin
                Inc(vSlashes);
                vQS[vJ] := Ord('\');
            end;
            '"':
            begin
                // Escape preceding slashes
                for ; vSlashes > 0; Dec(vSlashes)) do
                begin
                    vQS[vJ] := Ord('\');
                    Inc(vJ);
                end;
                vQS[vJ] := Ord('\'); // Escape the quote itself
                Inc(vJ);
                vQS[vJ] := Ord('"');
            end;
        else
            begin
                vSlashes := 0;
                vQS[vJ] := Ord(ParaS[vI]);
            end;
        end;
        Inc(vJ);
    end;

    if vHasSpace then
    begin
        // Escape trailing slashes
        for ; vSlashes > 0; Dec(vSlashes)) do
        begin
            vQS[vJ] := Ord('\');
            Inc(vJ);
        end;
        vQS[vJ] := Ord('"');
        Inc(vJ);
    end;

    // Convert TBytes back to string
    SetLength(vQS, vJ);
    Result := TEncoding.GetEncoding(0).GetString(vQS); // Assumes ANSI/UTF8 encoding for Go's []byte
end;

function ComposeCommandLine(const ParaArgs: TStringArray): string;
var
    vCommandLine: string;
    vI: Integer;
begin
    vCommandLine := '';
    for vI := Low(ParaArgs) to High(ParaArgs) do
    begin
        if vI > Low(ParaArgs) then
        begin
            vCommandLine := vCommandLine + ' ';
        end;
        vCommandLine := vCommandLine + EscapeArg(ParaArgs[vI]);
    end;
    Result := vCommandLine;
end;

function DecomposeCommandLine(const ParaCommandLine: string; out ParaArgs: TStringArray): TErrno;
var
    vArgC: Integer;
    vArgV: PWideChar;
    vErr: TErrno;
    vI: Integer;
    vStringPtrs: ^PWideChar; // The result is a pointer to an array of PWideChar
begin
    ParaArgs := TStringArray.Create;

    if Length(ParaCommandLine) = 0 then
    begin
        Result := 0; // Success
        Exit;
    end;

    // Go: argv, err := CommandLineToArgv(StringToUTF16Ptr(commandLine), &argc)
    vArgV := CommandLineToArgv(StringToUTF16Ptr(ParaCommandLine), vArgC);
    vErr := GetLastErrno;

    if vArgV = nil then
    begin
        Result := vErr;
        Exit;
    end;

    // Go: defer LocalFree(Handle(unsafe.Pointer(argv)))
    // Set up cleanup block (defer equivalent)
    try
        // Go: for _, v := range (*argv)[:argc]
        // vArgV is actually a pointer to the start of an array of pointers (PWideChar)
        vStringPtrs := Pointer(vArgV);
        SetLength(ParaArgs, vArgC);

        for vI := 0 to vArgC - 1 do
        begin
            // Go: args = append(args, UTF16ToString((*v)[:]))
            ParaArgs[vI] := UTF16PtrToString(vStringPtrs[vI]);
        end;

        Result := 0; // Success
    finally
        // Cleanup with LocalFree
        LocalFree(THandle(vArgV));
    end;
end;

procedure CloseOnExec(ParaFd: THandle);
begin
    // Go: SetHandleInformation(Handle(fd), HANDLE_FLAG_INHERIT, 0)
    // We assume the caller is interested in the result of SetHandleInformation
    // but the Go function does not return an error, so we suppress it.
    SetHandleInformation(ParaFd, Const_HANDLE_FLAG_INHERIT, 0);
end;

function FullPath(const ParaName: string; out ParaPath: string): TErrno;
var
    vP: PWideChar;
    vN: Cardinal;
    vBuf: array of Word; // []uint16
    vBufLen: Cardinal;
    vErr: TErrno;
begin
    ParaPath := '';
    vP := UTF16PtrFromString(ParaName);

    // Initial buffer size
    vN := 100;
    while True do
    begin
        vBufLen := vN;
        try
            SetLength(vBuf, vBufLen);
        except
            on E: EOutOfMemory do
            begin
                Result := Winapi.Windows.ERROR_OUTOFMEMORY;
                Exit;
            end;
        end;

        // Go: n, err = GetFullPathName(p, uint32(len(buf)), &buf[0], nil)
        vN := GetFullPathName(vP, vBufLen, @vBuf[0], nil);
        vErr := GetLastErrno;

        if vErr <> 0 then
        begin
            // Go: if err != nil { return "", err }
            Result := vErr;
            Exit;
        end;

        if vN <= vBufLen then
        begin
            // Go: return UTF16ToString(buf[:n]), nil
            // The result includes the null terminator, but the string is up to n-1
            ParaPath := UTF16PtrToString(@vBuf[0]);
            Result := 0; // Success
            Exit;
        end;
        
        // The buffer was too small, resize and try again
        vN := vN; // next size is returned in vN
        // vN is guaranteed to be > 0 and the required buffer size
        if vN > $FFFFFFFF div SizeOf(Word) then
        begin
            Result := Winapi.Windows.ERROR_INVALID_PARAMETER; // Arbitrary error for too large size
            Exit;
        end;
    end;
end;

// --- TProcThreadAttributeListContainer Implementation ---

// TSliceHeader is assumed to be defined/imported from Vendor.Golang.Org.X.Sys.Internal.Unsafeheader
function TProcThreadAttributeListContainer.GetSliceHeader(ParaPtr: Pointer; ParaSize: NativeUInt): Vendor.Golang.Org.X.Sys.Internal.Unsafeheader.TSliceHeader;
begin
    Result.Data := ParaPtr;
    Result.Len := Integer(ParaSize);
    Result.Cap := Integer(ParaSize);
end;

class function TProcThreadAttributeListContainer.NewProcThreadAttributeList(ParaMaxAttrCount: Cardinal): TProcThreadAttributeListContainer;
var
    vSize: NativeUInt;
    vErr: TErrno;
    vData: array of Byte;
    vAL: TProcThreadAttributeListContainer;
begin
    vSize := 0;
    
    // Go: err := initializeProcThreadAttributeList(nil, maxAttrCount, 0, &size)
    InitializeProcThreadAttributeList(nil, ParaMaxAttrCount, 0, vSize);
    vErr := GetLastErrno;

    if vErr <> Const_ERROR_INSUFFICIENT_BUFFER then
    begin
        // Go: if err == nil { return nil, errorspkg.New("unable to query buffer size...") }
        if vErr = 0 then
        begin
            // This is an unexpected scenario from Go's perspective (it expects an error)
            raise Exception.Create('Unable to query buffer size from InitializeProcThreadAttributeList (expected insufficient buffer error, got success).');
        end;
        
        // Go: return nil, err
        raise Exception.CreateFmt('InitializeProcThreadAttributeList failed to get size: %d', [vErr]);
    end;

    // Go: al := &ProcThreadAttributeListContainer{data: (*ProcThreadAttributeList)(unsafe.Pointer(&make([]byte, size)[0]))}
    SetLength(vData, vSize);
    vAL := nil;
    try
        vAL := TProcThreadAttributeListContainer.Create;
        vAL.mdata := @vData[0];
        // Ensure vData array is not released before vAL.mdata is initialized
    except
        on E: EOutOfMemory do
        begin
            raise Exception.Create('Failed to allocate memory for attribute list data: Out of memory');
        end;
    end;

    // Go: err = initializeProcThreadAttributeList(al.data, maxAttrCount, 0, &size)
    if not InitializeProcThreadAttributeList(vAL.mdata, ParaMaxAttrCount, 0, vSize) then
    begin
        vErr := GetLastErrno;
        vAL.Free;
        raise Exception.CreateFmt('InitializeProcThreadAttributeList failed to initialize list: %d', [vErr]);
    end;

    Result := vAL;
end;

function TProcThreadAttributeListContainer.Update(ParaAttribute: NativeUInt; ParaValue: Pointer; ParaSize: NativeUInt): TErrno;
var
    vAlloc: Pointer;
    vErr: TErrno;
    vSrcHeader, vDstHeader: Vendor.Golang.Org.X.Sys.Internal.Unsafeheader.TSliceHeader;
begin
    // Go: alloc, err := LocalAlloc(LMEM_FIXED, uint32(size))
    vAlloc := LocalAlloc(Const_LMEM_FIXED, Cardinal(ParaSize));
    if vAlloc = nil then
    begin
        vErr := GetLastErrno;
        Result := vErr;
        Exit;
    end;

    // Go: copy(dst, src) -- using unsafeheader/slice manipulation to copy data
    // Assuming unsafeheader.TSliceHeader is correctly defined and allows pointer manipulation
    vSrcHeader := GetSliceHeader(ParaValue, ParaSize);
    vDstHeader := GetSliceHeader(vAlloc, ParaSize);
    
    // Manual copy of bytes from ParaValue (source) to vAlloc (destination)
    System.Move(vSrcHeader.Data^, vDstHeader.Data^, ParaSize);
    
    // Go: al.heapAllocations = append(al.heapAllocations, alloc)
    SetLength(mHeapAllocations, Length(mHeapAllocations) + 1);
    mHeapAllocations[High(mHeapAllocations)] := vAlloc;
    
    // Go: return updateProcThreadAttribute(al.data, 0, attribute, unsafe.Pointer(alloc), size, nil, nil)
    if not UpdateProcThreadAttribute(mdata, 0, ParaAttribute, vAlloc, ParaSize, nil, nil) then
    begin
        vErr := GetLastErrno;
        Result := vErr;
    end else
    begin
        Result := 0; // Success
    end;
end;

procedure TProcThreadAttributeListContainer.Delete;
var
    vI: Integer;
begin
    // Go: deleteProcThreadAttributeList(al.data)
    DeleteProcThreadAttributeList(mdata);
    
    // Go: for i := range al.heapAllocations { LocalFree(Handle(al.heapAllocations[i])) }
    for vI := Low(mHeapAllocations) to High(mHeapAllocations) do
    begin
        LocalFree(THandle(mHeapAllocations[vI]));
    end;

    // Go: al.heapAllocations = nil
    SetLength(mHeapAllocations, 0);
    // mData is implicitly freed with the TProcThreadAttributeListContainer object when it goes out of scope,
    // but the Go code does not explicitly destroy the container, only the list resources.
    // In Delphi, the container object itself should be freed by the user. This function cleans up the WinAPI resources.
end;

function TProcThreadAttributeListContainer.List: Pointer;
begin
    Result := mdata;
end;

end.