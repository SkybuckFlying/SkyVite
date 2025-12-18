unit Ledger.Chain.Genesis.CheckSum;

interface

uses
  Common.Types,
  Crypto,
  GoToDelphi.Helpers.BigInt,
  Interfaces,
  Ledger.Chain.Genesis.Account.Block,
  Ledger.Chain.Genesis.Genesis,
  Ledger.Chain.Genesis.Interface,
  Ledger.Chain.Genesis.Snapshot.Block,
  System.Classes,
  System.Generics.Collections,
  System.Numerics,
  System.SysUtils;

type
  TSortVmBlocks = class(TComparer<IVmAccountBlock>)
  public
    function Compare(const Left, Right: IVmAccountBlock): Integer; override;
  end;

  TBalanceInfo = record
    TokenId: TTokenTypeId;
    Balance: TBigInteger;
  end;

  TSortBalances = class(TComparer<TBalanceInfo>)
  public
    function Compare(const Left, Right: TBalanceInfo): Integer; override;
  end;

function CheckSum(ParaAccountBlocks: TArray<IVmAccountBlock>): THash;

implementation

uses
  System.Math;

{ TSortVmBlocks }

function TSortVmBlocks.Compare(const Left, Right: IVmAccountBlock): Integer;
var
  LBytes, RBytes: TBytes;
begin
  LBytes := Left.AccountBlock.Hash.Bytes;
  RBytes := Right.AccountBlock.Hash.Bytes;
  Result := TBytes.Compare(LBytes, RBytes);
end;

{ TSortBalances }

function TSortBalances.Compare(const Left, Right: TBalanceInfo): Integer;
var
  LBytes, RBytes: TBytes;
begin
  LBytes := Left.TokenId.Bytes;
  RBytes := Right.TokenId.Bytes;
  Result := TBytes.Compare(LBytes, RBytes);
end;

function CheckSum(ParaAccountBlocks: TArray<IVmAccountBlock>): THash;
var
  vSumHash: THash;
  vContent: TBytesStream;
  vSortedAccountBlocks: TList<IVmAccountBlock>;
  vVmBlock: IVmAccountBlock;
  vVmDb: IVmDb;
  vUnsavedBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
  vSortedBalances: TList<TBalanceInfo>;
  vTokenId: TTokenTypeId;
  vBalance: TBigInteger;
  vBalanceInfo: TBalanceInfo;
  vItem: TBalanceInfo;
  vStorage: TArray<TArray<Byte>>;
  vKv: TArray<Byte>;
  vBytes: TBytes;
  vError: Exception;
  vI: Integer;
begin
  vContent := TBytesStream.Create;
  vSortedAccountBlocks := TList<IVmAccountBlock>.Create;
  vSortedBalances := TList<TBalanceInfo>.Create;
  try
    for vI := 0 to High(ParaAccountBlocks) do
    begin
      vSortedAccountBlocks.Add(ParaAccountBlocks[vI]);
    end;

    vSortedAccountBlocks.Sort(TSortVmBlocks.Create);

    for vVmBlock in vSortedAccountBlocks do
    begin
      vBytes := vVmBlock.AccountBlock.Hash.Bytes;
      vContent.Write(vBytes, Length(vBytes));

      // balance
      vVmDb := vVmBlock.VmDb;
      vUnsavedBalanceMap := vVmDb.GetUnsavedBalanceMap;

      for vTokenId in vUnsavedBalanceMap.Keys do
      begin
        vBalance := vUnsavedBalanceMap[vTokenId];
        vBalanceInfo.TokenId := vTokenId;
        vBalanceInfo.Balance := vBalance;
        vSortedBalances.Add(vBalanceInfo);
      end;
      vSortedBalances.Sort(TSortBalances.Create);

      for vItem in vSortedBalances do
      begin
        vBytes := vItem.TokenId.Bytes;
        vContent.Write(vBytes, Length(vBytes));
        vBytes := vItem.Balance.Bytes;
        vContent.Write(vBytes, Length(vBytes));
      end;

      // key, value
      vStorage := vVmDb.GetUnsavedStorage;
      for vKv in vStorage do
      begin
        vContent.Write(vKv, Length(vKv));
      end;
    end;

    try
      vSumHash := BytesToHash(THash.Hash256(vContent.Bytes));
      vError := nil;
    except
      on E: Exception do
      begin
        vError := E;
      end;
    end;
    if vError <> nil then
    begin
      raise vError;
    end;

    Result := vSumHash;
  finally
    vContent.Free;
    vSortedAccountBlocks.Free;
    vSortedBalances.Free;
  end;
end;

end.
