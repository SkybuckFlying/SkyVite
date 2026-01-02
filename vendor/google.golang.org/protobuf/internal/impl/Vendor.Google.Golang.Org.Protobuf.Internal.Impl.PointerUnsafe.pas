unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.PointerUnsafe;

interface

uses
  System.SysUtils, System.Rtti, System.SyncWait;

const
  UnsafeEnabled = True;

type
  TPointer_ = Pointer; // Opaque pointer type

  TOffset = UIntPtr;

function OffsetOf(const F: TRttiField; X: TExporter): TOffset;

type
  TPointer = record
    P: Pointer;
    function IsNil: Boolean;
    function Apply(F: TOffset): TPointer;
    function AsValueOf(T: TRttiType): TValue;
    // Scalar accessors
    function Bool: PBoolean;
    function Int32: PInt32;
    function Int64: PInt64;
    function Uint32: PUInt32;
    function Uint64: PUInt64;
    function Float32: PSingle;
    function Float64: PDouble;
    function String_: PString;
    function Bytes: PBytes;
    function Elem: TPointer;
    procedure SetPointer(V: TPointer);
  end;

var
  InvalidOffset: TOffset;
  ZeroOffset: TOffset;

implementation

function OffsetOf(const F: TRttiField; X: TExporter): TOffset;
begin
  Result := TOffset(F.Offset);
end;

{ TPointer }

function TPointer.IsNil: Boolean;
begin
  Result := P = nil;
end;

function TPointer.Apply(F: TOffset): TPointer;
begin
  if IsNil then raise Exception.Create('invalid nil pointer');
  Result.P := Pointer(UIntPtr(P) + UIntPtr(F));
end;

function TPointer.AsValueOf(T: TRttiType): TValue;
begin
  TValue.Make(P, T.Handle, Result);
end;

function TPointer.Bool: PBoolean; begin Result := P; end;
function TPointer.Int32: PInt32; begin Result := P; end;
function TPointer.Int64: PInt64; begin Result := P; end;
function TPointer.Uint32: PUInt32; begin Result := P; end;
function TPointer.Uint64: PUInt64; begin Result := P; end;
function TPointer.Float32: PSingle; begin Result := P; end;
function TPointer.Float64: PDouble; begin Result := P; end;
function TPointer.String_: PString; begin Result := P; end;
function TPointer.Bytes: PBytes; begin Result := P; end;

function TPointer.Elem: TPointer;
begin
  Result.P := PPointer(P)^;
end;

procedure TPointer.SetPointer(V: TPointer);
begin
  PPointer(P)^ := V.P;
end;

initialization
  InvalidOffset := TOffset(!0);
  ZeroOffset := TOffset(0);

end.
