unit generator;

interface

uses
  Ledger.Generator.Incoming.Message,
  Ledger.Generator.Utils,
  Ledger.Generator.Utils.Test,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite.Abi Vite.Common Vite.Crypto Vite.Ledger Vite.Vm Vite.Pow,
  Vite.Interfaces big_int;

type
  TConsensus = interface
    function SBPReader: ISBPStatReader;
  end;

  TChain = interface
    function GetAccountBlockByHash(blockHash: THash): TAccountBlock;
    function GetSnapshotBlockByContractMeta(addr: TAddress; fromHash: THash): TSnapshotBlock;
    function GetSeedConfirmedSnapshotBlock(addr: TAddress; fromHash: THash): TSnapshotBlock;
    function GetSeed(limitSb: TSnapshotBlock; fromHash: THash): UInt64;
  end;

  TGenerator = class(TInterfacedObject, IGenerator)
  private
    FChain: TChain;
    FVmDb: IVmDb;
    FVm: TVM;
    FLog: TLogger;
    function GenerateBlock(block, fromBlock: TAccountBlock; producer: PAddress; signFunc: ISignFunc): IGenResult;
    function PackReceiveBlockWithSend(sendBlock: TAccountBlock; difficulty: TBigInt): TAccountBlock;
  public
    constructor Create(chain: IVmDbChain; sbpStatReader: ISBPStatReader; addr: TAddress; latestSnapshotBlockHash, prevBlockHash: PHash);
    destructor Destroy; override;
    function GenerateWithBlock(block, fromBlock: TAccountBlock): IGenResult;
    function GenerateWithMessage(message: IIncomingMessage; producer: PAddress; signFunc: ISignFunc): IGenResult;
    function GenerateWithOnRoad(sendBlock: TAccountBlock; producer: PAddress; signFunc: ISignFunc; difficulty: TBigInt): IGenResult;
    function GetVMDB: IVmDb;
  end;

implementation

{ TGenerator }

constructor TGenerator.Create(chain: IVmDbChain; sbpStatReader: ISBPStatReader;
  addr: TAddress; latestSnapshotBlockHash, prevBlockHash: PHash);
begin
  inherited Create;
  FLog := TLogger.New('module', 'Generator');
  FChain := chain as TChain;
  FVm := TVM.Create(TVMConsensusReader.Create(sbpStatReader));
  FVmDb := TVmDb.Create(chain, @addr, latestSnapshotBlockHash, prevBlockHash);
end;

destructor TGenerator.Destroy;
begin
  FVm.Free;
  inherited;
end;

function TGenerator.GenerateBlock(block, fromBlock: TAccountBlock;
  producer: PAddress; signFunc: ISignFunc): IGenResult;
var
  state: TVMGlobalStatus;
  latestSb, limitSb, limitSeedSb: TSnapshotBlock;
  vmBlock: TVMBlock;
  isRetry: Boolean;
  err: Exception;
  bDetail: string;
  vb: TAccountBlock;
  i: Integer;
  signature, publicKey: TBytes;
