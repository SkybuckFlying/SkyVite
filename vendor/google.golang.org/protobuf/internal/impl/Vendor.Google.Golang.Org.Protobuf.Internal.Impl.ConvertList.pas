unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.ConvertList;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

function NewListConverter(T: TRttiType; FD: IFieldDescriptor): IConverter;

implementation

type
  TListReflect = class(TInterfacedObject, IList, IUnwrapper)
  private
    FV: TValue; // *[]T
    FConv: IConverter;
  public
    constructor Create(const V: TValue; const Conv: IConverter);
    function Len: Integer;
    function Get(I: Integer): TValue;
    procedure Set_(I: Integer; const V: TValue);
    procedure Append(const V: TValue);
    function AppendMutable: TValue;
    procedure Truncate(I: Integer);
    function NewElement: TValue;
    function IsValid: Boolean;
    function ProtoUnwrap: TValue;
  end;

{ TListReflect }

constructor TListReflect.Create(const V: TValue; const Conv: IConverter);
begin
  FV := V;
  FConv := Conv;
end;

function TListReflect.Len: Integer;
begin
  if FV.IsNil then Exit(0);
  Result := FV.Elem.GetArrayLength;
end;

function TListReflect.Get(I: Integer): TValue;
begin
  Result := FConv.PBValueOf(FV.Elem.GetArrayElement(I));
end;

procedure TListReflect.Set_(I: Integer; const V: TValue);
begin
  FV.Elem.SetArrayElement(I, FConv.GoValueOf(V));
end;

procedure TListReflect.Append(const V: TValue);
begin
  // Implementation of dynamic array append in Delphi
end;

function TListReflect.AppendMutable: TValue;
begin
  Result := NewElement;
  Append(Result);
end;

procedure TListReflect.Truncate(I: Integer);
begin
  // Implementation of SetLength in Delphi
end;

function TListReflect.NewElement: TValue;
begin
  Result := FConv.New_;
end;

function TListReflect.IsValid: Boolean;
begin
  Result := not FV.IsNil;
end;

function TListReflect.ProtoUnwrap: TValue;
begin
  Result := FV;
end;

function NewListConverter(T: TRttiType; FD: IFieldDescriptor): IConverter;
begin
  // ... similar to Go version
  Result := nil;
end;

end.
