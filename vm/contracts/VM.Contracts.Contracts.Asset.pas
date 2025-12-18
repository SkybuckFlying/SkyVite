unit VM.Contracts.Contracts.Asset;

interface

uses
  Common.Types,
  Interfaces,
  Interfaces.Core,
  System.Classes,
  System.Math,
  System.RegularExpressions,
  System.SysUtils,
  unit_GoLang_Compatibility_version_006,
  VM.ABI.ABI,
  VM.Contracts.Contracts,
  VM.Contracts.Contracts.Dex.Fund,
  VM.Contracts.Contracts.Dex.Trade,
  VM.Contracts.Contracts.Governance,
  VM.Contracts.Contracts.Quota,
  VM.Contracts.Contracts.Test,
  VM.Contracts.Params,
  VM.Contracts.Reward.Test,
  VM.Util;

type
	TMethodIssue = class( TInterfacedObject, IVmMethod )
	public
		mMethodName : string;
		function GetFee( ParaBlock : TAccountBlock ) : TBigInt;
		function GetRefundData( ParaSendBlock : TAccountBlock; ParaSbHeight : UInt64; out ParaData : TBytes ) : Boolean;
		function GetSendQuota( const ParaData : TBytes; ParaGasTable : TQuotaTable ) : UInt64;
		function GetReceiveQuota( ParaGasTable : TQuotaTable ) : UInt64;
		function DoSend( ParaDb : IVmDb; ParaBlock : TAccountBlock ) : Error;
		function DoReceive( ParaDb : IVmDb; ParaBlock, ParaSendBlock : TAccountBlock; ParaVm : IVmEnvironment ) : TArray<TAccountBlock>;
	end;

	// ... similar classes for ReIssue, Burn, etc.

implementation

{ TMethodIssue }

function TMethodIssue.GetFee( ParaBlock : TAccountBlock ) : TBigInt;
begin
	if ParaBlock.Amount.Sign > 0 then raise Exception.Create( 'InvalidParam' );
	Result := TBigInt.From( 1000 ); // mock fee
end;

function TMethodIssue.GetRefundData( ParaSendBlock : TAccountBlock; ParaSbHeight : UInt64; out ParaData : TBytes ) : Boolean;
begin
	ParaData := nil;
	Result := False;
end;

function TMethodIssue.GetSendQuota( const ParaData : TBytes; ParaGasTable : TQuotaTable ) : UInt64;
begin
	Result := ParaGasTable.IssueQuota;
end;

function TMethodIssue.GetReceiveQuota( ParaGasTable : TQuotaTable ) : UInt64;
begin
	Result := 0;
end;

function TMethodIssue.DoSend( ParaDb : IVmDb; ParaBlock : TAccountBlock ) : Error;
var
	vParam : TParamIssue;
begin
	// deserialize, checkToken, packing...
	Result := nil;
end;

function TMethodIssue.DoReceive( ParaDb : IVmDb; ParaBlock, ParaSendBlock : TAccountBlock; ParaVm : IVmEnvironment ) : TArray<TAccountBlock>;
begin
	// issuance logic...
	Result := nil;
end;

end.
