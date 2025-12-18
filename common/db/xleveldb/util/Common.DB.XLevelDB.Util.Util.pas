unit common.db.xleveldb.util;

interface

uses
  Common.DB.XLevelDB.Util.Buffer,
  Common.DB.XLevelDB.Util.Buffer.Pool,
  Common.DB.XLevelDB.Util.Crc32,
  Common.DB.XLevelDB.Util.Hash,
  Common.DB.XLevelDB.Util.Range,
  System.SysUtils;

type
  ELevelDBUtil = class(Exception);
  EReleased = class(ELevelDBUtil);
  EHasReleaser = class(ELevelDBUtil);

  IReleaser = interface
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    procedure Release;
  end;

  IReleaseSetter = interface
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    procedure SetReleaser(AReleaser: IReleaser);
  end;

  TBasicReleaser = class(TInterfacedObject, IReleaser, IReleaseSetter)
  private
    FReleaser: IReleaser;
    FReleased: Boolean;
  public
    function Released: Boolean;
    procedure Release;
    procedure SetReleaser(AReleaser: IReleaser);
  end;

  TNoopReleaser = class(TInterfacedObject, IReleaser)
  public
    procedure Release;
  end;

implementation

{ TBasicReleaser }

function TBasicReleaser.Released: Boolean;
begin
  Result := FReleased;
end;

procedure TBasicReleaser.Release;
begin
  if not FReleased then
  begin
    if FReleaser <> nil then
    begin
      FReleaser.Release;
      FReleaser := nil;
    end;
    FReleased := True;
  end;
end;

procedure TBasicReleaser.SetReleaser(AReleaser: IReleaser);
begin
  if FReleased then
    raise EReleased.Create('leveldb: resource already released');
  if (FReleaser <> nil) and (AReleaser <> nil) then
    raise EHasReleaser.Create('leveldb: releaser already defined');
  FReleaser := AReleaser;
end;

{ TNoopReleaser }

procedure TNoopReleaser.Release;
begin
  // No-op
end;

initialization
  EReleased.Create('leveldb: resource already released');
  EHasReleaser.Create('leveldb: releaser already defined');

end.
