unit RpcApi.Api.LedgerModel;

interface

uses
  Common.Types Ledger Ledger.Chain Vm.Quota Common.BigInt,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.SysUtils System.Classes System.Generics.Collections;

type
  TRpcTokenInfo = record
    TokenName: string;
    TokenSymbol: string;
    TotalSupply: PString;
    Decimals: Byte;
    Owner: TAddress;
    TokenId: TTokenTypeId;
    MaxSupply: PString;
    OwnerBurnOnly: Boolean;
    IsReIssuable: Boolean;
    Index: Word;
    IsOwnerBurnOnly: Boolean;
  end;

  TAccountBlock = record
    BlockType: Byte;
    Height: string;
    Hash: THash;
    PrevHash: THash;
    PreviousHash: THash;
    AccountAddress: TAddress;
    Address: TAddress;
    PublicKey: TBytes;
    Producer: TAddress;
    FromAddress: TAddress;
    ToAddress: TAddress;
    FromBlockHash: THash;
    SendBlockHash: THash;
    TokenId: TTokenTypeId;
    Amount: PString;
    Fee: PString;
    Data: TBytes;
    Difficulty: PString;
    Nonce: TBytes;
    Signature: TBytes;
    Quota: PString;
    QuotaByStake: PString;
    QuotaUsed: PString;
    TotalQuota: PString;
    UtUsed: PString;
    LogHash: PHash;
    VmLogHash: PHash;
    SendBlockList: TArray<TAccountBlock>;
    TriggeredSendBlockList: TArray<TAccountBlock>;
    TokenInfo: PRpcTokenInfo;
    ConfirmedTimes: PString;
    Confirmations: PString;
    ConfirmedHash: PHash;
    FirstSnapshotHash: PHash;
    FirstSnapshotHeight: PString;
    ReceiveBlockHeight: PString;
    ReceiveBlockHash: PHash;
    Timestamp: Int64;
    function RpcToLedgerBlock: TAccountBlock;
    function ComputeHash: THash;
    procedure AddExtraInfo(AChain: IChain);
  end;

  TSnapshotBlock = record
    Producer: TAddress;
    SnapshotBlock: TSnapshotBlock;
    PreviousHash: THash;
    NextSeedHash: PHash;
    SnapshotData: TSnapshotContent;
    Timestamp: Int64;
  end;

  TSnapshotChunkV2 = record
    AccountBlocks: TArray<TAccountBlock>;
    SnapshotBlock: TSnapshotBlock;
  end;

  TRpcTokenBalanceInfo = record
    TokenInfo: PRpcTokenInfo;
    TotalAmount: string;
    Number: PString;
  end;

  TRpcAccountInfo = record
    AccountAddress: TAddress;
    TotalNumber: string;
    TokenBalanceInfoMap: TDictionary<TTokenTypeId, TRpcTokenBalanceInfo>;
  end;

  TBalanceInfo = record
    TokenInfo: PRpcTokenInfo;
    Balance: string;
    TransactionCount: PString;
  end;

  TAccountInfo = record
    Address: TAddress;
    BlockCount: string;
    BalanceInfoMap: TDictionary<TTokenTypeId, TBalanceInfo>;
  end;

  TPagingQueryBatch = record
    Address: TAddress;
    PageNumber: UInt64;
    PageCount: UInt64;
  end;

  TNormalRequestRawTxParam = record
    BlockType: Byte;
    Height: string;
    Hash: THash;
    PrevHash: THash;
    PreviousHash: THash;
    AccountAddress: TAddress;
    Address: TAddress;
    PublicKey: TBytes;
    ToAddress: TAddress;
    TokenId: TTokenTypeId;
    Amount: string;
    Data: TBytes;
    Difficulty: PString;
    Nonce: TBytes;
    Signature: TBytes;
    function LedgerAccountBlock: TAccountBlock;
  end;

