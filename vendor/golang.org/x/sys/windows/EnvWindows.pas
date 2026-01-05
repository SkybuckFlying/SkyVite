{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.EnvWindows;

interface

// Copyright 2010 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Windows environment variables.

{$IFDEF FPC}
uses
  SysUtils,
  SystemClasses,
  Vendor.Golang.Org.X.Sys.Windows.Syscall // For syscall functions and Token
;
{$ELSE}
uses
  System.SysUtils,
  System.Classes,
  Vendor.Golang.Org.X.Sys.Windows.Syscall // For syscall functions and Token
;
{$ENDIF}

type
    // Assuming TToken is defined in Vendor.Golang.Org.X.Sys.Windows.Syscall
    TToken = Vendor.Golang.Org.X.Sys.Windows.Syscall.TToken;
    TErrno = Vendor.Golang.Org.X.Sys.Windows.Syscall.TErrno;
    
    // String array type equivalent to Go's []string
    TStringArray = TArray<string>;

    // Forward declarations for Win32 API wrappers (Go unexported functions used in the module)
    function CreateEnvironmentBlock(out ParaBlock: PWideChar; ParaToken: TToken; ParaInheritExisting: Boolean): TErrno;
    function DestroyEnvironmentBlock(ParaBlock: PWideChar): TErrno;
    function UTF16PtrToString(ParaPtr: PWideChar): string;

// Function equivalents of Go's standard library for environment variables (delegated to syscall package)
function Getenv(const ParaKey: string; out ParaValue: string): Boolean;
function Setenv(const ParaKey: string; const ParaValue: string): TErrno;
procedure Clearenv;
function Environ: TStringArray;
function Unsetenv(const ParaKey: string): TErrno;

// Method for TToken
function Environ(ParaToken: TToken; ParaInheritExisting: Boolean; out ParaEnv: TStringArray): TErrno;

implementation

uses
    System.StrUtils,
    System.Math; // For Min/Max

// --- Win32 API wrappers (Mocks/Proxies for required syscall functions) ---

// Assuming these are implemented elsewhere in the converted code, likely in a Windows-specific unit.
// For now, these are treated as external functions.
function CreateEnvironmentBlock(out ParaBlock: PWideChar; ParaToken: TToken; ParaInheritExisting: Boolean): TErrno;
begin
    // Mock implementation: Should use the underlying WinAPI call
    Result := Vendor.Golang.Org.X.Sys.Windows.Syscall.CreateEnvironmentBlock(ParaBlock, ParaToken, ParaInheritExisting);
end;

function DestroyEnvironmentBlock(ParaBlock: PWideChar): TErrno;
begin
    // Mock implementation: Should use the underlying WinAPI call
    Result := Vendor.Golang.Org.X.Sys.Windows.Syscall.DestroyEnvironmentBlock(ParaBlock);
end;

function UTF16PtrToString(ParaPtr: PWideChar): string;
begin
    // Mock implementation: Should be safe for null-terminated wide strings
    Result := ParaPtr;
end;

// --- Function Implementations (Delegated to Syscall) ---

function Getenv(const ParaKey: string; out ParaValue: string): Boolean;
begin
    // Go: return syscall.Getenv(key)
    Result := Vendor.Golang.Org.X.Sys.Windows.Syscall.Getenv(ParaKey, ParaValue);
end;

function Setenv(const ParaKey: string; const ParaValue: string): TErrno;
begin
    // Go: return syscall.Setenv(key, value)
    Result := Vendor.Golang.Org.X.Sys.Windows.Syscall.Setenv(ParaKey, ParaValue);
end;

procedure Clearenv;
begin
    // Go: syscall.Clearenv()
    Vendor.Golang.Org.X.Sys.Windows.Syscall.Clearenv;
end;

function Environ: TStringArray;
begin
    // Go: return syscall.Environ()
    Result := Vendor.Golang.Org.X.Sys.Windows.Syscall.Environ;
end;

function Unsetenv(const ParaKey: string): TErrno;
begin
    // Go: return syscall.Unsetenv(key)
    Result := Vendor.Golang.Org.X.Sys.Windows.Syscall.Unsetenv(ParaKey);
end;

// --- TToken.Environ Implementation (Go method converted to Delphi function with ParaToken as first parameter) ---

function Environ(ParaToken: TToken; ParaInheritExisting: Boolean; out ParaEnv: TStringArray): TErrno;
var
    vBlock: PWideChar;
    vBlockP: NativeUInt;
    vEntry: string;
    vCurrentErr: TErrno;
    vI: Integer;
begin
    vBlock := nil;
    vCurrentErr := CreateEnvironmentBlock(vBlock, ParaToken, ParaInheritExisting);
    if vCurrentErr <> 0 then
    begin
        ParaEnv := TStringArray.Create;
        Result := vCurrentErr;
        Exit;
    end;

    // Go: defer DestroyEnvironmentBlock(block)
    // In Delphi, we use try..finally to replace defer
    try
        vBlockP := NativeUInt(vBlock);
        
        // Use a TList<string> internally for dynamic array building
        vI := 0;
        SetLength(ParaEnv, 0); // Initialize array as empty dynamic array

        // Loop to extract environment variables from the block
        while True do
        begin
            vEntry := UTF16PtrToString(PWideChar(vBlockP));
            if Length(vEntry) = 0 then
            begin
                Break;
            end;
            
            // Add to the dynamic array
            try
                SetLength(ParaEnv, Length(ParaEnv) + 1);
                ParaEnv[High(ParaEnv)] := vEntry;
            except
                on E: EOutOfMemory do
                begin
                    // Handle allocation failure during SetLength
                    Result := EOutOfMemory.Create('Failed to allocate memory for environment array');
                    Exit; // Exit with error, cleanup in finally
                end;
            end;
            
            // Go: blockp += 2 * (uintptr(len(entry)) + 1)
            // 2 bytes per WideChar, +1 for null terminator
            vBlockP := vBlockP + 2 * (NativeUInt(Length(vEntry)) + 1);
        end;
        
        Result := 0; // Success
    finally
        // Go: defer DestroyEnvironmentBlock(block)
        vCurrentErr := DestroyEnvironmentBlock(vBlock);
        if Result = 0 then
        begin
            Result := vCurrentErr; // Propagate error if destruction failed, only if no other error occurred
        end;
    end;
end;

end.