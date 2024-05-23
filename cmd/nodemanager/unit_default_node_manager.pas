unit unit_default_node_manager;

interface

uses
  urfave.cli,
  unit_node;

type
  TDefaultNodeManager = class
  private
    ctx: PCliContext;
    node: PNode;
  public
	constructor Create(const ctx: PCliContext; const maker: TNodeMaker);
    function Start: Integer;
	function Stop: Integer;
    function GetNode: PNode;
  end;

implementation

constructor TDefaultNodeManager.Create(const ctx: PCliContext; const maker: TNodeMaker);
var
  err: Integer;
begin
  err := maker.MakeNode(ctx, node);
  if err <> 0 then
    raise Exception.Create('Error creating node');
  Self.ctx := ctx;
  Self.node := node;
end;

function TDefaultNodeManager.Start: Integer;
var
  err: Integer;
begin
  // 1: Start up the node
  err := StartNode(Self.node);
  if err <> 0 then
    Exit(err);

  // 2: Waiting for node to close
  WaitNode(Self.node);

  Result := 0;
end;

function TDefaultNodeManager.Stop: Integer;
begin
  StopNode(Self.node);
  Result := 0;
end;

function TDefaultNodeManager.GetNode: PNode;
begin
  Result := Self.node;
end;

end.


