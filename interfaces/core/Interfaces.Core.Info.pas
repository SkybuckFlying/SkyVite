unit Interfaces.Core.Info;

interface

uses
  System.SysUtils, System.Generics.Collections, Math.BigInt,
  GoToDelphi.Helpers.BigInt,
  Common.Types;

type
  TTokenBalanceInfo = record
    TotalAmount: TBigInt;
    Number: UInt64;
  end;

  TAccountInfo = record
    AccountAddress: TAddress;
    TotalNumber: UInt64;
    TokenBalanceInfoMap: TDictionary<TTokenTypeId, TTokenBalanceInfo>;
  end;

implementation

end.
