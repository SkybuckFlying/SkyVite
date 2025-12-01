unit Common.Db.XLevelDB.Errors;

interface

uses
  System.SysUtils,
  Common.Db.XLevelDB.Storage;

const
  ErrNotFound = 'leveldb: not found';
  ErrReadOnly = 'leveldb: read-only mode';
  ErrSnapshotReleased = 'leveldb: snapshot released';
  ErrIterReleased = 'leveldb: iterator released';
  ErrClosed = 'leveldb: closed';
  ErrReleased = 'releaser: released';
  ErrHasReleaser = 'releaser: has releaser';

type
  EXLevelDBCorrupted = class(Exception)
  private
    mFd: TFileDesc;
    mOriginalError: string;
  public
    constructor Create(const ParaFd: TFileDesc; const ParaErr: string);
    property Fd: TFileDesc read mFd;
    property OriginalError: string read mOriginalError;
  end;

function IsCorrupted(const ParaErr: Exception): boolean;
function NewErrCorrupted(const ParaFd: TFileDesc; const ParaErr: string): Exception;
function SetFd(const ParaErr: Exception; const ParaFd: TFileDesc): Exception;

implementation

{ EXLevelDBCorrupted }

constructor EXLevelDBCorrupted.Create(const ParaFd: TFileDesc; const ParaErr: string);
begin
  mFd := ParaFd;
  mOriginalError := ParaErr;
  if not mFd.IsZero then
  begin
    inherited Create(Format('%s [file=%s]', [ParaErr, mFd.ToString]))
  end
  else
  begin
    inherited Create(ParaErr);
  end;
end;

function IsCorrupted(const ParaErr: Exception): boolean;
begin
  Result := (ParaErr is EXLevelDBCorrupted) or (ParaErr is EStorageCorrupted);
end;

function NewErrCorrupted(const ParaFd: TFileDesc; const ParaErr: string): Exception;
begin
  Result := EXLevelDBCorrupted.Create(ParaFd, ParaErr);
end;

function SetFd(const ParaErr: Exception; const ParaFd: TFileDesc): Exception;
begin
  if ParaErr is EXLevelDBCorrupted then
  begin
    (ParaErr as EXLevelDBCorrupted).mFd := ParaFd;
    Result := ParaErr;
  end
  else
  begin
    Result := ParaErr;
  end;
end;

end.
