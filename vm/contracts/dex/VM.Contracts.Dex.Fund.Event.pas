unit Vm.Contracts.Dex.DexFundEvent;

interface

uses
  Common.Types.Address Common.Types.TokenTypeId,
  Interfaces.VmDb Interfaces.Core.VmLogList,
  System.SysUtils System.Classes,
  VM.Contracts.Dex.Account,
  VM.Contracts.Dex.Calculator,
  Vm.Contracts.Dex.DexEvents Vm.Contracts.Dex.Proto.DexProto,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper,
  VM.Contracts.Dex.Fund.Helper.Test,
  VM.Contracts.Dex.Fund.Mine,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

procedure AddTokenEvent(Db: IVmDb; TokenInfo: TDexTokenInfo);
procedure AddMarketEvent(Db: IVmDb; MarketInfo: TDexMarketInfo);
procedure AddPeriodWithBizEvent(Db: IVmDb; PeriodId: UInt64; BizType: Byte);
procedure AddFeeDividendEvent(Db: IVmDb; Address: TAddress; FeeToken: TTokenTypeId; VxAmount, FeeDividend: TBigInteger);
procedure AddOperatorFeeDividendEvent(Db: IVmDb; Address: TAddress; OperatorMarketFee: TDexProtoOperatorMarketFee);
procedure AddMinedVxForTradeFeeEvent(Db: IVmDb; Address: TAddress; QuoteTokenType: Int32; FeeAmount: TBytes; VxMined: TBigInteger);
procedure AddMinedVxForInviteeFeeEvent(Db: IVmDb; Address: TAddress; QuoteTokenType: Int32; FeeAmount: TBytes; VxMined: TBigInteger);
procedure AddMinedVxForStakingEvent(Db: IVmDb; Address: TAddress; StakedAmt, MinedAmt: TBigInteger);
procedure AddMinedVxForOperationEvent(Db: IVmDb; BizType: Int32; Address: TAddress; Amount: TBigInteger);
procedure AddInviteRelationEvent(Db: IVmDb; Inviter, Invitee: TAddress; InviteCode: UInt32);
procedure AddSettleMakerMinedVxEvent(Db: IVmDb; PeriodId: UInt64; Page: Int32; Finish: Boolean);
procedure AddGrantMarketToAgentEvent(Db: IVmDb; Principal, Agent: TAddress; MarketId: Int32);
procedure AddRevokeMarketFromAgentEvent(Db: IVmDb; Principal, Agent: TAddress; MarketId: Int32);
procedure AddBurnViteEvent(Db: IVmDb; BizType: Integer; Amount: TBigInteger);
procedure AddTransferAssetEvent(Db: IVmDb; BizType: Integer; From, To: TAddress; Token: TTokenTypeId; Amount: TBigInteger; Extra: TBytes);
procedure AddErrEvent(Db: IVmDb; Err: Exception);

implementation

procedure DoEmitEventLog(Db: IVmDb; Event: IDexEvent);
var
  Log: TVmLog;
begin
  Log.Topics := [Event.GetTopicId];
  Log.Data := Event.ToDataBytes;
  Db.AddLog(Log);
end;

procedure AddTokenEvent(Db: IVmDb; TokenInfo: TDexTokenInfo);
var
  Event: TTokenEvent;
begin
  Event.TokenInfo := TokenInfo.TokenInfo;
  DoEmitEventLog(Db, Event);
end;

procedure AddMarketEvent(Db: IVmDb; MarketInfo: TDexMarketInfo);
var
  Event: TMarketEvent;
begin
  Event.MarketInfo := MarketInfo.MarketInfo;
  DoEmitEventLog(Db, Event);
end;

procedure AddPeriodWithBizEvent(Db: IVmDb; PeriodId: UInt64; BizType: Byte);
var
  Event: TPeriodJobWithBizEvent;
begin
  Event.PeriodJobForBiz.Period := PeriodId;
  Event.PeriodJobForBiz.BizType := BizType;
  DoEmitEventLog(Db, Event);
end;

procedure AddFeeDividendEvent(Db: IVmDb; Address: TAddress; FeeToken: TTokenTypeId; VxAmount, FeeDividend: TBigInteger);
var
  Event: TFeeDividendEvent;
begin
  Event.FeeDividendForVxHolder.Address := Address.Bytes;
  Event.FeeDividendForVxHolder.VxAmount := VxAmount.ToByteArray;
  Event.FeeDividendForVxHolder.FeeToken := FeeToken.Bytes;
  Event.FeeDividendForVxHolder.FeeDividend := FeeDividend.ToByteArray;
  DoEmitEventLog(Db, Event);
end;

procedure AddOperatorFeeDividendEvent(Db: IVmDb; Address: TAddress; OperatorMarketFee: TDexProtoOperatorMarketFee);
var
  Event: TOperatorFeeDividendEvent;
begin
  Event.OperatorFeeDividend.Address := Address.Bytes;
  Event.OperatorFeeDividend.MarketId := OperatorMarketFee.MarketId;
  Event.OperatorFeeDividend.TakerOperatorFeeRate := OperatorMarketFee.TakerOperatorFeeRate;
  Event.OperatorFeeDividend.MakerOperatorFeeRate := OperatorMarketFee.MakerOperatorFeeRate;
  Event.OperatorFeeDividend.Amount := OperatorMarketFee.Amount;
  DoEmitEventLog(Db, Event);
