unit Net.VNode.Mock;

interface

uses
  System.SysUtils,
  Net.VNode.Node,
  Net.VNode.Host,
  Net.VNode.EndPoint;

function MockIP: TBytes;
function MockPort: Integer;
function MockRest: TBytes;
function MockNet: Integer;
function MockNode(ParaDomain, ParaExt: Boolean): TNode;

implementation

uses
  System.Math;

function MockIP: TBytes;
var
  vIsIPv4: Boolean;
  vLen: Integer;
begin
  vIsIPv4 := Random > 0.5;
  if vIsIPv4 then
    vLen := 4
  else
    vLen := 16;
  SetLength(Result, vLen);
  for var i := 0 to vLen - 1 do
    Result[i] := Byte(Random(256));
end;

function MockPort: Integer;
begin
  Result := Random(65536);
end;

function MockRest: TBytes;
var
  vLen: Integer;
begin
  vLen := Random(1001);
  SetLength(Result, vLen);
  for var i := 0 to vLen - 1 do
    Result[i] := Byte(Random(256));
end;

function MockNet: Integer;
begin
  Result := Random(1001);
end;

function MockNode(ParaDomain, ParaExt: Boolean): TNode;
var
  vNode: TNode;
  vIP: TBytes;
begin
  vNode := TNode.Create;
  vNode.ID := TNodeID.RandomNodeID;
  vNode.EndPoint.Port := MockPort;
  vNode.Net := MockNet;

  if ParaDomain then
  begin
    vNode.EndPoint.Host := TEncoding.UTF8.GetBytes('www.vite.org');
    vNode.EndPoint.Typ := htDomain;
  end
  else
  begin
    vIP := MockIP;
    vNode.EndPoint.Host := vIP;
    if Length(vIP) = 4 then
      vNode.EndPoint.Typ := htIPv4
    else
      vNode.EndPoint.Typ := htIPv6;
  end;

  if ParaExt then
    vNode.Ext := MockRest;

  Result := vNode;
end;

end.
