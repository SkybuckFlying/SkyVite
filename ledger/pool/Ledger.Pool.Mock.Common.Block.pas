unit Ledger.Pool.MockCommonBlock;

interface

uses
  Common.BigInt,
  Common.Types,
  GoToDelphi.Helpers.BigInt,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.Chain.Pool,
  Ledger.Pool.Chain.Pool.Test,
  Ledger.Pool.Context,
  Ledger.Pool.Face,
  Ledger.Pool.Pipeline.Pool,
  Ledger.Pool.Pool,
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
  Ledger.Pool.Pool.Batch.Fork,
  Ledger.Pool.Pool.Fork.Checker,
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Worker,
  System.SysUtils;

type
  ICommonBlock = interface
    ['{B8E4B4B4-8B4B-4B4B-8B4B-4B4B4B4B4B4B}']
    function Height: TUInt64;
    function Hash: THash;
    function PrevHash: THash;
    function checkForkVersion: Boolean;
    procedure resetForkVersion;
    function forkVersion: TUInt64;
    function Source: TBlockSource;
    function Latency: TTimeSpan;
    function ShouldFetch: Boolean;
    function ReferHashes: TTuple<TArray<THash>, TArray<THash>, THash>;
    function Ready: Boolean;
  end;

  TMockCommonBlock = class(TInterfacedObject, ICommonBlock)
  private
    FFlag: string;
    FPrevHash: THash;
    FHeight: TUInt64;
    FHash: THash;
    function computeHash: THash;
  public
    constructor Create;
    function Height: TUInt64;
    function Hash: THash;
    function PrevHash: THash;
    function checkForkVersion: Boolean;
    procedure resetForkVersion;
    function forkVersion: TUInt64;
    function Source: TBlockSource;
    function Latency: TTimeSpan;
    function ShouldFetch: Boolean;
    function ReferHashes: TTuple<TArray<THash>, TArray<THash>, THash>;
    function Ready: Boolean;
  end;

function genGenesisBlock: ICommonBlock;
function genEmptyBlock: ICommonBlock;
function newMockCommonBlockByHH(height: TUInt64; hash: THash; flag: string): ICommonBlock;
function newMockCommonBlock(prev: ICommonBlock; flag: string): ICommonBlock;

var
  genesisBlock: ICommonBlock;
  emptyBlock: ICommonBlock;

implementation

uses
  Crypto,
  System.DateUtils;

{ TMockCommonBlock }

constructor TMockCommonBlock.Create;
begin
  inherited;
end;

function TMockCommonBlock.Height: TUInt64;
begin
  Result := FHeight;
end;

function TMockCommonBlock.Hash: THash;
begin
  Result := FHash;
end;

function TMockCommonBlock.PrevHash: THash;
begin
  Result := FPrevHash;
end;

function TMockCommonBlock.checkForkVersion: Boolean;
begin
  Result := False;
end;

procedure TMockCommonBlock.resetForkVersion;
begin
end;

function TMockCommonBlock.forkVersion: TUInt64;
begin
  Result := 0;
end;

function TMockCommonBlock.Source: TBlockSource;
begin
  Result := bsLocal;
end;

function TMockCommonBlock.Latency: TTimeSpan;
begin
  Result := OneSecond;
end;

function TMockCommonBlock.ShouldFetch: Boolean;
begin
  Result := False;
end;

function TMockCommonBlock.ReferHashes: TTuple<TArray<THash>, TArray<THash>, THash>;
begin
  raise Exception.Create('Not implemented');
end;

function TMockCommonBlock.Ready: Boolean;
begin
  Result := True;
end;

function TMockCommonBlock.computeHash: THash;
var
  vSource: TBytes;
  vHeightBytes: TBytes;
  vError: Exception;
begin
  SetLength(vSource, 0);
  vSource := vSource + FPrevHash.Bytes;

  SetLength(vHeightBytes, 8);
  PULong(@vHeightBytes[0])^ := FHeight;
  vSource := vSource + vHeightBytes;

  vSource := vSource + TEncoding.UTF8.GetBytes(FFlag);

  Result := THash.Hash256(vSource, vError);
  if vError <> nil then
    raise vError;
end;

function genGenesisBlock: ICommonBlock;
var
  vKnot: TMockCommonBlock;
begin
  vKnot := TMockCommonBlock.Create;
  vKnot.FPrevHash := THash.Create;
  vKnot.FHeight := 1;
  vKnot.FFlag := 'genesis';
  vKnot.FHash := vKnot.computeHash;
  Result := vKnot;
end;

function genEmptyBlock: ICommonBlock;
var
  vKnot: TMockCommonBlock;
begin
  vKnot := TMockCommonBlock.Create;
  vKnot.FPrevHash := THash.Create;
  vKnot.FHeight := 0;
  vKnot.FFlag := 'empty';
  vKnot.FHash := THash.Create;
  Result := vKnot;
end;

function newMockCommonBlockByHH(height: TUInt64; hash: THash; flag: string): ICommonBlock;
var
  vKnot: TMockCommonBlock;
begin
  vKnot := TMockCommonBlock.Create;
  vKnot.FPrevHash := hash;
  vKnot.FHeight := height + 1;
  vKnot.FFlag := flag;
  vKnot.FHash := vKnot.computeHash;
  Result := vKnot;
end;

function newMockCommonBlock(prev: ICommonBlock; flag: string): ICommonBlock;
var
  vKnot: TMockCommonBlock;
begin
  vKnot := TMockCommonBlock.Create;
  vKnot.FPrevHash := prev.Hash;
  vKnot.FHeight := prev.Height + 1;
  vKnot.FFlag := flag;
  vKnot.FHash := vKnot.computeHash;
  Result := vKnot;
end;

initialization
  genesisBlock := genGenesisBlock;
  emptyBlock := genEmptyBlock;

end.
