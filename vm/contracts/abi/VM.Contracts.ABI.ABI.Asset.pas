unit Vm.Contracts.Abi.AbiAsset;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vm.Abi.Abi, Common.Types.Hash, Common.Types.TokenTypeId, Common.Types.Address,
  Interfaces.VmDb, Common.Types.Contracts, Vm.Util.Util;

const
  MethodNameIssue = 'Mint';
  MethodNameIssueV2 = 'IssueToken';
  MethodNameReIssue = 'Issue';
  MethodNameReIssueV2 = 'ReIssue';
  MethodNameBurn = 'Burn';
  MethodNameBurnV2 = 'Burn2';
  MethodNameTransferOwnership = 'TransferOwner';
  MethodNameTransferOwnershipV2 = 'TransferOwnership';
  MethodNameDisableReIssue = 'ChangeTokenType';
  MethodNameDisableReIssueV2 = 'DisableReIssue';
  MethodNameGetTokenInfo = 'GetTokenInfo';
  MethodNameGetTokenInfoV3 = 'GetTokenInformation';
  VariableNameTokenInfo = 'tokenInfo';
  VariableNameTokenIndex = 'tokenIndex';

var
  ABIDataAsset: TAbiContract;
  AssetBurnEventID: THash;

type
  TParamIssue = record
    IsReIssuable: Boolean;
    TokenName: string;
    TokenSymbol: string;
    TotalSupply: TBigInteger;
    Decimals: Byte;
    MaxSupply: TBigInteger;
    IsOwnerBurnOnly: Boolean;
  end;

  TParamReIssue = record
    TokenId: TTokenTypeId;
    Amount: TBigInteger;
    ReceiveAddress: TAddress;
  end;

  TParamTransferOwnership = record
    TokenId: TTokenTypeId;
    NewOwner: TAddress;
  end;

  TParamGetTokenInfo = record
    TokenId: TTokenTypeId;
    Bid: Byte;
  end;

function GetTokenInfoKey(TokenID: TTokenTypeId): TBytes;
function GetTokenIdFromTokenInfoKey(Key: TBytes): TTokenTypeId;
function IsTokenInfoKey(Key: TBytes): Boolean;
function GetNextTokenIndexKey(const TokenSymbol: string): TBytes;
function GetTokenIDListKey(Owner: TAddress): TBytes;
function AppendTokenID(OldIDList: TBytes; TokenID: TTokenTypeId): TBytes;
function DeleteTokenID(OldIDList: TBytes; TokenID: TTokenTypeId): TBytes;
function GetTokenByID(Db: IVmDb; TokenID: TTokenTypeId): TTokenInfo;
function GetTokenMap(Db: IVmDb): TDictionary<TTokenTypeId, TTokenInfo>;
function GetTokenMapByOwner(Db: IVmDb; Owner: TAddress): TDictionary<TTokenTypeId, TTokenInfo>;

implementation

function ParseTokenInfo(Data: TBytes): TTokenInfo;
var
  TokenInfo: TTokenInfo;
begin
  if Length(Data) = 0 then
    raise EUtilDataNotExist.Create('data not exist');
  ABIDataAsset.UnpackVariable(TValue.From<TTokenInfo>(TokenInfo), VariableNameTokenInfo, Data);
  Result := TokenInfo;
end;

function GetTokenInfoKey(TokenID: TTokenTypeId): TBytes;
begin
  Result := TokenID.Bytes;
end;

function GetTokenIdFromTokenInfoKey(Key: TBytes): TTokenTypeId;
begin
  Result := BytesToTokenTypeId(Key);
end;

function IsTokenInfoKey(Key: TBytes): Boolean;
begin
  Result := Length(Key) = TokenTypeIdSize;
end;

function GetNextTokenIndexKey(const TokenSymbol: string): TBytes;
begin
  Result := DataHash(TEncoding.UTF8.GetBytes(TokenSymbol)).Bytes;
end;

function GetTokenIDListKey(Owner: TAddress): TBytes;
begin
  Result := Owner.Bytes;
end;

function AppendTokenID(OldIDList: TBytes; TokenID: TTokenTypeId): TBytes;
begin
  Result := OldIDList + TokenID.Bytes;
end;

