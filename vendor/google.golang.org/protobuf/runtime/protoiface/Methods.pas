{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface.Methods;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Types,
	// Vendor dependencies
	Vendor.Google.Golang.Org.Protobuf.Internal.Pragma,
	Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
	Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry;

// SupportFlags indicate support for optional features.
type
	TSupportFlags = UInt64;

const
	// SupportMarshalDeterministic reports whether MarshalOptions.Deterministic is supported.
	ConstSupportMarshalDeterministic : TSupportFlags = 1 shl 0;

	// SupportUnmarshalDiscardUnknown reports whether UnmarshalOptions.DiscardUnknown is supported.
	ConstSupportUnmarshalDiscardUnknown : TSupportFlags = 1 shl 1;

// MarshalInputFlags configure the marshaler.
// Most flags correspond to fields in proto.MarshalOptions.
type
	TMarshalInputFlags = Byte;

const
	ConstMarshalDeterministic : TMarshalInputFlags = 1 shl 0;
	ConstMarshalUseCachedSize : TMarshalInputFlags = 1 shl 1;

// UnmarshalInputFlags configure the unmarshaler.
// Most flags correspond to fields in proto.UnmarshalOptions.
type
	TUnmarshalInputFlags = Byte;

const
	ConstUnmarshalDiscardUnknown : TUnmarshalInputFlags = 1 shl 0;

// UnmarshalOutputFlags are output from the Unmarshal method.
type
	TUnmarshalOutputFlags = Byte;

const
	// UnmarshalInitialized may be set on return if all required fields are known to be set.
	// If unset, then it does not necessarily indicate that the message is uninitialized,
	// only that its status could not be confirmed.
	ConstUnmarshalInitialized : TUnmarshalOutputFlags = 1 shl 0;

// MergeOutputFlags are output from the Merge method.
type
	TMergeOutputFlags = Byte;

const
	// MergeComplete reports whether the merge was performed.
	// If unset, the merger must have made no changes to the destination.
	ConstMergeComplete : TMergeOutputFlags = 1 shl 0;


{ Record: TSizeInput }
// SizeInput is input to the Size method.
type
	TSizeInput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Message protoreflect.Message
		mMessage : TMessage;

		// Flags MarshalInputFlags
		mFlags : TMarshalInputFlags;
	end;

{ Record: TSizeOutput }
// SizeOutput is output from the Size method.
type
	TSizeOutput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Size int
		mSize : Integer;
	end;

{ Record: TMarshalInput }
// MarshalInput is input to the Marshal method.
type
	TMarshalInput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Message protoreflect.Message
		mMessage : TMessage;

		// Buf []byte // output is appended to this buffer
		mBuffer : TBytes;

		// Flags MarshalInputFlags
		mFlags : TMarshalInputFlags;
	end;

{ Record: TMarshalOutput }
// MarshalOutput is output from the Marshal method.
type
	TMarshalOutput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Buf []byte // contains marshaled message
		mBuffer : TBytes;
	end;

{ Record: TUnmarshalInput }
// UnmarshalInput is input to the Unmarshal method.
type
	TUnmarshalInput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Message protoreflect.Message
		mMessage : TMessage;

		// Buf []byte // input buffer
		mBuffer : TBytes;

		// Flags UnmarshalInputFlags
		mFlags : TUnmarshalInputFlags;

		// Resolver interface
		mResolver : IExtensionTypeResolver;
	end;

{ Record: TUnmarshalOutput }
// UnmarshalOutput is output from the Unmarshal method.
type
	TUnmarshalOutput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Flags UnmarshalOutputFlags
		mFlags : TUnmarshalOutputFlags;
	end;

{ Record: TMergeInput }
// MergeInput is input to the Merge method.
type
	TMergeInput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Source protoreflect.Message
		mSource : TMessage;

		// Destination protoreflect.Message
		mDestination : TMessage;
	end;

{ Record: TMergeOutput }
// MergeOutput is output from the Merge method.
type
	TMergeOutput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Flags MergeOutputFlags
		mFlags : TMergeOutputFlags;
	end;

{ Record: TCheckInitializedInput }
// CheckInitializedInput is input to the CheckInitialized method.
type
	TCheckInitializedInput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Message protoreflect.Message
		mMessage : TMessage;
	end;

{ Record: TCheckInitializedOutput }
// CheckInitializedOutput is output from the CheckInitialized method.
type
	TCheckInitializedOutput = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;
	end;

{ Record: TMethods }
// Methods is a set of optional fast-path implementations of various operations.
type
	TMethods = record
	public
		// pragma.NoUnkeyedLiterals
		mNoUnkeyedLiterals : TNoUnkeyedLiterals;

		// Flags indicate support for optional features.
		mFlags : TSupportFlags;

		// Size returns the size in bytes of the wire-format encoding of a message.
		// Marshal must be provided if a custom Size is provided.
		mSize : TFunc<TSizeInput, TSizeOutput>;

		// Marshal formats a message in the wire-format encoding to the provided buffer.
		// Size should be provided if a custom Marshal is provided.
		// It must not return an error for a partial message.
		mMarshal : TFunc<TMarshalInput, TMarshalOutput, TErrorInterface>;

		// Unmarshal parses the wire-format encoding and merges the result into a message.
		// It must not reset the target message or return an error for a partial message.
		mUnmarshal : TFunc<TUnmarshalInput, TUnmarshalOutput, TErrorInterface>;

		// Merge merges the contents of a source message into a destination message.
		mMerge : TFunc<TMergeInput, TMergeOutput>;

		// CheckInitialized returns an error if any required fields in the message are not set.
		mCheckInitialized : TFunc<TCheckInitializedInput, TCheckInitializedOutput, TErrorInterface>;
	end;

implementation

end.