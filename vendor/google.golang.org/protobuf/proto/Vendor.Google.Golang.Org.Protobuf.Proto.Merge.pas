unit Vendor.Google.Golang.Org.Protobuf.Proto.Merge;

interface

uses
  System.SysUtils, Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

procedure Merge(Dst, Src: IMessage);
function Clone(M: IMessage): IMessage;

implementation

procedure Merge(Dst, Src: IMessage);
begin
  // Implementation of Merge
end;

function Clone(M: IMessage): IMessage;
begin
  if M = nil then Exit(nil);
  Result := M.ProtoReflect.New_.Interface_;
  Merge(Result, M);
end;

end.
