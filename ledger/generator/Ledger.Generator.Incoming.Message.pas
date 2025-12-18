unit incoming_message;

interface

uses
  Ledger.Generator.Generator,
  Ledger.Generator.Utils,
  Ledger.Generator.Utils.Test,
  System.SysUtils System.Classes,
  Vite.Interfaces Vite.Ledger Vite.Common Vite.Pow big_int;

function IncomingMessageToBlock(vmDb: IVmDb; im: IIncomingMessage): TAccountBlock;

implementation

function IncomingMessageToBlock(vmDb: IVmDb; im: IIncomingMessage): TAccountBlock;
var
  block: TAccountBlock;
  prevBlock: TAccountBlock;
  prevHash: THash;
  preHeight: UInt64;
  nonce: TBytes;
  err: Exception;
begin
  block := TAccountBlock.Create;
  block.BlockType := im.BlockType;
  block.AccountAddress := im.AccountAddress;
  block.Quota := 0;
  block.QuotaUsed := 0;
  block.SendBlockList := nil;
  block.LogHash := nil;
  block.Hash := THash.Create;
  block.Signature := nil;
  block.PublicKey := nil;

  case im.BlockType of
    btSendCreate, btSendRefund, btSendReward, btSendCall:
    begin
      block.Data := im.Data;
      block.FromBlockHash := THash.Create;
      if im.ToAddress <> nil then
        block.ToAddress := im.ToAddress^
      else if im.BlockType <> btSendCreate then
        raise Exception.Create('pack send failed, toAddress can''t be nil');

      if (im.TokenId = nil) or (im.TokenId^ = TTokenId.ZERO_TOKENID) then
      begin
        if (im.Amount <> nil) and (im.Amount.Cmp(TBigInt.Big0) <> 0) then
          raise Exception.Create('pack send failed, tokenId can''t be empty when amount have actual value');
        block.Amount := TBigInt.Create(0);
        block.TokenId := TTokenId.ZERO_TOKENID;
      end
      else
      begin
        if im.Amount = nil then
          block.Amount := TBigInt.Create(0)
        else
        begin
          if (im.Amount.Sign < 0) or (im.Amount.BitLen > TMath.MaxBigIntLen) then
            raise Exception.Create('pack send failed, amount out of bounds');
          block.Amount := im.Amount;
        end;
        block.TokenId := im.TokenId^;
      end;

      if im.Fee = nil then
        block.Fee := TBigInt.Create(0)
      else
      begin
        if (im.Fee.Sign < 0) or (im.Fee.BitLen > TMath.MaxBigIntLen) then
          raise Exception.Create('pack send failed, fee out of bounds');
        block.Fee := im.Fee;
      end;

      prevBlock := vmDb.PrevAccountBlock;
      if prevBlock = nil then
        raise Exception.Create('account address doesn''t exist');

      block.Height := prevBlock.Height + 1;
      block.PrevHash := prevBlock.Hash;
    end;
    btReceive:
    begin
      block.Data := nil;
      block.ToAddress := TAddress.Create;
      if (im.FromBlockHash <> nil) and (im.FromBlockHash^ <> THash.ZERO_HASH) then
        block.FromBlockHash := im.FromBlockHash^
      else
        raise Exception.Create('pack recvBlock failed, cause sendBlock.Hash is invaild');

      if (im.Amount <> nil) and (im.Amount.Cmp(TBigInt.Big0) <> 0) then
        raise Exception.Create('pack recvBlock failed, amount is invalid');
      if (im.TokenId <> nil) and (im.TokenId^ <> TTokenId.ZERO_TOKENID) then
        raise Exception.Create('pack recvBlock failed, cause tokenId is invaild');
      if (im.Fee <> nil) and (im.Fee.Cmp(TBigInt.Big0) <> 0) then
        raise Exception.Create('pack recvBlock failed, fee is invalid');

      prevBlock := vmDb.PrevAccountBlock;
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
      block.PrevHash := prevHash;
      block.Height := preHeight + 1;
    end;
  else
    raise Exception.Create('generator can''t solve this block type ' + block.BlockType.ToString);
  end;

  if im.Difficulty <> nil then
  begin
    nonce := TPoW.GetPowNonce(im.Difficulty, TDataHash.Create(block.AccountAddress.Bytes + block.PrevHash.Bytes));
    block.Nonce := nonce;
    block.Difficulty := im.Difficulty;
  end;

  Result := block;
end;

end.