function RawTokenInfoToRpc(TInfo: PTokenInfo; Tti: TTokenTypeId): TRpcTokenInfo;
function ToRpcAccountInfo(AChain: IChain; Info: PAccountInfo): TRpcAccountInfo;
function ToAccountInfo(AChain: IChain; Info: PAccountInfo): TAccountInfo;
function LedgerToRpcBlock(AChain: IChain; LAb: PAccountBlock): TAccountBlock;
function LedgerSnapshotBlockToRpcBlock(Sb: PSnapshotBlock): TSnapshotBlock;

implementation

uses System.StrUtils;

function RawTokenInfoToRpc(TInfo: PTokenInfo; Tti: TTokenTypeId): TRpcTokenInfo;
var
  Rt: TRpcTokenInfo;
  S: string;
begin
  if TInfo <> nil then
  begin
    Rt.TokenName := TInfo.TokenName;
    Rt.TokenSymbol := TInfo.TokenSymbol;
    Rt.Decimals := TInfo.Decimals;
    Rt.Owner := TInfo.Owner;
    Rt.TokenId := Tti;
    Rt.OwnerBurnOnly := TInfo.OwnerBurnOnly;
    Rt.IsOwnerBurnOnly := TInfo.OwnerBurnOnly;
    Rt.IsReIssuable := TInfo.IsReIssuable;
    Rt.Index := TInfo.Index;
    if TInfo.TotalSupply <> nil then
    begin
      S := TInfo.TotalSupply.ToString;
      Rt.TotalSupply := @S;
    end;
    if TInfo.MaxSupply <> nil then
    begin
      S := TInfo.MaxSupply.ToString;
      Rt.MaxSupply := @S;
    end;
  end;
  Result := Rt;
end;

function ToRpcAccountInfo(AChain: IChain; Info: PAccountInfo): TRpcAccountInfo;
var
  R: TRpcAccountInfo;
  Tti: TTokenTypeId;
  V: PTokenBalanceInfo;
  TInfo: PTokenInfo;
  B: TRpcTokenBalanceInfo;
  Number: string;
begin
  if Info = nil then
    Exit;
  R.AccountAddress := Info.AccountAddress;
  R.TotalNumber := IntToStr(Info.TotalNumber);
  R.TokenBalanceInfoMap := TDictionary<TTokenTypeId, TRpcTokenBalanceInfo>.Create;
  for Tti in Info.TokenBalanceInfoMap.Keys do
  begin
    V := Info.TokenBalanceInfoMap[Tti];
    if V <> nil then
    begin
      TInfo := AChain.GetTokenInfoById(Tti);
      if TInfo = nil then
        Continue;
      B.TokenInfo := @RawTokenInfoToRpc(TInfo, Tti);
      B.TotalAmount := V.TotalAmount.ToString;
      if V.Number > 0 then
      begin
        Number := IntToStr(V.Number);
        B.Number := @Number;
      end;
      R.TokenBalanceInfoMap.Add(Tti, B);
    end;
  end;
  Result := R;
end;

function ToAccountInfo(AChain: IChain; Info: PAccountInfo): TAccountInfo;
var
  R: TAccountInfo;
  Tti: TTokenTypeId;
  V: PTokenBalanceInfo;
  TInfo: PTokenInfo;
  B: TBalanceInfo;
  Number: string;
begin
  if Info = nil then
    Exit;
  R.Address := Info.AccountAddress;
  R.BlockCount := IntToStr(Info.TotalNumber);
  R.BalanceInfoMap := TDictionary<TTokenTypeId, TBalanceInfo>.Create;
  for Tti in Info.TokenBalanceInfoMap.Keys do
  begin
    V := Info.TokenBalanceInfoMap[Tti];
    if V <> nil then
    begin
      TInfo := AChain.GetTokenInfoById(Tti);
      if TInfo = nil then
        Continue;
      B.TokenInfo := @RawTokenInfoToRpc(TInfo, Tti);
      B.Balance := V.TotalAmount.ToString;
      if V.Number > 0 then
      begin
        Number := IntToStr(V.Number);
        B.TransactionCount := @Number;
      end;
      R.BalanceInfoMap.Add(Tti, B);
    end;
  end;
  Result := R;
