unit V2.Ledger.Chain.State;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Common.Types,
  V2.VM.Util,
  V2.Ledger.Chain.Chain;

type
  TChainStateHelper = class helper for TChain
  public
    function GetBalance(const AAddr: TAddress; const ATokenId: TTokenTypeId): TBigInteger;
    function GetBalanceMap(const AAddr: TAddress): TDictionary<TTokenTypeId, TBigInteger>;
    function GetConfirmedBalanceList(const AAddrList: TArray<TAddress>; const ATokenId: TTokenTypeId; const ASbHash: THash): TDictionary<TAddress, TBigInteger>;
    function GetContractCode(const AContractAddress: TAddress): TBytes;
    function GetContractMeta(const AContractAddress: TAddress): IContractMeta;
    function GetContractMetaInSnapshot(const AContractAddress: TAddress; ASnapshotHeight: TUInt64): IContractMeta;
    function GetContractList(const AGid: TGid): TArray<TAddress>;
    function GetVmLogList(const ALogListHash: THash): IVmLogList;
    function GetVMLogListByAddress(const AAddress: TAddress; AStart, AEnd: TUInt64; const AId: THash): IVmLogList;
    function GetQuotaUnused(const AAddress: TAddress): TUInt64;
    function GetGlobalQuota: IQuotaInfo;
    function GetQuotaUsedList(const AAddress: TAddress): TArray<IQuotaInfo>;
    function GetStorageIterator(const AAddress: TAddress; const APrefix: TBytes): IStorageIterator;
    function GetValue(const AAddress: TAddress; const AKey: TBytes): TBytes;
  end;

implementation

{ TChainStateHelper }

function TChainStateHelper.GetBalance(const AAddr: TAddress; const ATokenId: TTokenTypeId): TBigInteger;
var
  LCErr: string;
begin
  try
    Result := Self.FStateDB.GetBalance(AAddr, ATokenId);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetBalance failed, Addr is %s, tokenId is %s. Error: %s', [AAddr.ToString, ATokenId.ToString, E.Message]);
      Self.FLog.Error(LCErr, 'method', 'GetBalance');
      raise Exception.Create(LCErr);
    end;
  end;
end;

function TChainStateHelper.GetBalanceMap(const AAddr: TAddress): TDictionary<TTokenTypeId, TBigInteger>;
var
  LCErr: string;
begin
  try
    Result := Self.FStateDB.GetBalanceMap(AAddr);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetBalanceMap failed, Addr is %s. Error: %s', [AAddr.ToString, E.Message]);
      Self.FLog.Error(LCErr, 'method', 'GetBalance');
      raise Exception.Create(LCErr);
    end;
  end;
end;

function TChainStateHelper.GetConfirmedBalanceList(const AAddrList: TArray<TAddress>; const ATokenId: TTokenTypeId; const ASbHash: THash): TDictionary<TAddress, TBigInteger>;
var
  LBalanceMap: TDictionary<TAddress, TBigInteger>;
begin
  LBalanceMap := TDictionary<TAddress, TBigInteger>.Create;
  try
    Self.FStateDB.GetSnapshotBalanceList(LBalanceMap, ASbHash, AAddrList, ATokenId);
  except
    on E: Exception do
    begin
      Self.FLog.Error(E.Message, 'method', 'GetConfirmedBalance');
      raise E;
    end;
  end;
  Result := LBalanceMap;
end;

function TChainStateHelper.GetContractCode(const AContractAddress: TAddress): TBytes;
var
  LCode: TBytes;
  LCErr: string;
begin
  try
    LCode := Self.FStateDB.GetCode(AContractAddress);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetCode failed, error is %s, Addr is %s', [E.Message, AContractAddress.ToString]);
      Self.FLog.Error(LCErr, 'method', 'GetBalance');
      raise Exception.Create(LCErr);
    end;
  end;
  Result := LCode;
end;

function TChainStateHelper.GetContractMeta(const AContractAddress: TAddress): IContractMeta;
var
  LMeta: IContractMeta;
  LCErr: string;
begin
  LMeta := TContractMeta.GetBuiltinContractMeta(AContractAddress);
  if LMeta <> nil then
    Exit(LMeta);

  try
    LMeta := Self.FStateDB.GetContractMeta(AContractAddress);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetContractMeta failed, error is %s, Addr is %s', [E.Message, AContractAddress.ToString]);
      Self.FLog.Error(LCErr, 'method', 'GetBalance');
      raise Exception.Create(LCErr);
    end;
  end;
  Result := LMeta;
end;

function TChainStateHelper.GetContractMetaInSnapshot(const AContractAddress: TAddress; ASnapshotHeight: TUInt64): IContractMeta;
var
  LMeta: IContractMeta;
  LCErr: string;
  LCreateBlockHash: THash;
  LConfirmedHeight: TUInt64;
