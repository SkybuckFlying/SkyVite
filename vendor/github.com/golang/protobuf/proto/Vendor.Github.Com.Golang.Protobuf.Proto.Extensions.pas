unit Vendor.Github.Com.Golang.Protobuf.Proto.Extensions;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Golang.Protobuf.Proto.Buffer,
  Vendor.Github.Com.Golang.Protobuf.Proto.Defaults,
  Vendor.Github.Com.Golang.Protobuf.Proto.Deprecated,
  Vendor.Github.Com.Golang.Protobuf.Proto.Discard,
  Vendor.Github.Com.Golang.Protobuf.Proto.Properties,
  Vendor.Github.Com.Golang.Protobuf.Proto.Proto,
  Vendor.Github.Com.Golang.Protobuf.Proto.Registry,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextDecode,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextEncode,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wire,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers;

type
	TExtensionDesc = record
	public
		mField : Integer;
		mName  : string;
		mTag   : string;
	end;

implementation

end.
