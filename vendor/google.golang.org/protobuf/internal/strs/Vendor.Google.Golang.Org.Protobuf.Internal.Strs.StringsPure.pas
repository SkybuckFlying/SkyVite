unit Vendor.Google.Golang.Org.Protobuf.Internal.Strs.StringsPure;

interface

uses
  System.SysUtils, Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

function UnsafeString(const B: TBytes): string;
function UnsafeBytes(const S: string): TBytes;

type
  TStrsBuilder = record
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
