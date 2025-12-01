unit Ledger.Onroad.Pool.Types;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Vite.Interfaces.Core,
  Ledger.Onroad.Pool.Storage,
  Ledger.Onroad.Pool.Error.Table,
  Log15,
  Ledger.Onroad.Pool.Interfaces;

type
  TOrHeightValue = TArray<TOnroadTx>;

function NewOrHeightValueFromOnroadTxs(ParaTxs: TArray<TOnroadTx>): TOrHeightValue;
function IsEmpty(ParaHv: TOrHeightValue): Boolean;
function DirtyTxs(ParaHv: TOrHeightValue): TArray<TOnroadTx>;
function MinTx(ParaHv: TOrHeightValue): TOnroadTx;

type
  TOrHashHeight = record
    mHash: THash;
    mHeight: UInt64;
    mSubIndex: PUInt32;
    mCachedBlock: TAccountBlock;
    function ToString: string;
  end;

function NewOrHashHeightFromOnroadTx(ParaTx: TOnroadTx): TOrHashHeight;

type
  TOnRoadList = class(TList<TOrHashHeight>)
  public
    procedure Sort;
  end;

  TOnRoadBlock = record
    mCaller: TAddress;
    mOrAddr: TAddress;
    mHashHeight: TOrHashHeight;
    mBlock: TAccountBlock;
  end;

function LedgerBlockToOnRoad(ParaChain: IChainReader; ParaBlock: TAccountBlock): TOnRoadBlock;

type
  TPendingOnRoadList = class(TList<TOnRoadBlock>)
  public
    procedure Sort;
  end;

implementation

uses
  System.StrUtils;

var
  GOnroadPoolLog: ILog;

function NewOrHeightValueFromOnroadTxs(ParaTxs: TArray<TOnroadTx>): TOrHeightValue;
var
  vI: Integer;
begin
  SetLength(Result, Length(ParaTxs));
  for vI := 0 to High(ParaTxs) do
    Result[vI] := ParaTxs[vI];
end;

function IsEmpty(ParaHv: TOrHeightValue): Boolean;
begin
  Result := Length(ParaHv) = 0;
end;

function DirtyTxs(ParaHv: TOrHeightValue): TArray<TOnroadTx>;
var
  vSub: TOnroadTx;
begin
  Result := [];
  for vSub in ParaHv do
  begin
    if vSub.mFromIndex = nil then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := vSub;
    end;
  end;
end;

function MinTx(ParaHv: TOrHeightValue): TOnroadTx;
var
  vMin: TOnroadTx;
  vSub: TOnroadTx;
  vTmp: TOnroadTx;
begin
  if Length(ParaHv) = 0 then
    raise Exception.Create('height value is empty');

  vMin := Default(TOnroadTx);
  for vSub in ParaHv do
  begin
    if vSub.mFromIndex = nil then
      raise Exception.Create('sub index is nil');
    vTmp := vSub;
    if vMin.mFromHash.IsZero then
      vMin := vTmp
    else
    begin
      if vSub.mFromIndex^ < vMin.mFromIndex^ then
        vMin := vTmp;
    end;
  end;
  Result := vMin;
end;

{ TOrHashHeight }

function TOrHashHeight.ToString: string;
begin
  if mSubIndex = nil then
    Result := Format('orHashHeight: hash=%s,height=%d,subIndex=nil', [mHash.ToString, mHeight])
  else
    Result := Format('orHashHeight: hash=%s,height=%d,subIndex=%d', [mHash.ToString, mHeight, mSubIndex^]);
end;

function NewOrHashHeightFromOnroadTx(ParaTx: TOnroadTx): TOrHashHeight;
begin
  Result.mHash := ParaTx.mFromHash;
  Result.mHeight := ParaTx.mFromHeight;
  Result.mSubIndex := ParaTx.mFromIndex;
  Result.mCachedBlock := nil;
end;

{ TOnRoadList }

