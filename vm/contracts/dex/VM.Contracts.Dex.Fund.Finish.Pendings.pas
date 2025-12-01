unit Vm.Contracts.Dex.DexFundFinishPendings;

interface

uses
  System.SysUtils, System.Classes,
  Interfaces.VmDb, Common.Types.Address,
  Vm.Contracts.Dex.DexFundStorage, Vm.Contracts.Dex.Proto.DexProto;

function DoFinishVxUnlock(Db: IVmDb; PeriodId: UInt64): Exception;
function DoFinishCancelMiningStake(Db: IVmDb; PeriodId: UInt64): Exception;

implementation

function DoFinishVxUnlock(Db: IVmDb; PeriodId: UInt64): Exception;
var
  Iterator: IStorageIterator;
  VxUnlocksKey, VxUnlocksValue: TBytes;
  Address: TAddress;
  Unlocks: TVxUnlocks;
  I: Integer;
  Amount: TBigInteger;
  Ul: TDexProtoVxUnlock;
begin
  if not IsEarthFork(Db) then
  begin
    Result := nil;
    Exit;
  end;

  Iterator := Db.NewStorageIterator(VxUnlocksKeyPrefix);
  try
    while Iterator.Next do
    begin
      VxUnlocksKey := Iterator.Key;
      VxUnlocksValue := Iterator.Value;
      if Length(VxUnlocksValue) = 0 then
        Continue;

      if Length(VxUnlocksKey) <> Length(VxUnlocksKeyPrefix) + AddressSize then
        raise Exception.Create('invalid vx unlocks key');

      Address := BytesToAddress(Copy(VxUnlocksKey, Length(VxUnlocksKeyPrefix), AddressSize));
      Unlocks := TVxUnlocks.Create;
      Unlocks.Deserialize(VxUnlocksValue);

      I := 0;
      Amount := TBigInteger.Create(0);
      for Ul in Unlocks.Unlocks do
      begin
        if Ul.PeriodId + SchedulePeriods <= PeriodId then
        begin
          Amount := TBigInteger.Add(Amount, TBigInteger.FromByteArray(Ul.Amount));
          Inc(I);
        end
        else
          Break;
      end;

      if I > 0 then
      begin
        Unlocks.Unlocks := Copy(Unlocks.Unlocks, I, Length(Unlocks.Unlocks) - I);
        UpdateVxUnlocks(Db, Address, Unlocks);
        if FinishVxUnlockForDividend(Db, Address, Amount) <> nil then
          Exit(FinishVxUnlockForDividend(Db, Address, Amount));
      end;
    end;
  finally
    Iterator.Release;
  end;
  Result := nil;
end;

function DoFinishCancelMiningStake(Db: IVmDb; PeriodId: UInt64): Exception;
var
  Iterator: IStorageIterator;
  CancelStakesKey, CancelStakesValue: TBytes;
  Address: TAddress;
  CancelStakes: TCancelStakes;
  I: Integer;
  Amount: TBigInteger;
  Cl: TDexProtoCancelStake;
begin
  if not IsEarthFork(Db) then
  begin
    Result := nil;
    Exit;
  end;

  Iterator := Db.NewStorageIterator(CancelStakesKeyPrefix);
  try
    while Iterator.Next do
    begin
      CancelStakesKey := Iterator.Key;
      CancelStakesValue := Iterator.Value;
      if Length(CancelStakesValue) = 0 then
        Continue;

      if Length(CancelStakesKey) <> Length(CancelStakesKeyPrefix) + AddressSize then
        raise Exception.Create('invalid cancel stakes key');

      Address := BytesToAddress(Copy(CancelStakesKey, Length(CancelStakesKeyPrefix), AddressSize));
      CancelStakes := TCancelStakes.Create;
      CancelStakes.Deserialize(CancelStakesValue);

      I := 0;
      Amount := TBigInteger.Create(0);
      for Cl in CancelStakes.Cancels do
      begin
        if Cl.PeriodId + SchedulePeriods <= PeriodId then
        begin
          Amount := TBigInteger.Add(Amount, TBigInteger.FromByteArray(Cl.Amount));
          Inc(I);
        end
        else
          Break;
      end;

      if I > 0 then
      begin
        CancelStakes.Cancels := Copy(CancelStakes.Cancels, I, Length(CancelStakes.Cancels) - I);
        UpdateCancelStakes(Db, Address, CancelStakes);
        if FinishCancelStake(Db, Address, Amount) <> nil then
          Exit(FinishCancelStake(Db, Address, Amount));
      end;
    end;
  finally
    Iterator.Release;
  end;
  Result := nil;
end;

end.