begin
  Result := nil;
  try
    state := nil;
    if block.IsReceiveBlock then
    begin
      if fromBlock = nil then
        raise Exception.Create('need to pass in sendBlock when generate receiveBlock');
      latestSb := GetVMDB.LatestSnapshotBlock;
      if latestSb = nil then
        raise Exception.Create('vmDb''s latestSnapshotBlock is nil');

      limitSb := FChain.GetSnapshotBlockByContractMeta(block.AccountAddress, fromBlock.Hash);
      if TUpgrade.IsSeedUpgrade(latestSb.Height) then
      begin
        limitSeedSb := FChain.GetSeedConfirmedSnapshotBlock(block.AccountAddress, fromBlock.Hash);
        if limitSb = nil then
        begin
          if limitSeedSb <> nil then
            limitSb := limitSeedSb;
        end
        else
        begin
          if (limitSeedSb <> nil) and (limitSb.Height < limitSeedSb.Height) then
            limitSb := limitSeedSb;
        end;
      end;
      if limitSb <> nil then
      begin
        state := TVMGlobalStatus.Create(FChain, limitSb, fromBlock.Hash);
        FLog.Info('gen GlobalStatus', 'hash', limitSb.Hash.ToString, 'fromHash', fromBlock.Hash.ToString);
      end;
    end;

    vmBlock := FVm.RunV2(FVmDb, block, fromBlock, state, isRetry);
    if vmBlock <> nil then
    begin
      vb := vmBlock.AccountBlock;
      if vb.IsReceiveBlock and (vb.AccountAddress.IsContractAddr) and (Length(vb.SendBlockList) > 0) then
      begin
        for i := 0 to High(vb.SendBlockList) do
          vb.SendBlockList[i].Hash := vb.SendBlockList[i].ComputeSendHash(vb, i);
      end;
      vb.Hash := vb.ComputeHash;
      if signFunc <> nil then
      begin
        if producer = nil then
          raise Exception.Create('producer address is uncertain, can''t sign');
        signFunc(vb.Hash.Bytes, signature, publicKey);
        vb.Signature := signature;
        vb.PublicKey := publicKey;
      end;
    end;

    Result := TGenResult.Create(vmBlock, isRetry, nil);
  except
    on E: Exception do
    begin
      bDetail := Format('block(addr:%s prevHash:%s)', [string(block.AccountAddress), string(block.PrevHash)]);
      if fromBlock <> nil then
        bDetail := bDetail + Format('fromBlock(addr:%s hash:%s)', [string(fromBlock.AccountAddress), string(fromBlock.Hash)]);
      FLog.Error(Format('generator_vm panic error %s', [E.Message]), 'detail', bDetail);
      Result := TGenResult.Create(nil, False, E);
    end;
  end;
end;

function TGenerator.GenerateWithBlock(block, fromBlock: TAccountBlock): IGenResult;
begin
  Result := GenerateBlock(block, fromBlock, nil, nil);
end;

function TGenerator.GenerateWithMessage(message: IIncomingMessage;
  producer: PAddress; signFunc: ISignFunc): IGenResult;
var
  block, fromBlock: TAccountBlock;
begin
  block := IncomingMessageToBlock(FVmDb, message);
  fromBlock := nil;
  if block.IsReceiveBlock then
  begin
    fromBlock := FChain.GetAccountBlockByHash(block.FromBlockHash);
    if fromBlock = nil then
      raise Exception.Create('generate recvBlock failed, cause failed to find its sendBlock');
  end;
  Result := GenerateBlock(block, fromBlock, producer, signFunc);
end;

function TGenerator.GenerateWithOnRoad(sendBlock: TAccountBlock;
  producer: PAddress; signFunc: ISignFunc; difficulty: TBigInt): IGenResult;
var
  block: TAccountBlock;
begin
  block := PackReceiveBlockWithSend(sendBlock, difficulty);
  Result := GenerateBlock(block, sendBlock, producer, signFunc);
end;

function TGenerator.GetVMDB: IVmDb;
begin
  Result := FVmDb;
end;

function TGenerator.PackReceiveBlockWithSend(sendBlock: TAccountBlock;
  difficulty: TBigInt): TAccountBlock;
var
  recvBlock: TAccountBlock;
  prevBlock: TAccountBlock;
  prevHash: THash;
  preHeight: UInt64;
  nonce: TBytes;
begin
  recvBlock := TAccountBlock.Create;
  recvBlock.BlockType := btReceive;
  recvBlock.AccountAddress := sendBlock.ToAddress;
  recvBlock.FromBlockHash := sendBlock.Hash;

  prevBlock := FVmDb.PrevAccountBlock;
  if prevBlock <> nil then
  begin
    prevHash := prevBlock.Hash;
    preHeight := prevBlock.Height;
  end
  else
  begin
    prevHash := THash.Create;
    preHeight := 0;
  end;
  recvBlock.PrevHash := prevHash;
  recvBlock.Height := preHeight + 1;

  if difficulty <> nil then
  begin
    nonce := TPoW.GetPowNonce(difficulty, TDataHash.Create(sendBlock.ToAddress.Bytes + prevHash.Bytes));
    recvBlock.Nonce := nonce;
    recvBlock.Difficulty := difficulty;
  end;
  Result := recvBlock;
end;

end.
