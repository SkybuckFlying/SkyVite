unit Client.Client;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math.BigInt,
  Common.Types,
  Common.Errors,
  Crypto.Ed25519,
  Interfaces.Core,
  RpcApi.Api,
  Vm.Abi,
  Vm.Util,
  Wallet.EntropyStore,
  Wallet.Hd_Bip.Derivation,
  Client.DexClient;

type
  ERequestError = class(Exception);

  TParamPlaceOrder = record
    // Placeholder for dex.ParamPlaceOrder
  end;

  TParamDexCancelOrder = record
    // Placeholder for dex.ParamDexCancelOrder
  end;

  TRequestTxParams = record
    ToAddr: TAddress;
    SelfAddr: TAddress;
    Amount: TBigInteger;
    TokenId: TTokenTypeId;
    Data: TBytes;
  end;

  TRequestCreateContractParams = record
    SelfAddr: TAddress;
    Fee: TBigInteger;
    Arguments: TArray<TValue>;
    AbiStr: string;
    MetaParams: TCreateContractDataParam;
  end;

  TResponseTxParams = record
    SelfAddr: TAddress;
    RequestHash: THash;
  end;

  IDexClient = interface
    ['{B1A6F5C7-5D96-4E1A-9B3A-8D2C3F4E5A6B}']
    function BuildRequestNewOrderBlock(const ParaParam: TParamPlaceOrder; const ParaSelfAddr: TAddress; ParaPrev: PHashHeight): IAccountBlock;
    function BuildRequestCancelOrderBlock(const ParaParam: TParamDexCancelOrder; const ParaSelfAddr: TAddress; ParaPrev: PHashHeight): IAccountBlock;
  end;

  IClient = interface(IDexClient)
    ['{A0B6F5C7-5D96-4E1A-9B3A-8D2C3F4E5A6B}']
    function BuildNormalRequestBlock(const ParaParams: TRequestTxParams; ParaPrev: PHashHeight): IAccountBlock;
    function BuildRequestCreateContractBlock(const ParaParams: TRequestCreateContractParams; ParaPrev: PHashHeight): IAccountBlock;
    function BuildResponseBlock(const ParaParams: TResponseTxParams; ParaPrev: PHashHeight): IAccountBlock;
    function GetBalance(const ParaAddr: TAddress; const ParaTokenId: TTokenTypeId; out ParaBalance: TBigInteger; out ParaOnroad: TBigInteger): Exception;
    function GetBalanceAll(const ParaAddr: TAddress; out ParaAllBalance: IRpcAccountInfo; out ParaAllOnroad: IRpcAccountInfo): Exception;
    procedure SignData(const ParaWallet: IManager; const ParaBlock: IAccountBlock);
    procedure SignDataWithPriKey(const ParaKey: IKey; const ParaBlock: IAccountBlock);
    procedure SignDataWithEd25519Key(const ParaKey: TPrivateKey; const ParaBlock: IAccountBlock);
  end;

function NewClient(const ParaRpc: IRpcClient): IClient;

implementation

uses
  System.JSON,
  System.BigNumbers,
  System.IOUtils,
  System.Net.HttpClient,
  Vm.Contracts.Dex;

type
  TClient = class(TInterfacedObject, IClient)
  private
    mRpc: IRpcClient;
    function GetPrev(const ParaAddr: TAddress; out ParaHashHeight: THashHeight): Exception;
    function BuildDexNewOrderData(const ParaParam: TParamPlaceOrder): TBytes;
    function BuildDexCancelOrderData(const ParaParam: TParamDexCancelOrder): TBytes;
  public
    constructor Create(const ParaRpc: IRpcClient);
    destructor Destroy; override;
    function BuildRequestNewOrderBlock(const ParaParam: TParamPlaceOrder; const ParaSelfAddr: TAddress; ParaPrev: PHashHeight): IAccountBlock;
    function BuildRequestCancelOrderBlock(const ParaParam: TParamDexCancelOrder; const ParaSelfAddr: TAddress; ParaPrev: PHashHeight): IAccountBlock;
    function BuildNormalRequestBlock(const ParaParams: TRequestTxParams; ParaPrev: PHashHeight): IAccountBlock;
    function BuildRequestCreateContractBlock(const ParaParams: TRequestCreateContractParams; ParaPrev: PHashHeight): IAccountBlock;
    function BuildResponseBlock(const ParaParams: TResponseTxParams; ParaPrev: PHashHeight): IAccountBlock;
    function GetBalance(const ParaAddr: TAddress; const ParaTokenId: TTokenTypeId; out ParaBalance: TBigInteger; out ParaOnroad: TBigInteger): Exception;
    function GetBalanceAll(const ParaAddr: TAddress; out ParaAllBalance: IRpcAccountInfo; out ParaAllOnroad: IRpcAccountInfo): Exception;
    procedure SignData(const ParaWallet: IManager; const ParaBlock: IAccountBlock);
    procedure SignDataWithPriKey(const ParaKey: IKey; const ParaBlock: IAccountBlock);
    procedure SignDataWithEd25519Key(const ParaKey: TPrivateKey; const ParaBlock: IAccountBlock);
  end;

