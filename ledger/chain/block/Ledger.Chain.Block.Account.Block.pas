unit ledger.chain.block.account_block;

interface

uses
  Ledger.Chain.Block.Block.DB,
  Ledger.Chain.Block.Block.DB.Test,
  Ledger.Chain.Block.Block.Parser,
  Ledger.Chain.Block.Buffer,
  Ledger.Chain.Block.Flush,
  Ledger.Chain.Block.Snapshot.Block,
  SysUtils ledger.core ledger.chain.file_manager;

type
  TBlockDB = class
  public
    function GetAccountBlock(const Location: TLocation): TAccountBlock;
  end;

implementation

function TBlockDB.GetAccountBlock(const Location: TLocation): TAccountBlock;
var
  Buf: TBytes;
  AB: TAccountBlock;
begin
  Buf := Self.Read(Location); // Assume Read returns TBytes or similar
  AB := TAccountBlock.Create;
  if not AB.Deserialize(Buf) then
    raise Exception.Create('ab.Deserialize failed');
  Result := AB;
end;

end.
