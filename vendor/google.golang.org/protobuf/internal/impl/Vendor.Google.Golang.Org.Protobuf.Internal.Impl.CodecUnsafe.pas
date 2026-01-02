unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecUnsafe;

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecGen;

// When using unsafe pointers, we can just treat enum values as int32s.
// In Delphi, we use the corresponding pointer coder functions.

var
  CoderEnumNoZero: TPointerCoderFuncs;
  CoderEnum: TPointerCoderFuncs;
  CoderEnumPtr: TPointerCoderFuncs;
  CoderEnumSlice: TPointerCoderFuncs;
  CoderEnumPackedSlice: TPointerCoderFuncs;

implementation

initialization
  CoderEnumNoZero := CoderInt32NoZero;
  CoderEnum := CoderInt32;
  CoderEnumPtr := CoderInt32Ptr;
  CoderEnumSlice := CoderInt32Slice;
  CoderEnumPackedSlice := CoderInt32PackedSlice;

end.
