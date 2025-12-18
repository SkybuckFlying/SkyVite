unit Ledger.Onroad.Pool.Error.Table;

interface

uses
  Ledger.Onroad.Pool.Caller.Cache.Test,
  Ledger.Onroad.Pool.Contract.Pool,
  Ledger.Onroad.Pool.Pool,
  Ledger.Onroad.Pool.Storage,
  Ledger.Onroad.Pool.Storage.Test,
  Ledger.Onroad.Pool.Types,
  Ledger.Onroad.Pool.Types.Test,
  System.SysUtils;

const
  ConstOnRoadPoolNotAvailable = 'target gid''s onRoadPool is not available';
  ConstCheckIsCallerFrontOnRoadFailed = 'onRoadPool check the Caller''s front onroad hash failed';
  ConstLoadCallerCacheFailed = 'load callerCache failed';
  ConstFindCompleteBlock = 'failed to find complete block by hash';

type
  EOnRoadPoolNotAvailable = class(Exception);
  ECheckIsCallerFrontOnRoadFailed = class(Exception);
  ELoadCallerCacheFailed = class(Exception);
  EFindCompleteBlock = class(Exception);

implementation

initialization
  Exception.CreateFmt(ConstOnRoadPoolNotAvailable);
  Exception.CreateFmt(ConstCheckIsCallerFrontOnRoadFailed);
  Exception.CreateFmt(ConstLoadCallerCacheFailed);
  Exception.CreateFmt(ConstFindCompleteBlock);

end.
