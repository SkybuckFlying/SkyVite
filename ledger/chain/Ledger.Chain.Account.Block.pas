unit Ledger.Chain.AccountBlock;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block.Test,
  Ledger.Chain.Account.Test,
  Ledger.Chain.Builtin.Contract,
  Ledger.Chain.Builtin.Contract.Test,
  Ledger.Chain.Chain,
  Ledger.Chain.Chain.Test,
  Ledger.Chain.Check,
  Ledger.Chain.Delete,
  Ledger.Chain.Delete.Test,
  Ledger.Chain.Event.Manager,
  Ledger.Chain.Fork,
  Ledger.Chain.Insert,
  Ledger.Chain.Insert.Test,
  Ledger.Chain.Interface,
  Ledger.Chain.Meta,
  Ledger.Chain.Onroad,
  Ledger.Chain.Onroad.Test,
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.Snapshot.Block.Test,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Sync.Ledger,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test,
  System.Classes,
  System.SysUtils;

type
  TChain = class
  public
    function IsGenesisAccountBlock(const ParaHash: THash): Boolean;
    function IsAccountBlockExisted(const ParaHash: THash): Boolean;
    function GetAccountBlockByHeight(const ParaAddr: TAddress; ParaHeight: UInt64): IAccountBlock;
    function GetAccountBlockHashByHeight(const ParaAddr: TAddress; ParaHeight: UInt64): THash;
    function GetCompleteBlockByHash(const ParaBlockHash: THash): IAccountBlock;
    function GetAccountBlockByHash(const ParaBlockHash: THash): IAccountBlock;
    function GetReceiveAbBySendAb(const ParaSendBlockHash: THash): IAccountBlock;
    function IsReceived(const ParaSendBlockHash: THash): Boolean;
    function GetAccountBlocks(const ParaBlockHash: THash; ParaCount: UInt64): TArray<IAccountBlock>;
    function GetAccountBlocksByHeight(const ParaAddr: TAddress; ParaHeight, ParaCount: UInt64): TArray<IAccountBlock>;
    function GetAccountBlocksByRange(const ParaAddr: TAddress; ParaStart, ParaEnd: UInt64): TArray<IAccountBlock>;
    function GetCallDepth(const ParaSendBlockHash: THash): UInt16;
    function GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
    function IsSeedConfirmedNTimes(const ParaBlockHash: THash; ParaN: UInt64): Boolean;
    function GetLatestAccountBlock(const ParaAddr: TAddress): IAccountBlock;
    function GetLatestAccountHeight(const ParaAddr: TAddress): UInt64;
  end;

implementation

{ TChain }

function TChain.IsGenesisAccountBlock(const ParaHash: THash): Boolean;
begin
  // TODO: Implement this function
  Result := False;
end;

function TChain.IsAccountBlockExisted(const ParaHash: THash): Boolean;
begin
  // TODO: Implement this function
  Result := False;
end;

function TChain.GetAccountBlockByHeight(const ParaAddr: TAddress; ParaHeight: UInt64): IAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.GetAccountBlockHashByHeight(const ParaAddr: TAddress; ParaHeight: UInt64): THash;
begin
  // TODO: Implement this function
  Result := Default(THash);
end;

function TChain.GetCompleteBlockByHash(const ParaBlockHash: THash): IAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.GetAccountBlockByHash(const ParaBlockHash: THash): IAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.GetReceiveAbBySendAb(const ParaSendBlockHash: THash): IAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.IsReceived(const ParaSendBlockHash: THash): Boolean;
begin
  // TODO: Implement this function
  Result := False;
end;

function TChain.GetAccountBlocks(const ParaBlockHash: THash; ParaCount: UInt64): TArray<IAccountBlock>;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.GetAccountBlocksByHeight(const ParaAddr: TAddress; ParaHeight, ParaCount: UInt64): TArray<IAccountBlock>;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.GetAccountBlocksByRange(const ParaAddr: TAddress; ParaStart, ParaEnd: UInt64): TArray<IAccountBlock>;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.GetCallDepth(const ParaSendBlockHash: THash): UInt16;
begin
  // TODO: Implement this function
  Result := 0;
end;

function TChain.GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
begin
  // TODO: Implement this function
  Result := 0;
end;

function TChain.IsSeedConfirmedNTimes(const ParaBlockHash: THash; ParaN: UInt64): Boolean;
begin
  // TODO: Implement this function
  Result := False;
end;

function TChain.GetLatestAccountBlock(const ParaAddr: TAddress): IAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TChain.GetLatestAccountHeight(const ParaAddr: TAddress): UInt64;
begin
  // TODO: Implement this function
  Result := 0;
end;

end.
