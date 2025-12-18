unit Interfaces.Core.AccountBlock;

interface

uses
  Common.Types,
  Common.VitePb,
  Crypto,
  Crypto.Ed25519,
  GoToDelphi.Helpers.BigInt,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.HashHeight,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils System.Generics.Collections Math.BigInt;

const
  BlockTypeSendCreate = 1;
  BlockTypeSendCall = 2;
  BlockTypeSendReward = 3;
  BlockTypeReceive = 4;
  BlockTypeReceiveError = 5;
  BlockTypeSendRefund = 6;
  BlockTypeGenesisReceive = 7;

type
  TAccountBlock = record
  private
    mProducer: ^TAddress;
    function GetProducer: TAddress;
  public
    BlockType: Byte;
    Hash: THash;
    PrevHash: THash;
    Height: UInt64;
    AccountAddress: TAddress;
    PublicKey: TPublicKey;
    ToAddress: TAddress;
    Amount: TBigInt;
    TokenId: TTokenTypeId;
    FromBlockHash: THash;
    Data: TBytes;
    Quota: UInt64;
    QuotaUsed: UInt64;
    Fee: TBigInt;
    LogHash: ^THash;
    Difficulty: ^TBigInt;
    Nonce: TBytes;
    SendBlockList: TArray<TAccountBlock>;
    Signature: TBytes;

    property Producer: TAddress read GetProducer;

    function Copy: TAccountBlock;
    function HashSourceLength: Integer;
    function HashSource(const ParaExtraByte: TBytes): TBytes;
    function ComputeHash: THash;
    function ComputeSendHash(const ParaHostBlock: TAccountBlock; ParaIndex: Byte): THash;
    function GetHashHeight: THashHeight;
    function VerifySignature(out ParaError: Exception): Boolean;
    function ToProto: TAccountBlockPb;
    function DeProto(const ParaPb: TAccountBlockPb): Exception;
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaBuf: TBytes): Exception;
    function IsSendBlock: Boolean;
    function IsReceiveBlock: Boolean;
    function IsGenesisBlock: Boolean;
  end;

function IsSendBlock(ParaBlockType: Byte): Boolean;
function IsReceiveBlock(ParaBlockType: Byte): Boolean;

implementation

uses
  Common.Helper,
  Common.BigInt;

{ TAccountBlock }

function TAccountBlock.GetProducer: TAddress;
var
  vError: Exception;
begin
  if mProducer = nil then
  begin
    New(mProducer);
    mProducer^ := TAddress.FromPublicKey(PublicKey, vError);
    if vError <> nil then
    begin
      // Handle error
    end;
  end;
  Result := mProducer^;
end;

function TAccountBlock.Copy: TAccountBlock;
var
  vSendBlock: TAccountBlock;
begin
  Result := Self;

  if Self.Amount <> nil then
    Result.Amount := TBigInt.Create(Self.Amount.AsBytes);

  if Self.Fee <> nil then
    Result.Fee := TBigInt.Create(Self.Fee.AsBytes);

  SetLength(Result.Data, Length(Self.Data));
  System.Move(Self.Data[0], Result.Data[0], Length(Self.Data));

  if Self.LogHash <> nil then
  begin
    New(Result.LogHash);
    Result.LogHash^ := Self.LogHash^;
  end;

  if Self.Difficulty <> nil then
    Result.Difficulty := TBigInt.Create(Self.Difficulty.AsBytes);

  if Length(Self.Nonce) > 0 then
  begin
    SetLength(Result.Nonce, Length(Self.Nonce));
    System.Move(Self.Nonce[0], Result.Nonce[0], Length(Self.Nonce));
  end;

  if Length(Self.Signature) > 0 then
  begin
    SetLength(Result.Signature, Length(Self.Signature));
    System.Move(Self.Signature[0], Result.Signature[0], Length(Self.Signature));
  end;

  for vSendBlock in Self.SendBlockList do
    Result.SendBlockList := Result.SendBlockList + [vSendBlock.Copy];
end;

function TAccountBlock.HashSourceLength: Integer;
begin
  Result := 1 + THash.Size + 8 + TAddress.Size;

  if Self.IsSendBlock then
    Result := Result + TAddress.Size + 32 + TTokenTypeId.Size
  else
    Result := Result + THash.Size;

  if Length(Self.Data) > 0 then
    Result := Result + THash.Size;

  Result := Result + 32;

  if Self.LogHash <> nil then
    Result := Result + THash.Size;

  Result := Result + 8 + THash.Size * Length(Self.SendBlockList);
end;