function DeleteTokenID(OldIDList: TBytes; TokenID: TTokenTypeId): TBytes;
var
  I: Integer;
  NewIDList: TBytes;
begin
  for I := 0 to Length(OldIDList) div TokenTypeIdSize - 1 do
  begin
    if CompareMem(Pointer(OldIDList[I * TokenTypeIdSize]), Pointer(TokenID.Bytes[0]), TokenTypeIdSize) then
    begin
      SetLength(NewIDList, Length(OldIDList) - TokenTypeIdSize);
      Move(OldIDList[0], NewIDList[0], I * TokenTypeIdSize);
      Move(OldIDList[(I + 1) * TokenTypeIdSize], NewIDList[I * TokenTypeIdSize], Length(OldIDList) - (I + 1) * TokenTypeIdSize);
      Result := NewIDList;
      Exit;
    end;
  end;
  Result := OldIDList;
end;

function GetTokenByID(Db: IVmDb; TokenID: TTokenTypeId): TTokenInfo;
var
  Data: TBytes;
begin
  if Db.Address.Compare(AddressAsset) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  Data := Db.GetValue(GetTokenInfoKey(TokenID));
  if Length(Data) > 0 then
    Result := ParseTokenInfo(Data)
  else
    FillChar(Result, SizeOf(TTokenInfo), 0);
end;

function GetTokenMap(Db: IVmDb): TDictionary<TTokenTypeId, TTokenInfo>;
var
  Iterator: IStorageIterator;
  TokenID: TTokenTypeId;
  TokenInfo: TTokenInfo;
begin
  Result := TDictionary<TTokenTypeId, TTokenInfo>.Create;
  if Db.Address.Compare(AddressAsset) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  Iterator := Db.NewStorageIterator([]);
  try
    while Iterator.Next do
    begin
      if IsTokenInfoKey(Iterator.Key) then
      begin
        TokenID := GetTokenIdFromTokenInfoKey(Iterator.Key);
        TokenInfo := ParseTokenInfo(Iterator.Value);
        Result.Add(TokenID, TokenInfo);
      end;
    end;
  finally
    Iterator.Release;
  end;
end;

function GetTokenMapByOwner(Db: IVmDb; Owner: TAddress): TDictionary<TTokenTypeId, TTokenInfo>;
var
  TokenIDList: TBytes;
  I: Integer;
  TokenID: TTokenTypeId;
begin
  Result := TDictionary<TTokenTypeId, TTokenInfo>.Create;
  if Db.Address.Compare(AddressAsset) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  TokenIDList := Db.GetValue(GetTokenIDListKey(Owner));
  for I := 0 to Length(TokenIDList) div TokenTypeIdSize - 1 do
  begin
    TokenID := BytesToTokenTypeId(Copy(TokenIDList, I * TokenTypeIdSize, TokenTypeIdSize));
    Result.Add(TokenID, GetTokenByID(Db, TokenID));
  end;
end;

