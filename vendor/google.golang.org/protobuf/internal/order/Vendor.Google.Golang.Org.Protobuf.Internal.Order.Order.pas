unit Vendor.Google.Golang.Org.Protobuf.Internal.Order.Order;

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  TFieldOrder = TFunc<IFieldDescriptor, IFieldDescriptor, Boolean>;

var
  AnyFieldOrder: TFieldOrder;
  LegacyFieldOrder: TFieldOrder;
  NumberFieldOrder: TFieldOrder;
  IndexNameFieldOrder: TFieldOrder;

type
  TKeyOrder = TFunc<IMapKey, IMapKey, Boolean>;

var
  AnyKeyOrder: TKeyOrder;
  GenericKeyOrder: TKeyOrder;

implementation

initialization
  AnyFieldOrder := nil;
  
  LegacyFieldOrder := function(X, Y: IFieldDescriptor): Boolean
  var
    OX, OY: IOneofDescriptor;
    InOneof: TFunc<IOneofDescriptor, Boolean>;
  begin
    OX := X.ContainingOneof;
    OY := Y.ContainingOneof;
    InOneof := function(OD: IOneofDescriptor): Boolean
    begin
      Result := (OD <> nil) and not OD.IsSynthetic;
    end;

    if X.IsExtension <> Y.IsExtension then
      Exit(X.IsExtension and not Y.IsExtension);
    
    if InOneof(OX) <> InOneof(OY) then
      Exit(not InOneof(OX) and InOneof(OY));
      
    if (OX <> nil) and (OY <> nil) and (OX <> OY) then
      Exit(OX.Index < OY.Index);
      
    Result := X.Number < Y.Number;
  end;

  NumberFieldOrder := function(X, Y: IFieldDescriptor): Boolean
  begin
    Result := X.Number < Y.Number;
  end;

  // ... rest of the orders

end.
