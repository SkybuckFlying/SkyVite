unit Common.DB.XLevelDB.Errors.Errors;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Common.DB.XLevelDB.Storage;

type
  ECorrupted = class(Exception)
  protected
    mFD: TFileDesc;
    mInnerError: Exception;
  public
    constructor Create(const AFD: TFileDesc; AErr: Exception);
    constructor Create(const AFD: TFileDesc; const AMessage: string);
    property FD: TFileDesc read mFD;
    property InnerError: Exception read mInnerError;
  end;

  EMissingFiles = class(Exception)
  private
    mFDs: TArray<TFileDesc>;
  public
    constructor Create(const AFDs: TArray<TFileDesc>);
    property FDs: TArray<TFileDesc> read mFDs;
  end;

  EReleased = class(Exception);
  EHasReleaser = class(Exception);

var
  ErrNotFound: Exception;
  ErrReleased: Exception;
  ErrHasReleaser: Exception;

function NewErrCorrupted(const AFD: TFileDesc; AErr: Exception): ECorrupted;
function IsCorrupted(AErr: Exception): Boolean;
function SetFd(AErr: Exception; const AFD: TFileDesc): Exception;

implementation

{ ECorrupted }

constructor ECorrupted.Create(const AFD: TFileDesc; AErr: Exception);
var
  vMsg: string;
begin
  if not AFD.IsZero then
    vMsg := Format('%s [file=%s]', [AErr.Message, AFD.ToString])
  else
    vMsg := AErr.Message;
  inherited Create(vMsg);
  mFD := AFD;
  mInnerError := AErr;
end;

constructor ECorrupted.Create(const AFD: TFileDesc; const AMessage: string);
var
  vMsg: string;
begin
  if not AFD.IsZero then
    vMsg := Format('%s [file=%s]', [AMessage, AFD.ToString])
  else
    vMsg := AMessage;
  inherited Create(vMsg);
  mFD := AFD;
  mInnerError := nil;
end;


{ EMissingFiles }

constructor EMissingFiles.Create(const AFDs: TArray<TFileDesc>);
begin
  inherited Create('file missing');
  mFDs := AFDs;
end;

{ Helper Functions }

function NewErrCorrupted(const AFD: TFileDesc; AErr: Exception): ECorrupted;
begin
  Result := ECorrupted.Create(AFD, AErr);
end;

function IsCorrupted(AErr: Exception): Boolean;
begin
  Result := (AErr is ECorrupted) or (AErr is EStorageCorrupted);
end;

function SetFd(AErr: Exception; const AFD: TFileDesc): Exception;
begin
  if AErr is ECorrupted then
  begin
    ECorrupted(AErr).mFD := AFD;
    Result := AErr;
  end
  else
    Result := AErr;
end;

initialization
  ErrNotFound := Exception.Create('leveldb: not found');
  ErrReleased := EReleased.Create('leveldb: released');
  ErrHasReleaser := EHasReleaser.Create('leveldb: has releaser');
end.
