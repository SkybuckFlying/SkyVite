unit Common.Types.JsonUtils;

interface

uses
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  System.SysUtils;

function IsString(const ParaInput: TBytes): Boolean;
function TrimLeftRightQuotation(const ParaInput: TBytes): TBytes;

implementation

function IsString(const ParaInput: TBytes): Boolean;
begin
  if (Length(ParaInput) >= 2) and (ParaInput[0] = Ord('"')) and (ParaInput[High(ParaInput)] = Ord('"')) then
  begin
    Result := True;
  end
  else
  begin
    Result := False;
  end;
end;

function TrimLeftRightQuotation(const ParaInput: TBytes): TBytes;
begin
  if IsString(ParaInput) then
  begin
    Result := Copy(ParaInput, 1, Length(ParaInput) - 2);
  end
  else
  begin
    SetLength(Result, 0);
  end;
end;

end.
