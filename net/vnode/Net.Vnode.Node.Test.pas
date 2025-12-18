unit Net.Vnode.Node.Test;

interface

uses
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  System.Classes,
  System.SysUtils;

procedure TestNodeID_IsZero;
procedure TestNodeID_Bytes;
procedure TestNode_Serialize;
procedure TestCommonBits;
procedure TestDistance;
procedure TestParseNode;

implementation

procedure TestNodeID_IsZero;
var
	vId : TNodeID;
begin
	vId := Default( TNodeID );
	if not vId.IsZero then raise Exception.Create( 'should be zero' );
end;

procedure TestNodeID_Bytes;
var
	vId, vId2 : TNodeID;
begin
	vId := TNodeID.Random;
	vId2 := TNodeID.FromBytes( vId.Bytes );
	if vId <> vId2 then raise Exception.Create( 'different id' );
end;

procedure TestNode_Serialize;
begin
	// serialization tests...
end;

procedure TestCommonBits;
begin
	// common bits tests...
end;

procedure TestDistance;
begin
	// distance tests...
end;

procedure TestParseNode;
begin
	// node parsing tests...
end;

end.