function TAccountBlock.HashSource(const ParaExtraByte: TBytes): TBytes;
var
  vSource: TBytes;
  vHeightBytes: TBytes;
  vDataHash: THash;
  vFeeBytes: TBytes;
  vSendBlock: TAccountBlock;
  vError: Exception;
begin
  SetLength(vSource, 0);
  vSource := vSource + [Self.BlockType];
  vSource := vSource + Self.PrevHash.Bytes;

  SetLength(vHeightBytes, 8);
  PULong(@vHeightBytes[0])^ := Self.Height;
  vSource := vSource + vHeightBytes;

  vSource := vSource + Self.AccountAddress.Bytes;

  if Self.IsSendBlock then
  begin
    vSource := vSource + Self.ToAddress.Bytes;
    vSource := vSource + LeftPadBytes(Self.Amount.AsBytes, 32);
    vSource := vSource + Self.TokenId.Bytes;
  end
  else
    vSource := vSource + Self.FromBlockHash.Bytes;

  if Length(Self.Data) > 0 then
  begin
    vDataHash := THash.Hash256(Self.Data, vError);
    if vError = nil then
      vSource := vSource + vDataHash.Bytes;
  end;

  if Self.Fee <> nil then
    vFeeBytes := Self.Fee.AsBytes
  else
    vFeeBytes := nil;
  vSource := vSource + LeftPadBytes(vFeeBytes, 32);

  if Self.LogHash <> nil then
    vSource := vSource + Self.LogHash.Bytes;

  vSource := vSource + LeftPadBytes(Self.Nonce, 8);

  for vSendBlock in Self.SendBlockList do
    vSource := vSource + vSendBlock.Hash.Bytes;

  vSource := vSource + ParaExtraByte;
  Result := vSource;
end;

function TAccountBlock.ComputeHash: THash;
var
  vSource: TBytes;
  vError: Exception;
begin
  vSource := Self.HashSource(nil);
  Result := THash.Hash256(vSource, vError);
end;

function TAccountBlock.ComputeSendHash(const ParaHostBlock: TAccountBlock; ParaIndex: Byte): THash;
var
  vExtraBytes: TBytes;
  vHeightBytes: TBytes;
  vSource: TBytes;
  vError: Exception;
begin
  SetLength(vExtraBytes, 0);
  vExtraBytes := vExtraBytes + ParaHostBlock.PrevHash.Bytes;

  SetLength(vHeightBytes, 8);
  PULong(@vHeightBytes[0])^ := ParaHostBlock.Height;
  vExtraBytes := vExtraBytes + vHeightBytes;

  vExtraBytes := vExtraBytes + [ParaIndex];
  vSource := Self.HashSource(vExtraBytes);
  Result := THash.Hash256(vSource, vError);
end;

function TAccountBlock.GetHashHeight: THashHeight;
begin
  Result.Height := Self.Height;
  Result.Hash := Self.Hash;
end;

function TAccountBlock.VerifySignature(out ParaError: Exception): Boolean;
begin
  Result := TEd25519.Verify(Self.PublicKey, Self.Hash.Bytes, Self.Signature, ParaError);
end;

function TAccountBlock.ToProto: TAccountBlockPb;
var
  vSendBlock: TAccountBlock;
begin
  Result := TAccountBlockPb.Create;
  Result.BlockType := TAccountBlockPb_BlockType(Self.BlockType);
  Result.Hash := Self.Hash.Bytes;
  Result.Height := Self.Height;
  if Self.Height > 1 then
    Result.PrevHash := Self.PrevHash.Bytes;
  Result.AccountAddress := Self.AccountAddress.Bytes;
  Result.PublicKey := Self.PublicKey;
  if Self.IsSendBlock then
    Result.ToAddress := Self.ToAddress.Bytes
  else
    Result.FromBlockHash := Self.FromBlockHash.Bytes;

  if Self.IsSendBlock or (Self.BlockType = BlockTypeGenesisReceive) then
  begin
    Result.Amount := Self.Amount.AsBytes;
    Result.TokenId := Self.TokenId.Bytes;
  end;

  Result.Data := Self.Data;
  Result.Quota := Self.Quota;
  Result.QuotaUsed := Self.QuotaUsed;

  if Self.Fee <> nil then
    Result.Fee := Self.Fee.AsBytes;

  if Self.LogHash <> nil then
    Result.LogHash := Self.LogHash.Bytes;

  if Self.Difficulty <> nil then
    Result.Difficulty := Self.Difficulty.AsBytes;

  Result.Nonce := Self.Nonce;

  for vSendBlock in Self.SendBlockList do
    Result.SendBlockList := Result.SendBlockList + [vSendBlock.ToProto];

  Result.Signature := Self.Signature;