initialization
  ABIDataAsset := TAbiContract.JSONToABIContract(TStringStream.Create(
    '[' +
    '{"type":"function","name":"Mint","inputs":[{"name":"isReIssuable","type":"bool"},{"name":"tokenName","type":"string"},{"name":"tokenSymbol","type":"string"},{"name":"totalSupply","type":"uint256"},{"name":"decimals","type":"uint8"},{"name":"maxSupply","type":"uint256"},{"name":"isOwnerBurnOnly","type":"bool"}]},' +
    '{"type":"function","name":"IssueToken","inputs":[{"name":"isReIssuable","type":"bool"},{"name":"tokenName","type":"string"},{"name":"tokenSymbol","type":"string"},{"name":"totalSupply","type":"uint256"},{"name":"decimals","type":"uint8"},{"name":"maxSupply","type":"uint256"},{"name":"isOwnerBurnOnly","type":"bool"}]},' +
    '{"type":"function","name":"Issue","inputs":[{"name":"tokenId","type":"tokenId"},{"name":"amount","type":"uint256"},{"name":"receiveAddress","type":"address"}]},' +
    '{"type":"function","name":"ReIssue","inputs":[{"name":"tokenId","type":"tokenId"},{"name":"amount","type":"uint256"},{"name":"receiveAddress","type":"address"}]},' +
    '{"type":"function","name":"Burn","inputs":[]},' +
    '{"type":"function","name":"Burn2","inputs":[{"name":"target","type":"uint256"},{"name":"to","type":"bytes"}]},' +
    '{"type":"function","name":"TransferOwner","inputs":[{"name":"tokenId","type":"tokenId"},{"name":"newOwner","type":"address"}]},' +
    '{"type":"function","name":"TransferOwnership","inputs":[{"name":"tokenId","type":"tokenId"},{"name":"newOwner","type":"address"}]},' +
    '{"type":"function","name":"ChangeTokenType","inputs":[{"name":"tokenId","type":"tokenId"}]},' +
    '{"type":"function","name":"DisableReIssue","inputs":[{"name":"tokenId","type":"tokenId"}]},' +
    '{"type":"function","name":"GetTokenInfo","inputs":[{"name":"tokenId","type":"tokenId"},{"name":"bid","type":"uint8"}]},' +
    '{"type":"function","name":"GetTokenInformation","inputs":[{"name":"tokenId","type":"tokenId"}]},' +
    '{"type":"callback","name":"GetTokenInfo","inputs":[{"name":"tokenId","type":"tokenId"},{"name":"bid","type":"uint8"},{"name":"exist","type":"bool"},{"name":"decimals","type":"uint8"},{"name":"tokenSymbol","type":"string"},{"name":"index","type":"uint16"},{"name":"ownerAddress","type":"address"}]},' +
    '{"type":"callback","name":"GetTokenInformation","inputs":[{"name":"id","type":"bytes32"},{"name":"tokenId","type":"tokenId"},{"name":"exist","type":"bool"},{"name":"isReIssuable","type":"bool"},{"name":"tokenName","type":"string"},{"name":"tokenSymbol","type":"string"},{"name":"totalSupply","type":"uint256"},{"name":"decimals","type":"uint8"},{"name":"maxSupply","type":"uint256"},{"name":"isOwnerBurnOnly","type":"bool"},{"name":"index","type":"uint16"},{"name":"ownerAddress","type":"address"}]},' +
    '{"type":"variable","name":"tokenInfo","inputs":[{"name":"tokenName","type":"string"},{"name":"tokenSymbol","type":"string"},{"name":"totalSupply","type":"uint256"},{"name":"decimals","type":"uint8"},{"name":"owner","type":"address"},{"name":"isReIssuable","type":"bool"},{"name":"maxSupply","type":"uint256"},{"name":"ownerBurnOnly","type":"bool"},{"name":"index","type":"uint16"}]},' +
    '{"type":"variable","name":"tokenIndex","inputs":[{"name":"nextIndex","type":"uint16"}]},' +
    '{"type":"event","name":"mint","inputs":[{"name":"tokenId","type":"tokenId","indexed":true}]},' +
    '{"type":"event","name":"issueToken","inputs":[{"name":"tokenId","type":"tokenId","indexed":true}]},' +
    '{"type":"event","name":"issue","inputs":[{"name":"tokenId","type":"tokenId","indexed":true}]},' +
    '{"type":"event","name":"reIssue","inputs":[{"name":"tokenId","type":"tokenId","indexed":true}]},' +
    '{"type":"event","name":"burn","inputs":[{"name":"tokenId","type":"tokenId","indexed":true},{"name":"address","type":"address"},{"name":"amount","type":"uint256"}]},' +
    '{"type":"event","name":"burn2","inputs":[{"name":"tokenId","type":"tokenId","indexed":true},{"name":"address","type":"address"},{"name":"amount","type":"uint256"},{"name":"target","type":"uint256"},{"name":"to","type":"bytes"}]},' +
    '{"type":"event","name":"transferOwner","inputs":[{"name":"tokenId","type":"tokenId","indexed":true},{"name":"owner","type":"address"}]},' +
    '{"type":"event","name":"transferOwnership","inputs":[{"name":"tokenId","type":"tokenId","indexed":true},{"name":"owner","type":"address"}]},' +
    '{"type":"event","name":"changeTokenType","inputs":[{"name":"tokenId","type":"tokenId","indexed":true}]},' +
    '{"type":"event","name":"disableReIssue","inputs":[{"name":"tokenId","type":"tokenId","indexed":true}]}' +
    ']'));

  AssetBurnEventID := ABIDataAsset.EventID('burn2');
end;

end.
