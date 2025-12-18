unit VM.ABI.Unpack;

interface

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Common.Helper,
  VM.ABI.Types;

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
