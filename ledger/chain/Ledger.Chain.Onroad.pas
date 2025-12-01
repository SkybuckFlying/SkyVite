unit Ledger.Chain.OnRoad;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Common.Types,
  V2.Ledger.Chain.Plugins,
  V2.Ledger.Chain.Chain;

type
  TChainHelper = class helper for TChain
  public
    function LoadOnRoadRange(const ParaGid: TGid; ParaLoadFn: TLoadOnroadFn): string;
    function GetOnRoadBlocksByAddr(const ParaAddr: TAddress; ParaPageNum, ParaPageSize: Integer; out ParaBlocks: TArray<IAccountBlock>): string;
    procedure DeleteOnRoad(const ParaToAddress: TAddress; const ParaSendBlockHash: THash);
    function GetAccountOnRoadInfo(const ParaAddr: TAddress; out ParaAccountInfo: IAccountInfo): string;
    function LoadAllOnRoad(out ParaOnRoadData: TDictionary<TAddress, TArray<THash>>): string;
    function GetOnRoadInfoUnconfirmedHashList(const ParaAddr: TAddress; out ParaHashList: TArray<THash>): string;
    function UpdateOnRoadInfo(const ParaAddr: TAddress; const ParaTkId: TTokenTypeId; ParaNumber: TUInt64; ParaAmount: TBigInteger): string;
    function ClearOnRoadUnconfirmedCache(const ParaAddr: TAddress; const ParaHashList: TArray<THash>): string;
  end;

implementation

{ TChainHelper }

function TChainHelper.LoadOnRoadRange(const ParaGid: TGid; ParaLoadFn: TLoadOnroadFn): string;
var
  vAddrList: TArray<TAddress>;
  vCErr: string;
begin
  Result := '';
  try
    vAddrList := Self.GetContractList(ParaGid);
  except
    on E: Exception do
    begin
      Result := E.Message;
      Exit;
    end;
  end;

  try
    Self.FIndexDB.LoadRange(vAddrList, ParaLoadFn);
  except
    on E: Exception do
    begin
      vCErr := Format('c.indexDB.Load failed, addrList is %s. Error: %s', [TString.Join(',', vAddrList), E.Message]);
      Self.FLog.Error(vCErr, 'method', 'LoadOnRoad');
      Result := vCErr;
    end;
  end;
end;

function TChainHelper.GetOnRoadBlocksByAddr(const ParaAddr: TAddress; ParaPageNum, ParaPageSize: Integer; out ParaBlocks: TArray<IAccountBlock>): string;
var
  vHashList: TArray<THash>;
  vCErr: string;
  vCount: Integer;
  vHash: THash;
  vBlock: IAccountBlock;
begin
  Result := '';
  try
    vHashList := Self.FIndexDB.GetOnRoadHashList(ParaAddr, ParaPageNum, ParaPageSize);
  except
    on E: Exception do
    begin
      vCErr := Format('c.GetOnRoadBlocksByAddr failed, error is %s, address is %s, pageNum is %d, countPerPage is %d',
        [E.Message, ParaAddr.ToString, ParaPageNum, ParaPageSize]);
      Self.FLog.Error(vCErr, 'method', 'GetOnRoadBlocksByAddr');
      Result := vCErr;
      Exit;
    end;
  end;

  SetLength(ParaBlocks, Length(vHashList));
  vCount := 0;

  for vHash in vHashList do
  begin
    try
      vBlock := Self.GetAccountBlockByHash(vHash);
    except
      on E: Exception do
      begin
        Result := E.Message;
        Exit;
      end;
    end;
    if vBlock = nil then
    begin
      DeleteOnRoad(ParaAddr, vHash);
      Self.FLog.Error(Format('block is not exit, hash %s. fix onroad, hash %s is deleted', [vHash.ToString, vHash.ToString]), 'method', 'GetOnRoadBlocksByAddr');
      Continue;
    end;
    ParaBlocks[vCount] := vBlock;
    Inc(vCount);
  end;

  SetLength(ParaBlocks, vCount);
end;

procedure TChainHelper.DeleteOnRoad(const ParaToAddress: TAddress; const ParaSendBlockHash: THash);
begin
  Self.FFlushMu.BeginRead;
  try
    Self.FIndexDB.DeleteOnRoad(ParaToAddress, ParaSendBlockHash);
  finally
    Self.FFlushMu.EndRead;
  end;
end;

function TChainHelper.GetAccountOnRoadInfo(const ParaAddr: TAddress; out ParaAccountInfo: IAccountInfo): string;
var
  vOnRoadInfo: TOnRoadInfo;
begin
  Result := '';
  if Self.FPlugins = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  vOnRoadInfo := Self.FPlugins.GetPlugin('onRoadInfo') as TOnRoadInfo;
  if vOnRoadInfo = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  try
    ParaAccountInfo := vOnRoadInfo.GetAccountInfo(ParaAddr);
  except
    on E: Exception do
    begin
      Result := E.Message;
    end;
  end;
end;

function TChainHelper.LoadAllOnRoad(out ParaOnRoadData: TDictionary<TAddress, TArray<THash>>): string;
begin
  Result := '';
  try
    ParaOnRoadData := Self.FIndexDB.LoadAllHash;
  except
    on E: Exception do
    begin
      Result := E.Message;
    end;
  end;
end;

function TChainHelper.GetOnRoadInfoUnconfirmedHashList(const ParaAddr: TAddress; out ParaHashList: TArray<THash>): string;
var
  vOnRoadInfo: TOnRoadInfo;
begin
  Result := '';
  if Self.FPlugins = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  vOnRoadInfo := Self.FPlugins.GetPlugin('onRoadInfo') as TOnRoadInfo;
  if vOnRoadInfo = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  try
    ParaHashList := vOnRoadInfo.GetOnRoadInfoUnconfirmedHashList(ParaAddr);
  except
    on E: Exception do
    begin
      Result := E.Message;
    end;
  end;
end;

function TChainHelper.UpdateOnRoadInfo(const ParaAddr: TAddress; const ParaTkId: TTokenTypeId; ParaNumber: TUInt64; ParaAmount: TBigInteger): string;
var
  vOnRoadInfo: TOnRoadInfo;
begin
  Result := '';
  if Self.FPlugins = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  vOnRoadInfo := Self.FPlugins.GetPlugin('onRoadInfo') as TOnRoadInfo;
  if vOnRoadInfo = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  Result := vOnRoadInfo.UpdateOnRoadInfo(ParaAddr, ParaTkId, ParaNumber, ParaAmount);
end;

function TChainHelper.ClearOnRoadUnconfirmedCache(const ParaAddr: TAddress; const ParaHashList: TArray<THash>): string;
var
  vOnRoadInfo: TOnRoadInfo;
begin
  Result := '';
  if Self.FPlugins = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  vOnRoadInfo := Self.FPlugins.GetPlugin('onRoadInfo') as TOnRoadInfo;
  if vOnRoadInfo = nil then
  begin
    Result := 'plugins-OnRoadInfo''s service not provided';
    Exit;
  end;
  Result := vOnRoadInfo.RemoveFromUnconfirmedCache(ParaAddr, ParaHashList);
end;

end.