begin
  LMeta := TContractMeta.GetBuiltinContractMeta(AContractAddress);
  if LMeta <> nil then
    Exit(LMeta);

  try
    LMeta := Self.FStateDB.GetContractMeta(AContractAddress);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetContractMeta failed, error is %s, Addr is %s', [E.Message, AContractAddress.ToString]);
      Self.FLog.Error(LCErr, 'method', 'GetBalance');
      raise Exception.Create(LCErr);
    end;
  end;

  if LMeta = nil then
    Exit(nil);

  LCreateBlockHash := LMeta.CreateBlockHash;
  try
    LConfirmedHeight := Self.FIndexDB.GetConfirmHeightByHash(LCreateBlockHash);
  except
    on E: Exception do
      raise E;
  end;

  if (LConfirmedHeight <= 0) or (LConfirmedHeight > ASnapshotHeight) then
    Exit(nil);

  Result := LMeta;
end;

function TChainStateHelper.GetContractList(const AGid: TGid): TArray<TAddress>;
var
  LAddrList: TArray<TAddress>;
  LCErr: string;
begin
  try
    LAddrList := Self.FStateDB.GetContractList(AGid);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetContractList failed, gid is %s. Error: %s', [AGid.ToString, E.Message]);
      Self.FLog.Error(LCErr, 'method', 'GetContractList');
      raise Exception.Create(LCErr);
    end;
  end;
  if TUtil.IsDelegateGid(AGid) then
    LAddrList := Concat(LAddrList, TAddress.BuiltinContracts);
  Result := LAddrList;
end;

function TChainStateHelper.GetVmLogList(const ALogListHash: THash): IVmLogList;
var
  LLogList: IVmLogList;
  LCErr: string;
begin
  if ALogListHash = nil then
    Exit(nil);

  try
    LLogList := Self.FStateDB.GetVmLogList(ALogListHash);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetVmLogList failed, error is %s, logListHash is %s', [E.Message, ALogListHash.ToString]);
      Self.FLog.Error(LCErr, 'method', 'GetVmLogList');
      raise Exception.Create(LCErr);
    end;
  end;
  Result := LLogList;
end;

function TChainStateHelper.GetVMLogListByAddress(const AAddress: TAddress; AStart, AEnd: TUInt64; const AId: THash): IVmLogList;
var
  LBlocks: TArray<IAccountBlock>;
  LResultList: IVmLogList;
  LBlock: IAccountBlock;
  LLogs: IVmLogList;
  LLog: IVmLog;
begin
  if not TAddress.IsContractAddr(AAddress) then
    Exit(nil);

  try
    LBlocks := Self.GetAccountBlocksByRange(AAddress, AStart, AEnd);
  except
    on E: Exception do
      raise E;
  end;

  LResultList := TCollections.CreateObjectList<IVmLog>;
  for LBlock in LBlocks do
  begin
    try
      LLogs := GetVmLogList(LBlock.LogHash);
    except
      on E: Exception do
        raise E;
    end;
    for LLog in LLogs do
    begin
      if AId = nil then
        LResultList.Add(LLog)
      else if (AId <> nil) and (Length(LLog.Topics) > 0) and (LLog.Topics[0] = AId) then
        LResultList.Add(LLog);
    end;
  end;
  Result := LResultList;
end;

function TChainStateHelper.GetQuotaUnused(const AAddress: TAddress): TUInt64;
var
  LQuotaInfo: IQuota;
  LCErr: string;
begin
  try
    Self.GetStakeQuota(AAddress, LQuotaInfo);
  except
    on E: Exception do
    begin
      LCErr := Format('c.GetStakeQuota failed, address is %s. Error: %s', [AAddress.ToString, E.Message]);
      Self.FLog.Error(LCErr, 'method', 'GetQuotaUnused');
      raise Exception.Create(LCErr);
    end;
  end;
  Result := LQuotaInfo.Current;
end;

function TChainStateHelper.GetGlobalQuota: IQuotaInfo;
begin
  Result := Self.FCache.GetGlobalQuota;
end;

function TChainStateHelper.GetQuotaUsedList(const AAddress: TAddress): TArray<IQuotaInfo>;
begin
  Result := Self.FCache.GetQuotaUsedList(AAddress);
end;

function TChainStateHelper.GetStorageIterator(const AAddress: TAddress; const APrefix: TBytes): IStorageIterator;
begin
  Result := Self.FStateDB.NewStorageIterator(AAddress, APrefix);
end;

function TChainStateHelper.GetValue(const AAddress: TAddress; const AKey: TBytes): TBytes;
var
  LValue: TBytes;
  LCErr: string;
begin
  try
    LValue := Self.FStateDB.GetStorageValue(AAddress, AKey);
  except
    on E: Exception do
    begin
      LCErr := Format('c.stateDB.GetStorageValue failed, address is %s. key is %s', [AAddress.ToString, ToHex(AKey)]);
      Self.FLog.Error(LCErr, 'method', 'GetStorageValue');
      raise Exception.Create(LCErr);
    end;
  end;
  Result := LValue;
end;

end.