end;

function TAccountBlock.RpcToLedgerBlock: TAccountBlock;
var
  LAb: TAccountBlock;
  DifficultyStr: TBigInteger;
  QuotaStr, TotalQuotaStr: PString;
  SendBlockList: TArray<TAccountBlock>;
  SubLAbList: TArray<TAccountBlock>;
  K: Integer;
  V: TAccountBlock;
  SubLAb: TAccountBlock;
begin
  LAb.BlockType := Self.BlockType;
  LAb.Hash := Self.Hash;
  LAb.PrevHash := Self.PrevHash;
  LAb.AccountAddress := Self.AccountAddress;
  LAb.PublicKey := Self.PublicKey;
  LAb.ToAddress := Self.ToAddress;
  LAb.FromBlockHash := Self.FromBlockHash;
  LAb.TokenId := Self.TokenId;
  LAb.Data := Self.Data;
  LAb.Nonce := Self.Nonce;
  LAb.Signature := Self.Signature;
  LAb.LogHash := Self.LogHash;

  if Self.VmLogHash <> nil then
    LAb.LogHash := Self.VmLogHash;

  if not Self.PreviousHash.IsZero then
    LAb.PrevHash := Self.PreviousHash;

  if not Self.Address.IsZero then
    LAb.AccountAddress := Self.Address;

  if not Self.SendBlockHash.IsZero then
    LAb.FromBlockHash := Self.SendBlockHash;

  LAb.Height := StrToInt(Self.Height);

  LAb.Amount := TBigInteger.Create(0);
  if Self.Amount <> nil then
    LAb.Amount.SetString(Self.Amount^, 10);

  LAb.Fee := TBigInteger.Create(0);
  if Self.Fee <> nil then
    LAb.Fee.SetString(Self.Fee^, 10);

  if Self.Nonce <> nil then
  begin
    if Self.Difficulty = nil then
      raise Exception.Create('lack of difficulty field');
    DifficultyStr := TBigInteger.Create;
    DifficultyStr.SetString(Self.Difficulty^, 10);
    LAb.Difficulty := DifficultyStr;
  end;

  if Self.QuotaByStake <> nil then
    QuotaStr := Self.QuotaByStake
  else if Self.Quota <> nil then
    QuotaStr := Self.Quota;
  if QuotaStr <> nil then
    LAb.Quota := StrToInt(QuotaStr^);

  if Self.TotalQuota <> nil then
    TotalQuotaStr := Self.TotalQuota
  else if Self.QuotaUsed <> nil then
    TotalQuotaStr := Self.QuotaUsed;
  if TotalQuotaStr <> nil then
    LAb.QuotaUsed := StrToInt(TotalQuotaStr^);

  if not Self.AccountAddress.IsContractAddr then
    Exit(LAb);

  if Length(Self.TriggeredSendBlockList) > 0 then
    SendBlockList := Self.TriggeredSendBlockList
  else if Length(Self.SendBlockList) > 0 then
    SendBlockList := Self.SendBlockList;

  if Length(SendBlockList) > 0 then
  begin
    SetLength(SubLAbList, Length(SendBlockList));
    for K := 0 to High(SendBlockList) do
    begin
      V := SendBlockList[K];
      SubLAb := V.RpcToLedgerBlock;
      SubLAbList[K] := SubLAb;
    end;
    LAb.SendBlockList := SubLAbList;
  end;

  Result := LAb;
end;

function TAccountBlock.ComputeHash: THash;
var
  LAb: TAccountBlock;
begin
  LAb := Self.RpcToLedgerBlock;
  Result := LAb.ComputeHash;
end;

procedure TAccountBlock.AddExtraInfo(AChain: IChain);
var
  Token: PTokenInfo;
  ReceiveBlock: PAccountBlock;
  HeightStr, ConfirmedTimeStr, FirstSnapshotHeight: string;
  LatestSb, ConfirmedBlock: PSnapshotBlock;
