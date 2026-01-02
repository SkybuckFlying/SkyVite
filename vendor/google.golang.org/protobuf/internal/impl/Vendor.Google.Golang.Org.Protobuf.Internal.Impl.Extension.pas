unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Extension;

interface

uses
  System.SysUtils, System.Rtti, System.SyncObjs, System.SyncWait,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TExtensionInfo = class(TInterfacedObject, IExtensionType)
  private
    const
      Uninitialized = 0;
      DescInit = 1;
      FullInit = 2;
  private
    FInit: UInt32;
    FMu: TCriticalSection;
    FGoType: TRttiType;
    FDesc: TExtensionTypeDescriptor;
    FConv: IConverter;
    FInfo: PExtensionFieldInfo;
  public
    constructor Create;
    destructor Destroy; override;
    function New_: TValue;
    function Zero: TValue;
    function ValueOf(V: TValue): TValue;
    function InterfaceOf(V: TValue): TValue;
    function IsValidValue(V: TValue): Boolean;
    function IsValidInterface(V: TValue): Boolean;
    function TypeDescriptor: IExtensionTypeDescriptor;
    function LazyInit: IConverter;
    procedure LazyInitSlow;
  end;

implementation

{ TExtensionInfo }

constructor TExtensionInfo.Create;
begin
  FMu := TCriticalSection.Create;
end;

destructor TExtensionInfo.Destroy;
begin
  FMu.Free;
  inherited;
end;

function TExtensionInfo.New_: TValue; begin Result := LazyInit.New_; end;
function TExtensionInfo.Zero: TValue; begin Result := LazyInit.Zero; end;
function TExtensionInfo.ValueOf(V: TValue): TValue; begin Result := LazyInit.PBValueOf(V); end;
function TExtensionInfo.InterfaceOf(V: TValue): TValue; begin Result := LazyInit.GoValueOf(V); end;
function TExtensionInfo.IsValidValue(V: TValue): Boolean; begin Result := LazyInit.IsValidPB(V); end;
function TExtensionInfo.IsValidInterface(V: TValue): Boolean; begin Result := LazyInit.IsValidGo(V); end;

function TExtensionInfo.TypeDescriptor: IExtensionTypeDescriptor;
begin
  if TInterlocked.Read(FInit) < DescInit then
    LazyInitSlow;
  Result := FDesc;
end;

function TExtensionInfo.LazyInit: IConverter;
begin
  if TInterlocked.Read(FInit) < FullInit then
    LazyInitSlow;
  Result := FConv;
end;

procedure TExtensionInfo.LazyInitSlow;
begin
  FMu.Enter;
  try
    if FInit = FullInit then Exit;
    // ... initialization logic
    TInterlocked.Exchange(FInit, FullInit);
  finally
    FMu.Leave;
  end;
end;

end.
