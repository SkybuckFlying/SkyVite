unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Weak;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry;

type
  TWeakFields = TDictionary<Int32, IProtoMessage>;

  TWeakFieldsHelper = class helper for TWeakFields
  public
    function Get(Num: TFieldNumber; out M: IProtoMessage): Boolean;
    procedure Set_(Num: TFieldNumber; const M: IProtoMessage);
    procedure Clear(Num: TFieldNumber);
  end;

implementation

{ TWeakFieldsHelper }

function TWeakFieldsHelper.Get(Num: TFieldNumber; out M: IProtoMessage): Boolean;
begin
  Result := Self.TryGetValue(Int32(Num), M);
end;

procedure TWeakFieldsHelper.Set_(Num: TFieldNumber; const M: IProtoMessage);
begin
  Self.AddOrSetValue(Int32(Num), M);
end;

procedure TWeakFieldsHelper.Clear(Num: TFieldNumber);
begin
  Self.Remove(Int32(Num));
end;

end.