end;

procedure AddMinedVxForTradeFeeEvent(Db: IVmDb; Address: TAddress; QuoteTokenType: Int32; FeeAmount: TBytes; VxMined: TBigInteger);
var
  Event: TMinedVxForTradeFeeEvent;
begin
  Event.MinedVxForFee.Address := Address.Bytes;
  Event.MinedVxForFee.QuoteTokenType := QuoteTokenType;
  Event.MinedVxForFee.FeeAmount := FeeAmount;
  Event.MinedVxForFee.MinedAmount := VxMined.ToByteArray;
  DoEmitEventLog(Db, Event);
end;

procedure AddMinedVxForInviteeFeeEvent(Db: IVmDb; Address: TAddress; QuoteTokenType: Int32; FeeAmount: TBytes; VxMined: TBigInteger);
var
  Event: TMinedVxForInviteeFeeEvent;
begin
  Event.MinedVxForFee.Address := Address.Bytes;
  Event.MinedVxForFee.QuoteTokenType := QuoteTokenType;
  Event.MinedVxForFee.FeeAmount := FeeAmount;
  Event.MinedVxForFee.MinedAmount := VxMined.ToByteArray;
  DoEmitEventLog(Db, Event);
end;

procedure AddMinedVxForStakingEvent(Db: IVmDb; Address: TAddress; StakedAmt, MinedAmt: TBigInteger);
var
  Event: TMinedVxForStakingEvent;
begin
  Event.MinedVxForStaking.Address := Address.Bytes;
  Event.MinedVxForStaking.StakedAmount := StakedAmt.ToByteArray;
  Event.MinedVxForStaking.MinedAmount := MinedAmt.ToByteArray;
  DoEmitEventLog(Db, Event);
end;

procedure AddMinedVxForOperationEvent(Db: IVmDb; BizType: Int32; Address: TAddress; Amount: TBigInteger);
var
  Event: TMinedVxForOperationEvent;
begin
  Event.MinedVxForOperation.BizType := BizType;
  Event.MinedVxForOperation.Address := Address.Bytes;
  Event.MinedVxForOperation.Amount := Amount.ToByteArray;
  DoEmitEventLog(Db, Event);
end;

procedure AddInviteRelationEvent(Db: IVmDb; Inviter, Invitee: TAddress; InviteCode: UInt32);
var
  Event: TInviteRelationEvent;
begin
  Event.InviteRelation.Inviter := Inviter.Bytes;
  Event.InviteRelation.Invitee := Invitee.Bytes;
  Event.InviteRelation.InviteCode := InviteCode;
  DoEmitEventLog(Db, Event);
end;

procedure AddSettleMakerMinedVxEvent(Db: IVmDb; PeriodId: UInt64; Page: Int32; Finish: Boolean);
var
  Event: TSettleMakerMinedVxEvent;
begin
  Event.SettleMakerMinedVx.PeriodId := PeriodId;
  Event.SettleMakerMinedVx.Page := Page;
  Event.SettleMakerMinedVx.Finish := Finish;
  DoEmitEventLog(Db, Event);
end;

procedure AddGrantMarketToAgentEvent(Db: IVmDb; Principal, Agent: TAddress; MarketId: Int32);
var
  Event: TGrantMarketToAgentEvent;
begin
  Event.MarketAgentRelation.Principal := Principal.Bytes;
  Event.MarketAgentRelation.Agent := Agent.Bytes;
  Event.MarketAgentRelation.MarketId := MarketId;
  DoEmitEventLog(Db, Event);
end;

procedure AddRevokeMarketFromAgentEvent(Db: IVmDb; Principal, Agent: TAddress; MarketId: Int32);
var
  Event: TRevokeMarketFromAgentEvent;
begin
  Event.MarketAgentRelation.Principal := Principal.Bytes;
  Event.MarketAgentRelation.Agent := Agent.Bytes;
  Event.MarketAgentRelation.MarketId := MarketId;
  DoEmitEventLog(Db, Event);
end;

procedure AddBurnViteEvent(Db: IVmDb; BizType: Integer; Amount: TBigInteger);
var
  Event: TBurnViteEvent;
begin
  Event.BurnVite.BizType := BizType;
  Event.BurnVite.Amount := Amount.ToByteArray;
  DoEmitEventLog(Db, Event);
end;

procedure AddTransferAssetEvent(Db: IVmDb; BizType: Integer; From, To: TAddress; Token: TTokenTypeId; Amount: TBigInteger; Extra: TBytes);
var
  Event: TTransferAssetEvent;
begin
  Event.TransferAsset.BizType := BizType;
  Event.TransferAsset.From := From.Bytes;
  Event.TransferAsset.To := To.Bytes;
  Event.TransferAsset.Token := Token.Bytes;
  Event.TransferAsset.Amount := Amount.ToByteArray;
  Event.TransferAsset.Extra := Extra;
  DoEmitEventLog(Db, Event);
end;

procedure AddErrEvent(Db: IVmDb; Err: Exception);
var
  Event: TErrEvent;
begin
  Event := TErrEvent.Create(Err.Message);
  DoEmitEventLog(Db, Event);
end;

end.
