unit Vendor.Golang.Org.X.Sys.Unix.CapFreebsd;

interface

uses
  System.SysUtils;

type
  TCapRights = record
    Rights: array[0..1] of UInt64;
  end;
  PCapRights = ^TCapRights;

function CapRightsSet(Rights: PCapRights; const SetRights: array of UInt64): Exception;
function CapRightsClear(Rights: PCapRights; const ClearRights: array of UInt64): Exception;
function CapRightsIsSet(Rights: PCapRights; const SetRights: array of UInt64): TTuple<Boolean, Exception>;

implementation

function CapRightsSet(Rights: PCapRights; const SetRights: array of UInt64): Exception;
begin
  Result := nil;
end;

function CapRightsClear(Rights: PCapRights; const ClearRights: array of UInt64): Exception;
begin
  Result := nil;
end;

function CapRightsIsSet(Rights: PCapRights; const SetRights: array of UInt64): TTuple<Boolean, Exception>;
begin
  Result := Default(TTuple<Boolean, Exception>);
end;

end.
