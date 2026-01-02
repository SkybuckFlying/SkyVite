unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.MessageReflectField;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  TFieldInfo_ = record
    FieldDesc: IFieldDescriptor;
    Has: TFunc<TPointer, Boolean>;
    Clear: TProc<TPointer>;
    Get: TFunc<TPointer, TValue>;
    Set_: TProc<TPointer, TValue>;
    Mutable: TFunc<TPointer, TValue>;
    NewMessage: TFunc<IMessage>;
    NewField: TFunc<TValue>;
  end;

function FieldInfoForScalar(FD: IFieldDescriptor; FS: TRttiField; X: TExporter): TFieldInfo_;

implementation

function FieldInfoForScalar(FD: IFieldDescriptor; FS: TRttiField; X: TExporter): TFieldInfo_;
var
  Conv: IConverter;
  FieldOffset: TOffset;
begin
  Conv := NewConverter(FS.FieldType, FD);
  FieldOffset := 0; // Simplified

  Result.FieldDesc := FD;
  Result.Has := function(P: TPointer): Boolean
  var
    RV: TValue;
  begin
    if P.IsNil then Exit(False);
    RV := P.Apply(FieldOffset).AsValueOf(FS.FieldType).Elem;
    // switch-case logic for Has
    Result := True; // Simplified
  end;
  
  Result.Get := function(P: TPointer): TValue
  begin
    if P.IsNil then Exit(Conv.Zero);
    Result := Conv.PBValueOf(P.Apply(FieldOffset).AsValueOf(FS.FieldType).Elem);
  end;

  Result.Set_ := procedure(P: TPointer; V: TValue)
  begin
    P.Apply(FieldOffset).AsValueOf(FS.FieldType).Elem.Set_(Conv.GoValueOf(V));
  end;
end;

end.
