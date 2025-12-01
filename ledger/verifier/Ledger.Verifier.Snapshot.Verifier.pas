unit snapshot_verifier;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.DateUtils,
  Vite.Common, Vite.Crypto, Vite.Interfaces, Vite.Ledger, Vite.Ledger.Chain,
  Vite.Monitor, Verifier.Common, Verifier.Errors, big_int;

type
  TSnapshotVerifier = class
  private
    FReader: IChain;
    FVerifier: IConsensusVerifier;
    function VerifyTimestamp(block: TSnapshotBlock): Boolean;
    function VerifyDataValidity(block: TSnapshotBlock): Boolean;
    function VerifySelf(block: TSnapshotBlock; stat: TSnapshotBlockVerifyStat): Boolean;
    function VerifyAccounts(block, prev: TSnapshotBlock; stat: TSnapshotBlockVerifyStat): Boolean;
    function GetLastSeedBlock(head: TSnapshotBlock): TSnapshotBlock;
    function NewVerifyStat(b: TSnapshotBlock): TSnapshotBlockVerifyStat;
  public
    constructor Create(ch: IChain; verifier: IConsensusVerifier);
    function VerifyNetSb(block: TSnapshotBlock): Boolean;
    function VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
  end;

  TAccountHashH = record
    Addr: PAddress;
    Hash: PHash;
    Height: TBigInt;
  end;

  TSnapshotBlockVerifyStat = class
  private
    FResult: TVerifyResult;
    FResults: TDictionary<TAddress, TVerifyResult>;
    FErrMsg: string;
    FAccountTasks: TArray<TAccountPendingTask>;
    FSnapshotTask: TSnapshotPendingTask;
  public
    constructor Create;
    destructor Destroy; override;
    function ErrMsg: string;
    function VerifyResult: TVerifyResult;
    function Results: TDictionary<TAddress, TVerifyResult>;
  end;

implementation

{ TSnapshotVerifier }

constructor TSnapshotVerifier.Create(ch: IChain; verifier: IConsensusVerifier);
begin
  inherited Create;
  FReader := ch;
  FVerifier := verifier;
end;

function TSnapshotVerifier.VerifyNetSb(block: TSnapshotBlock): Boolean;
begin
  if not VerifyTimestamp(block) then
    Exit(False);
  if not VerifyDataValidity(block) then
    Exit(False);
  Result := True;
end;

function TSnapshotVerifier.VerifyTimestamp(block: TSnapshotBlock): Boolean;
begin
  if block.Timestamp = 0 then
    raise Exception.Create('timestamp is nil');
  if TUnix.ToDateTime(block.Timestamp) > Now + EncodeTime(1, 0, 0, 0) then
    raise Exception.Create('snapshot Timestamp not arrive yet');
  if TUpgrade.IsVersion13Upgrade(block.Height) then
  begin
    if TUnix.ToDateTime(block.Timestamp) > Now + EncodeTime(0, 0, 20, 0) then
      raise Exception.Create('A snapshot block from the future.');
  end;
  Result := True;
end;

function TSnapshotVerifier.VerifyDataValidity(block: TSnapshotBlock): Boolean;
var
  computedHash: THash;
  isVerified: Boolean;
begin
  computedHash := block.ComputeHash;
  if block.Hash.IsZero or (computedHash <> block.Hash) then
    raise ErrVerifyHashFailed;

  if FReader.IsGenesisSnapshotBlock(block.Hash) then
  begin
    Result := True;
    Exit;
  end;

  if (Length(block.Signature) = 0) or (Length(block.PublicKey) = 0) then
    raise Exception.Create('signature or publicKey is nil');
  isVerified := TCrypto.VerifySig(block.PublicKey, block.Hash.Bytes, block.Signature);
  if not isVerified then
    raise ErrVerifySignatureFailed;
  Result := True;
end;

function TSnapshotVerifier.VerifySelf(block: TSnapshotBlock; stat: TSnapshotBlockVerifyStat): Boolean;
var
  flag: Boolean;
  seedBlock: TSnapshotBlock;
  hash: THash;
  head: TSnapshotBlock;
