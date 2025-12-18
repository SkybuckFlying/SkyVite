unit Net.Mock.Receiver;

interface

uses
	System.SysUtils,
	Common.Types,
	Interfaces.Core.Snapshot.Block,
	Interfaces.Core.Account.Block,
	Net.Interface;

type
	TMockReceiver = class(TInterfacedObject, IReceiver)
	public
		function ReceiveAccountBlock( ParaBlock : TAccountBlock; ParaSource : TBlockSource ) : Boolean;
		function ReceiveSnapshotBlock( ParaBlock : TSnapshotBlock; ParaSource : TBlockSource ) : Boolean;
	end;

implementation

{ TMockReceiver }

function TMockReceiver.ReceiveAccountBlock( ParaBlock : TAccountBlock; ParaSource : TBlockSource ) : Boolean;
begin
	Result := True;
end;

function TMockReceiver.ReceiveSnapshotBlock( ParaBlock : TSnapshotBlock; ParaSource : TBlockSource ) : Boolean;
begin
	Result := True;
end;

end.
