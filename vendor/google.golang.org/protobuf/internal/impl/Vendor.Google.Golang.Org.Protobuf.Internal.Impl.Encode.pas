unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Encode;

interface

uses
  System.SysUtils, System.Math, System.SyncWait,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Flags,
  Vendor.Google.Golang.Org.Protobuf.Proto,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TMarshalOptions = record
    Flags: TMarshalInputFlags;
    function Options: TMarshalOptions;
    function Deterministic: Boolean;
    function UseCachedSize: Boolean;
  end;

  TMessageInfoHelper = class helper for TMessageInfo
  public
    function Size(const In_: TSizeInput): TSizeOutput;
    function SizePointer(P: TPointer; const Opts: TMarshalOptions): Integer;
    function SizePointerSlow(P: TPointer; const Opts: TMarshalOptions): Integer;
    function Marshal(const In_: TMarshalInput): TMarshalOutput;
    function MarshalAppendPointer(B: TBytes; P: TPointer; const Opts: TMarshalOptions): TBytes;
  end;

implementation

{ TMarshalOptions }

function TMarshalOptions.Options: TMarshalOptions;
begin
  Result := Default(TMarshalOptions); // Simplified
end;

function TMarshalOptions.Deterministic: Boolean;
begin
  Result := (Flags and TMarshalFlags.MarshalDeterministic) <> 0;
end;

function TMarshalOptions.UseCachedSize: Boolean;
begin
  Result := (Flags and TMarshalFlags.MarshalUseCachedSize) <> 0;
end;

{ TMessageInfoHelper }

function TMessageInfoHelper.Size(const In_: TSizeInput): TSizeOutput;
var
  P: TPointer;
  Opts: TMarshalOptions;
begin
  if In_.Message is TMessageState then
    P := TMessageState(In_.Message).Pointer
  else
    P := TMessageReflectWrapper(In_.Message).Pointer;

  Opts.Flags := In_.Flags;
  Result.Size := Self.SizePointer(P, Opts);
end;

function TMessageInfoHelper.SizePointer(P: TPointer; const Opts: TMarshalOptions): Integer;
var
  Cached: Int32;
begin
  Self.Init;
  if P.IsNil then Exit(0);
  if Opts.UseCachedSize and Self.SizecacheOffset.IsValid then
  begin
    Cached := TInterlocked.Read(P.Apply(Self.SizecacheOffset).Int32^);
    if Cached >= 0 then Exit(Cached);
  end;
  Result := Self.SizePointerSlow(P, Opts);
end;

function TMessageInfoHelper.SizePointerSlow(P: TPointer; const Opts: TMarshalOptions): Integer;
var
  Size: Integer;
  F: PCoderFieldInfo;
  FPtr: TPointer;
  U: PBytes;
begin
  if TFlags.ProtoLegacy and Self.IsMessageSet then
  begin
    Size := SizeMessageSet(Self, P, Opts);
    if Self.SizecacheOffset.IsValid then
      TInterlocked.Exchange(P.Apply(Self.SizecacheOffset).Int32^, Size);
    Exit(Size);
  end;

  Size := 0;
  if Self.ExtensionOffset.IsValid then
  begin
    // Size += sizeExtensions
  end;

  for F in Self.OrderedCoderFields do
  begin
    if not Assigned(F.Funcs.Size) then continue;
    FPtr := P.Apply(F.Offset);
    if F.IsPointer and FPtr.Elem.IsNil then continue;
    Size := Size + F.Funcs.Size(FPtr, F, Opts);
  end;

  if Self.UnknownOffset.IsValid then
  begin
    U := Self.GetUnknownBytes(P);
    if U <> nil then
      Size := Size + Length(U^);
  end;

  if Self.SizecacheOffset.IsValid then
  begin
    if Size > MaxInt then // Simplified check
      TInterlocked.Exchange(P.Apply(Self.SizecacheOffset).Int32^, -1)
    else
      TInterlocked.Exchange(P.Apply(Self.SizecacheOffset).Int32^, Size);
  end;
  Result := Size;
end;

function TMessageInfoHelper.Marshal(const In_: TMarshalInput): TMarshalOutput;
var
  P: TPointer;
  Opts: TMarshalOptions;
  B: TBytes;
  Err: Error;
begin
  if In_.Message is TMessageState then
    P := TMessageState(In_.Message).Pointer
  else
    P := TMessageReflectWrapper(In_.Message).Pointer;

  Opts.Flags := In_.Flags;
  B := Self.MarshalAppendPointer(In_.Buf, P, Opts);
  Result.Buf := B;
end;

function TMessageInfoHelper.MarshalAppendPointer(B: TBytes; P: TPointer; const Opts: TMarshalOptions): TBytes;
var
  F: PCoderFieldInfo;
  FPtr: TPointer;
  U: PBytes;
begin
  Self.Init;
  if P.IsNil then Exit(B);
  if TFlags.ProtoLegacy and Self.IsMessageSet then
    Exit(MarshalMessageSet(Self, B, P, Opts));

  if Self.ExtensionOffset.IsValid then
  begin
    // B := appendExtensions
  end;

  for F in Self.OrderedCoderFields do
  begin
    if not Assigned(F.Funcs.Marshal) then continue;
    FPtr := P.Apply(F.Offset);
    if F.IsPointer and FPtr.Elem.IsNil then continue;
    B := F.Funcs.Marshal(B, FPtr, F, Opts);
  end;

  if Self.UnknownOffset.IsValid and not Self.IsMessageSet then
  begin
    U := Self.GetUnknownBytes(P);
    if U <> nil then
      B := B + U^;
  end;
  Result := B;
end;

end.
