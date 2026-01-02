unit Vendor.Google.Golang.Org.Protobuf.Internal.Order.Range;

interface

uses
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Internal.Order.Order;

type
  TVisitField = TFunc<IFieldDescriptor, TValue, Boolean>;
  
  IFieldRanger = interface
    ['{F1E2D3C4-B5A6-47D8-9C0B-1A2B3C4D5E6F}']
    procedure Range(const FN: TVisitField);
  end;

procedure RangeFields(FS: IFieldRanger; Less: TFieldOrder; const FN: TVisitField);

implementation

type
  TMessageField = record
    FD: IFieldDescriptor;
    V: TValue;
  end;

procedure RangeFields(FS: IFieldRanger; Less: TFieldOrder; const FN: TVisitField);
var
  Fields: TList<TMessageField>;
  F: TMessageField;
begin
  if Less = nil then
  begin
    FS.Range(FN);
    Exit;
  end;

  Fields := TList<TMessageField>.Create;
  try
    FS.Range(function(FD: IFieldDescriptor; V: TValue): Boolean
    begin
      Fields.Add(TMessageField.Create(FD, V));
      Result := True;
    end);
    
    Fields.Sort(TDelegatedComparer<TMessageField>.Construct(
      function(const L, R: TMessageField): Integer
      begin
        if Less(L.FD, R.FD) then Result := -1
        else if Less(R.FD, L.FD) then Result := 1
        else Result := 0;
      end));

    for F in Fields do
    begin
      if not FN(F.FD, F.V) then break;
    end;
  finally
    Fields.Free;
  end;
end;

end.
