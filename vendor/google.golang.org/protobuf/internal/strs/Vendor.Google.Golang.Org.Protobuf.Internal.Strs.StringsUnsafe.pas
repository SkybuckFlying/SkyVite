unit Vendor.Google.Golang.Org.Protobuf.Internal.Strs.StringsUnsafe;

interface

uses
  System.SysUtils, Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

// In Delphi, strings are managed and have different memory layout than Go.
// True "unsafe" sharing between string and TBytes is tricky.
// For the purpose of this conversion, we use standard conversions.

function UnsafeString(const B: TBytes): string;
function UnsafeBytes(const S: string): TBytes;

type
  TStrsBuilder = record
  private
    FBuf: TBytes;
  public
    function AppendFullName(const Prefix: TFullName; const Name: TName): TFullName;
    function MakeString(const B: TBytes): string;
  end;

implementation

function UnsafeString(const B: TBytes): string;
begin
  Result := TEncoding.UTF8.GetString(B);
end;

function UnsafeBytes(const S: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(S);
end;

function TStrsBuilder.AppendFullName(const Prefix: TFullName; const Name: TName): TFullName;
begin
  Result := Prefix.Append(Name);
end;

function TStrsBuilder.MakeString(const B: TBytes): string;
begin
  Result := TEncoding.UTF8.GetString(B);
end;

end.
