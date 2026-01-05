{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Internal.Flags.Flags;

interface

// --- Emulate Go's Build Tag Logic for Delphi ---

// {$UNDEF PROTOLEGACY_BUILD_TAG} // Assume default is to not define the tag
{$IFDEF PROTOLEGACY_BUILD_TAG}
const
    // ProtoLegacy specifies whether to enable support for legacy functionality...
    // Go: const ProtoLegacy = true
    ConstProtoLegacy = True;
{$ELSE}
const
    // ProtoLegacy specifies whether to enable support for legacy functionality...
    // Go: const ProtoLegacy = false
    ConstProtoLegacy = False;
{$ENDIF}

const
    // LazyUnmarshalExtensions specifies whether to lazily unmarshal extensions.
    //
    // Lazy extension unmarshaling validates the contents of message-valued
    // extension fields at unmarshal time, but defers creating the message
    // structure until the extension is first accessed.
    // Go: const LazyUnmarshalExtensions = ProtoLegacy
    ConstLazyUnmarshalExtensions = ConstProtoLegacy;

implementation

// All functionality is in the interface section to mimic Go's constant accessibility.

end.