begin
  if Self.TokenId <> TTypes.ZERO_TOKENID then
  begin
    Token := AChain.GetTokenInfoById(Self.TokenId);
    Self.TokenInfo := @RawTokenInfoToRpc(Token, Self.TokenId);
  end;

  if Self.BlockType.IsSendBlock then
  begin
    ReceiveBlock := AChain.GetReceiveAbBySendAb(Self.Hash);
    if ReceiveBlock <> nil then
    begin
      HeightStr := IntToStr(ReceiveBlock.Height);
      Self.ReceiveBlockHeight := @HeightStr;
      Self.ReceiveBlockHash := @ReceiveBlock.Hash;
    end;
  end;

  LatestSb := AChain.GetLatestSnapshotBlock;
  ConfirmedBlock := AChain.GetConfirmSnapshotHeaderByAbHash(Self.Hash);
  if (ConfirmedBlock <> nil) and (LatestSb <> nil) and (ConfirmedBlock.Height <= LatestSb.Height) then
  begin
    ConfirmedTimeStr := IntToStr(LatestSb.Height - ConfirmedBlock.Height + 1);
    Self.ConfirmedTimes := @ConfirmedTimeStr;
    Self.Confirmations := @ConfirmedTimeStr;
    Self.ConfirmedHash := ConfirmedBlock.Hash;
    Self.FirstSnapshotHash := ConfirmedBlock.Hash;
    FirstSnapshotHeight := IntToStr(ConfirmedBlock.Height);
    Self.FirstSnapshotHeight := @FirstSnapshotHeight;
    Self.Timestamp := Round(ConfirmedBlock.Timestamp);
  end;
end;

function LedgerSnapshotBlockToRpcBlock(Sb: PSnapshotBlock): TSnapshotBlock;
var
  RpcBlock: TSnapshotBlock;
begin
  if Sb = nil then
    Exit;
  RpcBlock.SnapshotBlock := Sb^;
  RpcBlock.Producer := Sb.Producer;
  RpcBlock.PreviousHash := Sb.PrevHash;
  RpcBlock.NextSeedHash := @Sb.SeedHash;
  RpcBlock.SnapshotData := Sb.SnapshotContent;
  RpcBlock.Timestamp := Round(Sb.Timestamp);
  Result := RpcBlock;
end;

function LedgerToRpcBlock(AChain: IChain; LAb: PAccountBlock): TAccountBlock;
var
  RpcBlock: TAccountBlock;
  TotalQuota, QuotaUsed, UtUsed, Amount, Fee, Difficulty: string;
  SendBlock: PAccountBlock;
  SubBlockList: TArray<TAccountBlock>;
  K: Integer;
  V: PAccountBlock;
  SubRpcTx: TAccountBlock;
