unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Methods;

{$MODE DELPHIUNICODE}

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Proto,
  Vendor.Google.Golang.Org.Protobuf.Internal.Pragma;

type
  TSupportFlags = UInt64;

  TSizeInput = record
    Message: IMessage;
    Flags: Byte;
  end;

  TSizeOutput = record
    Size: Integer;
  end;

  TMarshalInput = record
    Message: IMessage;
    Buf: TArray<Byte>;
    Flags: Byte;
  end;

  TMarshalOutput = record
    Buf: TArray<Byte>;
  end;

  TUnmarshalInput = record
    Message: IMessage;
    Buf: TArray<Byte>;
    Flags: Byte;
    Resolver: IInterface; // Placeholder
  end;

  TUnmarshalOutput = record
    Flags: Byte;
  end;

  TMergeInput = record
    Source: IMessage;
    Destination: IMessage;
  end;

  TMergeOutput = record
    Flags: Byte;
  end;
  
  TCheckInitializedInput = record
    Message: IMessage;
  end;

  TCheckInitializedOutput = record
  end;

  TProtoMethods = record
    Flags: TSupportFlags;
    Size: function(ParaIn: TSizeInput): TSizeOutput;
    Marshal: function(ParaIn: TMarshalInput): TMarshalOutput; // Returns (output, error) tuple in Go. In Delphi, maybe return Record with Error field or raise exception.
    // For simplicity, I'll assume they return the output struct, and exceptions are raised.
    Unmarshal: function(ParaIn: TUnmarshalInput): TUnmarshalOutput;
    Merge: function(ParaIn: TMergeInput): TMergeOutput;
    CheckInitialized: function(ParaIn: TCheckInitializedInput): TCheckInitializedOutput;
  end;
  PProtoMethods = ^TProtoMethods;

implementation

end.
