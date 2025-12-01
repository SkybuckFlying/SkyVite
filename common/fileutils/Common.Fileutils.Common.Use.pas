unit Common.Fileutils.CommonUse;

interface

uses
  System.SysUtils, System.IOUtils;

type
  TFileUtils = class
  public
    class function OpenOrCreateFd(const ParaDirName: string): TFileStream;
    class function FileSize(const ParaFileStream: TFileStream): Int64;
    class function CreateTempDir: string;
  end;

implementation

{ TFileUtils }

class function TFileUtils.OpenOrCreateFd(const ParaDirName: string): TFileStream;
var
  vDirFd: TFileStream;
begin
  vDirFd := nil;
  while vDirFd = nil do
  begin
    try
      vDirFd := TFileStream.Create(ParaDirName, fmOpenRead);
    except
      on E: EFOpenError do
      begin
        if E.ErrorCode = ERROR_PATH_NOT_FOUND then
        begin
          try
            TDirectory.CreateDirectory(ParaDirName);
          except
            on E2: Exception do
            begin
              raise Exception.CreateFmt('Create %s failed, error is %s', [ParaDirName, E2.Message]);
            end;
          end;
        end
        else
        begin
          raise Exception.CreateFmt('os.Open %s failed, error is %s', [ParaDirName, E.Message]);
        end;
      end;
    end;
  end;
  Result := vDirFd;
end;

class function TFileUtils.FileSize(const ParaFileStream: TFileStream): Int64;
begin
  Result := ParaFileStream.Size;
end;

class function TFileUtils.CreateTempDir: string;
begin
  Result := TPath.GetTempPath;
end;

end.
