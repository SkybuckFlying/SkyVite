unit Ledger.Chain.Cache.Init;

interface

uses
  System.SysUtils, System.Classes, Ledger.Chain.Cache.Cache;

type
  TCache = partial class
  private
    function InternalInitLatestSnapshotBlock: Boolean;
  public
    function Init: Boolean;
  end;

implementation

uses
  Interfaces.Core;

{ TCache }

function TCache.Init: Boolean;
begin
  if not InternalInitLatestSnapshotBlock then
  begin
    Result := False;
    Exit;
  end;

  if not mQuotaList.Init then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
end;

function TCache.InternalInitLatestSnapshotBlock: Boolean;
var
  vLatestSnapshotBlock: TSnapshotBlock;
  vError: Exception;
begin
  try
    vLatestSnapshotBlock := mChain.QueryLatestSnapshotBlock;
    mHd.SetLatestSnapshotBlock(vLatestSnapshotBlock);
    Result := True;
  except
    on E: Exception do
    begin
      // Log the error if a logging mechanism is available
      vError := E;
      Result := False;
    end;
  end;
end;

end.
