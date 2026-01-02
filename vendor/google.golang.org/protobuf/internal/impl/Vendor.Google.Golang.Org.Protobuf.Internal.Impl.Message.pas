unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Message;

interface

uses
  System.SysUtils, System.Rtti, System.SyncObjs, System.SyncWait,
  Vendor.Google.Golang.Org.Protobuf.Internal.Genid,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry;

type
  TExporter = TFunc<TValue, Integer, TValue>;

  TMessageInfo = class
  public
    GoReflectType: TRttiType;
    Desc: IMessageDescriptor;
    Exporter: TExporter;
    OneofWrappers: TArray<TValue>;
    
    FInitMu: TCriticalSection;
    FInitDone: UInt32;

    constructor Create;
    destructor Destroy; override;
    procedure Init;
    procedure InitOnce;
    function GetPointer(M: IMessage; out OK: Boolean): TPointer;
    function New_: IMessage;
    function Zero: IMessage;
    function Descriptor: IMessageDescriptor;
    function MessageOf(M: TValue): IMessage;
  end;

function GetMessageInfo(MT: TRttiType): TMessageInfo;

implementation

constructor TMessageInfo.Create;
begin
  FInitMu := TCriticalSection.Create;
end;

destructor TMessageInfo.Destroy;
begin
  FInitMu.Free;
  inherited;
end;

procedure TMessageInfo.Init;
begin
  if TInterlocked.Read(FInitDone) = 0 then
    InitOnce;
end;

procedure TMessageInfo.InitOnce;
begin
  FInitMu.Enter;
  try
    if FInitDone = 1 then Exit;
    // Initialization logic...
    TInterlocked.Exchange(FInitDone, 1);
  finally
    FInitMu.Leave;
  end;
end;

function TMessageInfo.GetPointer(M: IMessage; out OK: Boolean): TPointer;
begin
  // Implementation of GetPointer
  OK := False;
  Result := Default(TPointer);
end;

function TMessageInfo.New_: IMessage;
begin
  Result := MessageOf(TValue.From(GoReflectType.AsInstance.MetaclassType.Create)); // Simplified
end;

function TMessageInfo.Zero: IMessage;
begin
  Result := MessageOf(TValue.Empty);
end;

function TMessageInfo.Descriptor: IMessageDescriptor;
begin
  Result := Desc;
end;

function TMessageInfo.MessageOf(M: TValue): IMessage;
begin
  // Implementation of MessageOf
  Result := nil;
end;

function GetMessageInfo(MT: TRttiType): TMessageInfo;
begin
  // Implementation of GetMessageInfo
  Result := nil;
end;

end.
