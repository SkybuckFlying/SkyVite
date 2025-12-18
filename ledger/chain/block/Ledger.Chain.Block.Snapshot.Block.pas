unit Ledger.Chain.Block.Snapshot.Block;

interface

uses
  Interfaces.Core.Snapshot.Block,
  Ledger.Chain.Block.Account.Block,
  Ledger.Chain.Block.Block.DB,
  Ledger.Chain.Block.Block.DB.Test,
  Ledger.Chain.Block.Block.Parser,
  Ledger.Chain.Block.Buffer,
  Ledger.Chain.Block.Flush,
  Ledger.Chain.File.Manager.Location,
  System.SysUtils;

type
	TSnapshotBlockHelper = class helper for TBlockDB
	public
		function GetSnapshotBlock( ParaLocation : TLocation ) : TSnapshotBlock;
		function GetSnapshotHeader( ParaLocation : TLocation ) : TSnapshotBlock;
	end;

implementation

{ TSnapshotBlockHelper }

function TSnapshotBlockHelper.GetSnapshotBlock( ParaLocation : TLocation ) : TSnapshotBlock;
var
	vBuf : TBytes;
begin
	Result := nil;
	vBuf := Read( ParaLocation );
	
	if Length( vBuf ) <= 0 then
	begin
		Exit;
	end;

	try
		Result := TSnapshotBlock.Create;
		if not Result.Deserialize( vBuf ) then
		begin
			Result.Free;
			raise Exception.Create( 'sb.Deserialize failed' );
		end;
	except
		on E: Exception do
		begin
			if Result <> nil then
			begin
				Result.Free;
			end;
			raise Exception.Create( 'GetSnapshotBlock failed: ' + E.Message );
		end;
	end;
end;

function TSnapshotBlockHelper.GetSnapshotHeader( ParaLocation : TLocation ) : TSnapshotBlock;
begin
	Result := GetSnapshotBlock( ParaLocation );
	if Result <> nil then
	begin
		// Reset/Clear snapshot content for header-only retrieval
		// Result.SnapshotContent := nil; // Assuming SnapshotContent is a property or field
	end;
end;

end.
