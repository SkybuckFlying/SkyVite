unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Merge;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Proto,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TMergeOptions = record
    procedure Merge(Dst, Src: IProtoMessage);
  end;

  TMessageInfoHelper = class helper for TMessageInfo
  public
    function Merge(const In_: TMergeInput): TMergeOutput;
    procedure MergePointer(Dst, Src: TPointer; const Opts: TMergeOptions);
  end;

function MergeScalarValue(Dst, Src: TValue; const Opts: TMergeOptions): TValue;
function MergeBytesValue(Dst, Src: TValue; const Opts: TMergeOptions): TValue;

implementation

{ TMergeOptions }

procedure TMergeOptions.Merge(Dst, Src: IProtoMessage);
begin
  TProto.Merge(Dst, Src);
end;

{ TMessageInfoHelper }

function TMessageInfoHelper.Merge(const In_: TMergeInput): TMergeOutput;
var
  DP, SP: TPointer;
  OK: Boolean;
begin
  DP := Self.GetPointer(In_.Destination, OK);
  if not OK then Exit(Default(TMergeOutput));
  SP := Self.GetPointer(In_.Source, OK);
  if not OK then Exit(Default(TMergeOutput));
  
  Self.MergePointer(DP, SP, Default(TMergeOptions));
  Result.Flags := TMergeFlags.MergeComplete;
end;

procedure TMessageInfoHelper.MergePointer(Dst, Src: TPointer; const Opts: TMergeOptions);
var
  F: PCoderFieldInfo;
  SFPtr: TPointer;
begin
  Self.Init;
  if Dst.IsNil then raise Exception.Create('invalid value: merging into nil message');
  if Src.IsNil then Exit;

  for F in Self.OrderedCoderFields do
  begin
    if not Assigned(F.Funcs.Merge) then continue;
    SFPtr := Src.Apply(F.Offset);
    if F.IsPointer and SFPtr.Elem.IsNil then continue;
    F.Funcs.Merge(Dst.Apply(F.Offset), SFPtr, F, Opts);
  end;
  
  // Extension and Unknown fields merge logic...
end;

function MergeScalarValue(Dst, Src: TValue; const Opts: TMergeOptions): TValue;
begin
  Result := Src;
end;

function MergeBytesValue(Dst, Src: TValue; const Opts: TMergeOptions): TValue;
var
  B: TBytes;
begin
  B := Src.AsType<TBytes>;
  Result := TValue.From<TBytes>(Copy(B, 0, Length(B)));
end;

end.