const
  ErrorEmptyHash = 'empty hash';
  ErrorNilWallet = 'nil wallet';
  ErrorNilKey = 'nil key';
  ErrorNilBlock = 'nil block';

function NewClient(const ParaRpc: IRpcClient): IClient;
begin
  Result := TClient.Create(ParaRpc);
end;

{ TClient }

constructor TClient.Create(const ParaRpc: IRpcClient);
begin
  inherited Create;
  mRpc := ParaRpc;
end;

destructor TClient.Destroy;
begin
  inherited Destroy;
end;

function TClient.BuildDexNewOrderData(const ParaParam: TParamPlaceOrder): TBytes;
var
  vAbiContract: IABI;
  vMethodName: string;
  vArguments: TArray<TValue>;
begin
  // Placeholder implementation
  Result := nil;
end;

function TClient.BuildDexCancelOrderData(const ParaParam: TParamDexCancelOrder): TBytes;
var
  vAbiContract: IABI;
  vMethodName: string;
  vArguments: TArray<TValue>;
begin
  // Placeholder implementation
  Result := nil;
end;

function TClient.BuildRequestNewOrderBlock(const ParaParam: TParamPlaceOrder; const ParaSelfAddr: TAddress; ParaPrev: PHashHeight): IAccountBlock;
var
  vData: TBytes;
  vParams: TRequestTxParams;
begin
  vData := BuildDexNewOrderData(ParaParam);
  vParams.SelfAddr := ParaSelfAddr;
  vParams.Data := vData;
  vParams.ToAddr := TAddress.AddressDexFund;
  vParams.Amount := TBigInteger.Zero;
  vParams.TokenId := TTypes.ViteTokenId;
  Result := BuildNormalRequestBlock(vParams, ParaPrev);
end;

function TClient.BuildRequestCancelOrderBlock(const ParaParam: TParamDexCancelOrder; const ParaSelfAddr: TAddress; ParaPrev: PHashHeight): IAccountBlock;
var
  vData: TBytes;
  vParams: TRequestTxParams;
begin
  vData := BuildDexCancelOrderData(ParaParam);
  vParams.SelfAddr := ParaSelfAddr;
  vParams.Data := vData;
  vParams.ToAddr := TAddress.AddressDexTrade;
  vParams.Amount := TBigInteger.Zero;
  vParams.TokenId := TTypes.ViteTokenId;
  Result := BuildNormalRequestBlock(vParams, ParaPrev);
end;

function TClient.GetPrev(const ParaAddr: TAddress; out ParaHashHeight: THashHeight): Exception;
var
  vLatest: IAccountBlock;
  vPrevHeight: UInt64;
begin
  Result := nil;
  try
    vLatest := mRpc.GetLatestBlock(ParaAddr);
    if vLatest <> nil then
    begin
      vPrevHeight := StrToInt64Def(vLatest.Height, 0);
      ParaHashHeight.Height := vPrevHeight;
      ParaHashHeight.Hash := vLatest.Hash;
    end
    else
    begin
      ParaHashHeight.Height := 0;
      ParaHashHeight.Hash := THash.CreateEmpty;
    end;
  except
    on E: Exception do
    begin
      Result := E;
    end;
  end;
end;

function TClient.BuildNormalRequestBlock(const ParaParams: TRequestTxParams; ParaPrev: PHashHeight): IAccountBlock;
var
  vPrev: THashHeight;
  vErr: Exception;
  vAmountStr: string;
  vAccBlock: IAccountBlock;