end;

function TAccountBlock.DeProto(const ParaPb: TAccountBlockPb): Exception;
var
  vError: Exception;
  vLogHash: THash;
  vPbSendBlock: TAccountBlockPb;
  vSendBlock: TAccountBlock;
begin
  Result := nil;
  Self.BlockType := Byte(ParaPb.BlockType);
  Self.Hash := THash.FromBytes(ParaPb.Hash, vError);
  if vError <> nil then Exit(vError);
  Self.Height := ParaPb.Height;
  if Self.Height > 1 then
  begin
    Self.PrevHash := THash.FromBytes(ParaPb.PrevHash, vError);
    if vError <> nil then Exit(vError);
  end;
  Self.AccountAddress := TAddress.FromBytes(ParaPb.AccountAddress, vError);
  if vError <> nil then Exit(vError);
  Self.PublicKey := ParaPb.PublicKey;

  if Self.IsSendBlock then
  begin
    Self.ToAddress := TAddress.FromBytes(ParaPb.ToAddress, vError);
    if vError <> nil then Exit(vError);
  end
  else
  begin
    Self.FromBlockHash := THash.FromBytes(ParaPb.FromBlockHash, vError);
    if vError <> nil then Exit(vError);
  end;

  if Self.IsSendBlock or (Self.BlockType = BlockTypeGenesisReceive) then
  begin
    Self.TokenId := TTokenTypeId.FromBytes(ParaPb.TokenId, vError);
    if vError <> nil then Exit(vError);
    Self.Amount := TBigInt.Create(0);
    if Length(ParaPb.Amount) > 0 then
      Self.Amount.SetBytes(ParaPb.Amount);
  end;

  Self.Data := ParaPb.Data;
  Self.Quota := ParaPb.Quota;
  Self.QuotaUsed := ParaPb.QuotaUsed;

  Self.Fee := TBigInt.Create(0);
  if Length(ParaPb.Fee) > 0 then
    Self.Fee.SetBytes(ParaPb.Fee);

  if Length(ParaPb.LogHash) > 0 then
  begin
    vLogHash := THash.FromBytes(ParaPb.LogHash, vError);
    if vError <> nil then Exit(vError);
    New(Self.LogHash);
    Self.LogHash^ := vLogHash;
  end;

  if Length(ParaPb.Difficulty) > 0 then
  begin
    New(Self.Difficulty);
    Self.Difficulty.SetBytes(ParaPb.Difficulty);
  end;

  Self.Nonce := ParaPb.Nonce;

  for vPbSendBlock in ParaPb.SendBlockList do
  begin
    vSendBlock := Default(TAccountBlock);
    Result := vSendBlock.DeProto(vPbSendBlock);
    if Result <> nil then
      Exit(Result);
    Self.SendBlockList := Self.SendBlockList + [vSendBlock];
  end;

  Self.Signature := ParaPb.Signature;
end;

function TAccountBlock.Serialize(out ParaError: Exception): TBytes;
var
  vPb: TAccountBlockPb;
begin
  vPb := Self.ToProto;
  Result := vPb.ToBytes(ParaError);
end;

function TAccountBlock.Deserialize(const ParaBuf: TBytes): Exception;
var
  vPb: TAccountBlockPb;
begin
  Result := nil;
  vPb := TAccountBlockPb.Create;
  Result := vPb.FromBytes(ParaBuf);
  if Result = nil then
    Result := Self.DeProto(vPb);
end;

function TAccountBlock.IsSendBlock: Boolean;
begin
  Result := IsSendBlock(Self.BlockType);
end;

function TAccountBlock.IsReceiveBlock: Boolean;
begin
  Result := IsReceiveBlock(Self.BlockType);
end;

function TAccountBlock.IsGenesisBlock: Boolean;
begin
  Result := (Self.BlockType = BlockTypeGenesisReceive) and (Self.Height = 1);
end;

function IsSendBlock(ParaBlockType: Byte): Boolean;
begin
  Result := (ParaBlockType = BlockTypeSendCreate) or
            (ParaBlockType = BlockTypeSendCall) or
            (ParaBlockType = BlockTypeSendReward) or
            (ParaBlockType = BlockTypeSendRefund);
end;

function IsReceiveBlock(ParaBlockType: Byte): Boolean;
begin
  Result := (ParaBlockType = BlockTypeReceive) or
            (ParaBlockType = BlockTypeReceiveError) or
            (ParaBlockType = BlockTypeGenesisReceive);
end;

end.
