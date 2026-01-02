unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Decode;

interface

uses
  System.SysUtils, System.Math,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Internal.Flags,
  Vendor.Google.Golang.Org.Protobuf.Proto,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TUnmarshalOptions = record
    Flags: TUnmarshalInputFlags;
    Resolver: IExtensionResolver;
    function Options: TUnmarshalOptions;
    function DiscardUnknown: Boolean;
    function IsDefault: Boolean;
  end;

  TUnmarshalOutput = record
    N: Integer;
    Initialized: Boolean;
  end;

var
  ErrDecode: Error;
  ErrUnknown: Error;
  LazyUnmarshalOptions: TUnmarshalOptions;

type
  TMessageInfoHelper = class helper for TMessageInfo
  public
    function Unmarshal(const In_: TUnmarshalInput): TUnmarshalOutput;
    function UnmarshalPointer(B: TBytes; P: TPointer; GroupTag: TFieldNumber; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
    function UnmarshalExtension(B: TBytes; Num: TFieldNumber; WTyp: TWireType; var Exts: TMap<Int32, TExtensionField>; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
  end;

implementation

{ TUnmarshalOptions }

function TUnmarshalOptions.Options: TUnmarshalOptions;
begin
  Result := Default(TUnmarshalOptions); // Simplified
end;

function TUnmarshalOptions.DiscardUnknown: Boolean;
begin
  Result := (Flags and TUnmarshalFlags.UnmarshalDiscardUnknown) <> 0;
end;

function TUnmarshalOptions.IsDefault: Boolean;
begin
  Result := (Flags = 0) and (Resolver = TProtoregistry.GlobalTypes);
end;

{ TMessageInfoHelper }

function TMessageInfoHelper.Unmarshal(const In_: TUnmarshalInput): TUnmarshalOutput;
var
  P: TPointer;
  Opts: TUnmarshalOptions;
begin
  if In_.Message is TMessageState then
    P := TMessageState(In_.Message).Pointer
  else
    P := TMessageReflectWrapper(In_.Message).Pointer;

  Opts.Flags := In_.Flags;
  Opts.Resolver := In_.Resolver;

  Self.UnmarshalPointer(In_.Buf, P, 0, Opts, Result);
end;

function TMessageInfoHelper.UnmarshalPointer(B: TBytes; P: TPointer; GroupTag: TFieldNumber; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
var
  Initialized: Boolean;
  RequiredMask: UInt64;
  Exts: PMap<Int32, TExtensionField>;
  Start, N, TagLen: Integer;
  Tag: UInt64;
  Num: TFieldNumber;
  WTyp: TWireType;
  F: PCoderFieldInfo;
  O: TUnmarshalOutput;
  U: PBytes;
begin
  Self.Init;
  if TFlags.ProtoLegacy and Self.IsMessageSet then
    Exit(UnmarshalMessageSet(Self, B, P, Opts, Out_));

  Initialized := True;
  RequiredMask := 0;
  Exts := nil;
  Start := Length(B);

  while Length(B) > 0 do
  begin
    if B[0] < $80 then
    begin
      Tag := B[0];
      TagLen := 1;
    end
    else if (Length(B) >= 2) and (B[1] < 128) then
    begin
      Tag := (B[0] and $7F) or (UInt64(B[1]) shl 7);
      TagLen := 2;
    end
    else
    begin
      Tag := TProtowire.ConsumeVarint(B, TagLen);
      if TagLen < 0 then Exit(ErrDecode);
    end;
    B := Copy(B, TagLen, MaxInt);

    Num := TFieldNumber(Tag shr 3);
    if (Num < TProtowire.MinValidNumber) or (Num > TProtowire.MaxValidNumber) then
      Exit(ErrDecode);
    WTyp := TWireType(Tag and 7);

    if WTyp = TWireType.EndGroupType then
    begin
      if Num <> GroupTag then Exit(ErrDecode);
      GroupTag := 0;
      break;
    end;

    if Integer(Num) < Length(Self.DenseCoderFields) then
      F := Self.DenseCoderFields[Num]
    else
      F := Self.CoderFields[Num];

    Result := ErrUnknown;
    if F <> nil then
    begin
      if Assigned(F.Funcs.Unmarshal) then
      begin
        Result := F.Funcs.Unmarshal(B, P.Apply(F.Offset), WTyp, F, Opts, O);
        N := O.N;
        if Result = nil then
        begin
          // RequiredMask |= F.Validation.RequiredBit;
          if Assigned(F.Funcs.IsInit) and not O.Initialized then
            Initialized := False;
        end;
      end;
    end
    else
    begin
      // Possible extension logic
    end;

    if Result <> nil then
    begin
      if Result <> ErrUnknown then Exit(Result);
      N := TProtowire.ConsumeFieldValue(Num, WTyp, B);
      if N < 0 then Exit(ErrDecode);
      if not Opts.DiscardUnknown and Self.UnknownOffset.IsValid then
      begin
        U := Self.MutableUnknownBytes(P);
        U^ := TProtowire.AppendTag(U^, Num, WTyp);
        U^ := U^ + Copy(B, 0, N);
      end;
    end;
    B := Copy(B, N, MaxInt);
  end;

  if GroupTag <> 0 then Exit(ErrDecode);
  if Initialized then Out_.Initialized := True;
  Out_.N := Start - Length(B);
  Result := nil;
end;

initialization
  ErrDecode := TErrors.New('cannot parse invalid wire-format data');
  ErrUnknown := TErrors.New('unknown');
  LazyUnmarshalOptions.Resolver := TProtoregistry.GlobalTypes;

end.