begin
  if ParaPrev <> nil then
  begin
    vPrev := ParaPrev^;
  end
  else
  begin
    vErr := GetPrev(ParaParams.SelfAddr, vPrev);
    if vErr <> nil then
    begin
      raise ERequestError.Create('Could not get previous block: ' + vErr.Message);
    end;
  end;

  vAmountStr := ParaParams.Amount.ToString;
  Result := TAccountBlock.Create;
  Result.BlockType := TBlockType.SendCall;
  Result.PrevHash := vPrev.Hash;
  Result.AccountAddress := ParaParams.SelfAddr;
  Result.ToAddress := ParaParams.ToAddr;
  Result.TokenId := ParaParams.TokenId;
  Result.Data := ParaParams.Data;
  Result.Height := IntToStr(vPrev.Height + 1);
  Result.Amount := vAmountStr;

  vAccBlock := Result.RpcToLedgerBlock;
  Result.Hash := vAccBlock.ComputeHash;
end;

function TClient.BuildRequestCreateContractBlock(const ParaParams: TRequestCreateContractParams; ParaPrev: PHashHeight): IAccountBlock;
var
  vPrev: THashHeight;
  vErr: Exception;
  vContractAddr: TAddress;
  vAbiContract: IABIContract;
  vConstructorParams: TBytes;
  vData: TBytes;
  vFeeStr: string;
  vFee: TBigInteger;
  vAccBlock: IAccountBlock;
  vStringReader: TStringReader;
begin
  if ParaPrev <> nil then
  begin
    vPrev := ParaPrev^;
  end
  else
  begin
    vErr := GetPrev(ParaParams.SelfAddr, vPrev);
    if vErr <> nil then
    begin
      raise ERequestError.Create('Could not get previous block: ' + vErr.Message);
    end;
  end;

  vContractAddr := TUtil.NewContractAddress(ParaParams.SelfAddr, vPrev.Height + 1, vPrev.Hash);
  vStringReader := TStringReader.Create(ParaParams.AbiStr);
  try
    vAbiContract := TAbiContract.JSONToABIContract(vStringReader);
  finally
    vStringReader.Free;
  end;

  vConstructorParams := vAbiContract.PackMethod('', ParaParams.Arguments);
  var vMetaParams: TCreateContractDataParam;
  vMetaParams := ParaParams.MetaParams;
  vMetaParams.Params := vConstructorParams;

  vData := mRpc.GetCreateContractData(vMetaParams);

  if ParaParams.Fee = nil then
  begin
    vFee := TBigInteger.Parse('10000000000000000000'); // 10 VITE
  end
  else
  begin
    vFee := ParaParams.Fee;
  end;
  vFeeStr := vFee.ToString;

  Result := TAccountBlock.Create;
  Result.BlockType := TBlockType.SendCreate;
  Result.PrevHash := vPrev.Hash;
  Result.AccountAddress := ParaParams.SelfAddr;
  Result.ToAddress := vContractAddr;
  Result.Data := vData;
  Result.Fee := vFeeStr;
  Result.Height := IntToStr(vPrev.Height + 1);

  vAccBlock := Result.RpcToLedgerBlock;
  Result.Hash := vAccBlock.ComputeHash;
end;

function TClient.BuildResponseBlock(const ParaParams: TResponseTxParams; ParaPrev: PHashHeight): IAccountBlock;
var
  vPrev: THashHeight;
  vErr: Exception;
  vAccountBlock: IAccountBlock;
begin
  if ParaPrev <> nil then
  begin
    vPrev := ParaPrev^;
  end
  else
  begin
    vErr := GetPrev(ParaParams.SelfAddr, vPrev);
    if vErr <> nil then
    begin
      raise ERequestError.Create('Could not get previous block: ' + vErr.Message);
    end;
  end;

  Result := TAccountBlock.Create;
  Result.BlockType := TBlockType.Receive;
  Result.PrevHash := vPrev.Hash;
  Result.AccountAddress := ParaParams.SelfAddr;
  Result.FromBlockHash := ParaParams.RequestHash;
  Result.Height := IntToStr(vPrev.Height + 1);

  vAccountBlock := Result.RpcToLedgerBlock;
  Result.Hash := vAccountBlock.ComputeHash;
