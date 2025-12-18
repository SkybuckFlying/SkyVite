unit VM.ABI.Unpack;

interface

uses
  GoVite.Types GoVite.Common.Helper,
  System.SysUtils System.Generics.Collections System.BigInt,
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.ABI.Argument,
  VM.ABI.Error,
  VM.ABI.Event,
  VM.ABI.Event.Test,
  VM.ABI.Method,
  VM.ABI.Numbers,
  VM.ABI.Numbers.Test,
  VM.ABI.Pack,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.ABI.Type,
  VM.ABI.Type.Test,
  VM.ABI.Types,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

function ReadInteger(AKind: TTypeKind; const ABytes: TBytes): TValue;
function ReadBool(const AWord: TBytes): Boolean;
function ReadFixedBytes(const AType: TAbiType; const AWord: TBytes): TValue;
function GetFullElemSize(AElem: TAbiType): Integer;
function ForEachUnpack(const AType: TAbiType; const AOutput: TBytes; AStart, ASize: Integer): TValue;
function ToGoType(AIndex: Integer; const AType: TAbiType; const AOutput: TBytes): TValue;
function LengthPrefixPointsTo(AIndex: Integer; const AOutput: TBytes; out AStart, ALength: Integer): Boolean;

implementation

uses
  System.Rtti, System.NetEncoding;

function ReadInteger(AKind: TTypeKind; const ABytes: TBytes): TValue;
begin
  // Implementation depends on TValue and how it can hold different integer types.
  // This is a simplified version.
  Result := TValue.From<TBigInteger>(TBigInteger.FromBytes(ABytes));
end;

function ReadBool(const AWord: TBytes): Boolean;
begin
  // Implementation
  Result := False;
end;

// ... other implementations ...

end.