procedure TOnRoadList.Sort;
begin
  inherited Sort(TComparer<TOrHashHeight>.Construct(
    function(const Left, Right: TOrHashHeight): Integer
    begin
      if Left.mHeight < Right.mHeight then
        Result := -1
      else if Left.mHeight > Right.mHeight then
        Result := 1
      else
      begin
        if (Left.mSubIndex <> nil) and (Right.mSubIndex <> nil) then
        begin
          if Left.mSubIndex^ < Right.mSubIndex^ then
            Result := -1
          else if Left.mSubIndex^ > Right.mSubIndex^ then
            Result := 1
          else
            Result := 0;
        end
        else
          Result := 0;
      end;
    end));
end;

{ TOnRoadBlock }

function LedgerBlockToOnRoad(ParaChain: IChainReader; ParaBlock: TAccountBlock): TOnRoadBlock;
var
  vOr: TOnRoadBlock;
  vIndex: Cardinal;
  vFromBlock: TAccountBlock;
  vCompleteBlock: TAccountBlock;
  vK: Integer;
  vV: TAccountBlock;
  vIdx: Cardinal;
begin
  vOr := Default(TOnRoadBlock);
  vOr.mBlock := ParaBlock;

  if ParaBlock.IsSendBlock then
  begin
    vOr.mCaller := ParaBlock.AccountAddress;
    vOr.mOrAddr := ParaBlock.ToAddress;
    vIndex := 0;
    vOr.mHashHeight := Default(TOrHashHeight);
    vOr.mHashHeight.mHash := ParaBlock.Hash;
    vOr.mHashHeight.mHeight := ParaBlock.Height;
    vOr.mHashHeight.mSubIndex := @vIndex;
  end
  else
  begin
    vFromBlock := ParaChain.GetAccountBlockByHash(ParaBlock.FromBlockHash);
    if vFromBlock = nil then
      raise Exception.Create('failed to find send');
    vOr.mCaller := vFromBlock.AccountAddress;
    vOr.mOrAddr := vFromBlock.ToAddress;
    vOr.mHashHeight := Default(TOrHashHeight);
    vOr.mHashHeight.mHash := vFromBlock.Hash;
    vOr.mHashHeight.mHeight := vFromBlock.Height;
  end;

  if vOr.mCaller.IsContractAddress then
  begin
    vCompleteBlock := ParaChain.GetCompleteBlockByHash(vOr.mHashHeight.mHash);
    if vCompleteBlock = nil then
      raise EFindCompleteBlock.Create;
    vOr.mHashHeight.mHeight := vCompleteBlock.Height;

    for vK := 0 to High(vCompleteBlock.SendBlockList) do
    begin
      vV := vCompleteBlock.SendBlockList[vK];
      if vV.Hash.IsEqual(vOr.mHashHeight.mHash) then
      begin
        vIdx := vK;
        vOr.mHashHeight.mSubIndex := @vIdx;
        Break;
      end;
    end;
  end
  else
  begin
    vIndex := 0;
    vOr.mHashHeight.mSubIndex := @vIndex;
  end;
  Result := vOr;
end;

{ TPendingOnRoadList }

procedure TPendingOnRoadList.Sort;
begin
  inherited Sort(TComparer<TOnRoadBlock>.Construct(
    function(const Left, Right: TOnRoadBlock): Integer
    begin
      if Left.mHashHeight.mHeight < Right.mHashHeight.mHeight then
        Result := -1
      else if Left.mHashHeight.mHeight > Right.mHashHeight.mHeight then
        Result := 1
      else
      begin
        if (Left.mHashHeight.mSubIndex <> nil) and (Right.mHashHeight.mSubIndex <> nil) then
        begin
          if Left.mHashHeight.mSubIndex^ < Right.mHashHeight.mSubIndex^ then
            Result := -1
          else if Left.mHashHeight.mSubIndex^ > Right.mHashHeight.mSubIndex^ then
            Result := 1
          else
            Result := 0;
        end
        else
          Result := 0;
      end;
    end));
end;

initialization
  GOnroadPoolLog := TLog15.New('onroadPool', nil);
end.