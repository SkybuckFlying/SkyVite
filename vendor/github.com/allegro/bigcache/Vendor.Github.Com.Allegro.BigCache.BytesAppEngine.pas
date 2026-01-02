unit Vendor.Github.Com.Allegro.BigCache.BytesAppEngine;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils;

function BytesToString(const ParaBytes: TBytes): string;

implementation

function BytesToString(const ParaBytes: TBytes): string;
begin
  if Length(ParaBytes) = 0 then
    Result := ''
  else
    Result := TEncoding.UTF8.GetString(ParaBytes);
end;

end.