begin
  RpcBlock.BlockType := LAb.BlockType;
  RpcBlock.Hash := LAb.Hash;
  RpcBlock.PrevHash := LAb.PrevHash;
  RpcBlock.PreviousHash := LAb.PrevHash;
  RpcBlock.AccountAddress := LAb.AccountAddress;
  RpcBlock.Address := LAb.AccountAddress;
  RpcBlock.PublicKey := LAb.PublicKey;
  RpcBlock.FromBlockHash := LAb.FromBlockHash;
  RpcBlock.SendBlockHash := LAb.FromBlockHash;
  RpcBlock.TokenId := LAb.TokenId;
  RpcBlock.Data := LAb.Data;
  RpcBlock.Signature := LAb.Signature;
  RpcBlock.LogHash := @LAb.LogHash;
  RpcBlock.VmLogHash := @LAb.LogHash;
  RpcBlock.Producer := LAb.Producer;
  RpcBlock.Height := IntToStr(LAb.Height);

  TotalQuota := IntToStr(LAb.Quota);
  RpcBlock.Quota := @TotalQuota;
  RpcBlock.QuotaByStake := RpcBlock.Quota;

  QuotaUsed := IntToStr(LAb.QuotaUsed);
  RpcBlock.QuotaUsed := @QuotaUsed;
  RpcBlock.TotalQuota := RpcBlock.QuotaUsed;

  UtUsed := FloatToStr(LAb.QuotaUsed / TQuota.QuotaPerUt);
  RpcBlock.UtUsed := @UtUsed;

  if LAb.IsSendBlock then
  begin
    RpcBlock.FromAddress := LAb.AccountAddress;
    RpcBlock.ToAddress := LAb.ToAddress;
    if LAb.Amount <> nil then
    begin
      Amount := LAb.Amount.ToString;
      RpcBlock.Amount := @Amount;
    end;
    if LAb.Fee <> nil then
    begin
      Fee := LAb.Fee.ToString;
      RpcBlock.Fee := @Fee;
    end;
  end
  else
  begin
    SendBlock := AChain.GetAccountBlockByHash(LAb.FromBlockHash);
    if SendBlock <> nil then
    begin
      RpcBlock.FromAddress := SendBlock.AccountAddress;
      RpcBlock.ToAddress := SendBlock.ToAddress;
      RpcBlock.FromBlockHash := SendBlock.Hash;
      RpcBlock.TokenId := SendBlock.TokenId;
      if SendBlock.Amount <> nil then
      begin
        Amount := SendBlock.Amount.ToString;
        RpcBlock.Amount := @Amount;
      end;
      if SendBlock.Fee <> nil then
      begin
        Fee := SendBlock.Fee.ToString;
        RpcBlock.Fee := @Fee;
      end;
    end;
  end;

  RpcBlock.Nonce := LAb.Nonce;
  if LAb.Difficulty <> nil then
  begin
    Difficulty := LAb.Difficulty.ToString;
    RpcBlock.Difficulty := @Difficulty;
  end;

  RpcBlock.AddExtraInfo(AChain);

  if Length(LAb.SendBlockList) > 0 then
  begin
    SetLength(SubBlockList, Length(LAb.SendBlockList));
    for K := 0 to High(LAb.SendBlockList) do
    begin
      V := LAb.SendBlockList[K];
      SubRpcTx := LedgerToRpcBlock(AChain, V);
      SubBlockList[K] := SubRpcTx;
    end;
    RpcBlock.SendBlockList := SubBlockList;
    RpcBlock.TriggeredSendBlockList := SubBlockList;
  end;

  Result := RpcBlock;
end;

function TNormalRequestRawTxParam.LedgerAccountBlock: TAccountBlock;
var
  LAb: TAccountBlock;
  DifficultyStr: TBigInteger;
begin
  if Self.AccountAddress.IsContractAddr then
    raise Exception.Create('can''t send tx for the contract');

  LAb.BlockType := Self.BlockType;
  LAb.Hash := Self.Hash;
  LAb.PrevHash := Self.PrevHash;
  LAb.AccountAddress := Self.AccountAddress;
  LAb.PublicKey := Self.PublicKey;
  LAb.ToAddress := Self.ToAddress;
  LAb.TokenId := Self.TokenId;
  LAb.Data := Self.Data;
  LAb.Signature := Self.Signature;

  if not Self.PreviousHash.IsZero then
    LAb.PrevHash := Self.PreviousHash;

  if not Self.Address.IsZero then
    LAb.AccountAddress := Self.Address;

  LAb.Height := StrToInt(Self.Height);

  LAb.Amount := TBigInteger.Create(0);
  LAb.Amount.SetString(Self.Amount, 10);

  if Self.Nonce <> nil then
  begin
    if Self.Difficulty = nil then
      raise Exception.Create('lack of difficulty field');
    DifficultyStr := TBigInteger.Create;
    DifficultyStr.SetString(Self.Difficulty^, 10);
    LAb.Difficulty := DifficultyStr;
    LAb.Nonce := Self.Nonce;
  end;

  Result := LAb;
end;

end.
