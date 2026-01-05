{$MODE DELPHIUNICODE}
unit Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface.Legacy;

interface

uses
	System.SysUtils;

{ Interface: IMessageV1 }
// MessageV1 interface is a legacy interface defining basic methods of a proto1 message.
type
	IMessageV1 = interface
		['{41E33B70-5F10-4A42-9D99-CC55B11C1542}']
		// Reset clears all fields of the message.
		procedure Reset;
		// String returns a string representation of the message.
		function ToString : string;
		// ProtoMessage is a marker method.
		procedure ProtoMessage;
	end;

{ Record: TExtensionRangeV1 }
// ExtensionRangeV1 represents an inclusive range of extension field numbers.
type
	TExtensionRangeV1 = record
	public
		// Start, End int32 // both inclusive
		mStart : Int32;
		mEnd : Int32;
	end;

implementation

end.