end;

function TClient.GetBalance(const ParaAddr: TAddress; const ParaTokenId: TTokenTypeId; out ParaBalance: TBigInteger; out ParaOnroad: TBigInteger): Exception;
var
  vAllBalance, vAllOnroad: IRpcAccountInfo;
  vInfo: TTokenBalanceInfo;
  vErr: Exception;
begin
  Result := nil;
  ParaBalance := TBigInteger.Zero;
  ParaOnroad := TBigInteger.Zero;

  vErr := GetBalanceAll(ParaAddr, vAllBalance, vAllOnroad);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;

  if (vAllBalance <> nil) and (vAllBalance.TokenBalanceInfoMap <> nil) then
  begin
    if vAllBalance.TokenBalanceInfoMap.TryGetValue(ParaTokenId, vInfo) then
    begin
      ParaBalance := TBigInteger.Parse(vInfo.TotalAmount);
    end;
  end;
  if (vAllOnroad <> nil) and (vAllOnroad.TokenBalanceInfoMap <> nil) then
  begin
    if vAllOnroad.TokenBalanceInfoMap.TryGetValue(ParaTokenId, vInfo) then
    begin
      ParaOnroad := TBigInteger.Parse(vInfo.TotalAmount);
    end;
  end;
end;

function TClient.GetBalanceAll(const ParaAddr: TAddress; out ParaAllBalance: IRpcAccountInfo; out ParaAllOnroad: IRpcAccountInfo): Exception;
begin
  Result := nil;
  try
    ParaAllBalance := mRpc.GetAccountByAccAddr(ParaAddr);
    ParaAllOnroad := mRpc.GetOnroadInfoByAddress(ParaAddr);
  except
    on E: Exception do
    begin
      Result := E;
    end;
  end;
end;

procedure TClient.SignData(const ParaWallet: IManager; const ParaBlock: IAccountBlock);
var
  vSignedData, vPubKey: TBytes;
  vErr: Exception;
begin
  if ParaWallet = nil then
  begin
    raise ERequestError.Create(ErrorNilWallet);
  end;
  if ParaBlock = nil then
  begin
    raise ERequestError.Create(ErrorNilBlock);
  end;
  if ParaBlock.Hash.IsEmpty then
  begin
    raise ERequestError.Create(ErrorEmptyHash);
  end;

  vErr := ParaWallet.SignData(ParaBlock.AccountAddress, ParaBlock.Hash.Bytes, vSignedData, vPubKey);
  if vErr <> nil then
  begin
    raise ERequestError.Create(vErr.Message);
  end;
  ParaBlock.Signature := vSignedData;
  ParaBlock.PublicKey := vPubKey;
end;

procedure TClient.SignDataWithPriKey(const ParaKey: IKey; const ParaBlock: IAccountBlock);
var
  vSignData, vPub: TBytes;
  vErr: Exception;
begin
  if ParaKey = nil then
  begin
    raise ERequestError.Create(ErrorNilKey);
  end;
  if ParaBlock = nil then
  begin
    raise ERequestError.Create(ErrorNilBlock);
  end;
  if ParaBlock.Hash.IsEmpty then
  begin
    raise ERequestError.Create(ErrorEmptyHash);
  end;

  vErr := ParaKey.SignData(ParaBlock.Hash.Bytes, vSignData, vPub);
  if vErr <> nil then
  begin
    raise ERequestError.Create(vErr.Message);
  end;

  ParaBlock.Signature := vSignData;
  ParaBlock.PublicKey := vPub;
end;

procedure TClient.SignDataWithEd25519Key(const ParaKey: TPrivateKey; const ParaBlock: IAccountBlock);
var
  vPub, vSignData: TBytes;
begin
  if ParaKey = nil then
  begin
    raise ERequestError.Create(ErrorNilKey);
  end;
  if ParaBlock = nil then
  begin
    raise ERequestError.Create(ErrorNilBlock);
  end;
  if ParaBlock.Hash.IsEmpty then
  begin
    raise ERequestError.Create(ErrorEmptyHash);
  end;

  vPub := ParaKey.PubByte;
  vSignData := TEd25519.Sign(ParaKey, ParaBlock.Hash.Bytes);
  ParaBlock.Signature := vSignData;
  ParaBlock.PublicKey := vPub;
end;

end.
