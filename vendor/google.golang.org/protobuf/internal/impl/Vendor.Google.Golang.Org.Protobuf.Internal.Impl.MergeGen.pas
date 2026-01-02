unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.MergeGen;

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Merge;

procedure MergeBool(Dst, Src: TPointer; F: PCoderFieldInfo; const Opts: TMergeOptions);
procedure MergeInt32(Dst, Src: TPointer; F: PCoderFieldInfo; const Opts: TMergeOptions);

implementation

procedure MergeBool(Dst, Src: TPointer; F: PCoderFieldInfo; const Opts: TMergeOptions);
begin
  Dst.Bool^ := Src.Bool^;
end;

procedure MergeInt32(Dst, Src: TPointer; F: PCoderFieldInfo; const Opts: TMergeOptions);
begin
  Dst.Int32^ := Src.Int32^;
end;

// ... other scalar merge functions

end.
