unit Common.Types.JsonUtils;

interface

uses
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