begin
  if block.Height = GenesisHeight then
  begin
    flag := FReader.IsGenesisSnapshotBlock(block.Hash);
    if not flag then
    begin
      stat.FResult := vrFail;
      raise Exception.CreateFmt('genesis block[%s] error.', [string(block.Hash)]);
    end;
  end;

  if block.Seed <> 0 then
  begin
    seedBlock := GetLastSeedBlock(block);
    if seedBlock <> nil then
    begin
      hash := TSnapshotBlock.ComputeSeedHash(block.Seed, seedBlock.PrevHash, seedBlock.Timestamp);
      if hash <> seedBlock.SeedHash^ then
        raise Exception.CreateFmt('seed verify fail. %s-%d', [string(seedBlock.Hash), seedBlock.Height]);
    end;
  end;

  head := FReader.GetLatestSnapshotBlock;
  if head.Height <> block.Height - 1 then
    raise Exception.CreateFmt('snapshot fail for height:[%d]', [head.Height]);
  if head.Hash <> block.PrevHash then
    raise Exception.CreateFmt('block is not next. prevHash:%s, headHash:%s', [string(block.PrevHash), string(head.Hash)]);
  Result := True;
end;

function TSnapshotVerifier.VerifyAccounts(block, prev: TSnapshotBlock; stat: TSnapshotBlockVerifyStat): Boolean;
var
  addr: TAddress;
  b: TAccountBlock;
  ab: TAccountBlock;
  v: TVerifyResult;
begin
  for addr in block.SnapshotContent.Keys do
  begin
    b := block.SnapshotContent[addr];
    ab := FReader.GetAccountBlockByHeight(addr, b.Height);
    if ab = nil then
      stat.FResults.AddOrSetValue(addr, vrPending)
    else if ab.Hash = b.Hash then
      stat.FResults.AddOrSetValue(addr, vrSuccess)
    else
    begin
      stat.FResults.AddOrSetValue(addr, vrFail);
      stat.FResult := vrFail;
      raise Exception.CreateFmt('account[%s] fork, height:[%d], hash:[%s]', [addr.ToString, b.Height, b.Hash.ToString]);
    end;
  end;
  for v in stat.FResults.Values do
  begin
    if v <> vrSuccess then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := True;
end;

function TSnapshotVerifier.VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
var
  stat: TSnapshotBlockVerifyStat;
  head: TSnapshotBlock;
  v: TVerifyResult;
  result: Boolean;
begin
  stat := NewVerifyStat(block);
  try
    if not VerifySelf(block, stat) then
      Exit(stat);

    head := FReader.GetLatestSnapshotBlock;
    if not (TUnix.ToDateTime(block.Timestamp) > TUnix.ToDateTime(head.Timestamp)) then
    begin
      stat.FResult := vrFail;
      stat.FErrMsg := 'timestamp must be greater.';
      Exit(stat);
    end;

    if not VerifyAccounts(block, head, stat) then
      Exit(stat);

    for v in stat.FResults.Values do
    begin
      if (v = vrFail) or (v = vrPending) then
        Exit(stat);
    end;

    if block.Height <> GenesisHeight then
    begin
      result := FVerifier.VerifySnapshotProducer(block);
      if not result then
      begin
        stat.FResult := vrFail;
        stat.FErrMsg := 'verify snapshot producer fail.';
        Exit(stat);
      end;
    end;
    stat.FResult := vrSuccess;
    Result := stat;
  except
    on E: Exception do
    begin
      stat.FErrMsg := E.Message;
      Result := stat;
    end;
  end;
end;

function TSnapshotVerifier.GetLastSeedBlock(head: TSnapshotBlock): TSnapshotBlock;
begin
  // Not implemented in Go version
  Result := nil;
end;

function TSnapshotVerifier.NewVerifyStat(b: TSnapshotBlock): TSnapshotBlockVerifyStat;
var
  k: TAddress;
begin
  Result := TSnapshotBlockVerifyStat.Create;
  Result.FResult := vrPending;
  for k in b.SnapshotContent.Keys do
    Result.FResults.Add(k, vrPending);
end;

{ TSnapshotBlockVerifyStat }

constructor TSnapshotBlockVerifyStat.Create;
begin
  inherited Create;
  FResults := TDictionary<TAddress, TVerifyResult>.Create;
end;

destructor TSnapshotBlockVerifyStat.Destroy;
begin
  FResults.Free;
  inherited;
end;

function TSnapshotBlockVerifyStat.ErrMsg: string;
begin
  Result := FErrMsg;
end;

function TSnapshotBlockVerifyStat.VerifyResult: TVerifyResult;
begin
  Result := FResult;
end;

function TSnapshotBlockVerifyStat.Results: TDictionary<TAddress, TVerifyResult>;
begin
  Result := FResults;
end;

end.
