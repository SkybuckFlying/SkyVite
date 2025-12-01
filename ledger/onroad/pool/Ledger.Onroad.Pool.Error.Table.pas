unit Ledger.Onroad.Pool.Error.Table;

interface

uses
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