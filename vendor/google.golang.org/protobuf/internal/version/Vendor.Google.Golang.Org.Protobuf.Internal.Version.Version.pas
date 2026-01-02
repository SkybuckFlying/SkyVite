unit Vendor.Google.Golang.Org.Protobuf.Internal.Version.Version;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils;

const
  ConstMajor = 1;
  ConstMinor = 27;
  ConstPatch = 1;
  ConstPreRelease = '';

// String formats the version string for this module in semver format.
function String_: string;

implementation

function String_: string;
var
  vMetadata: string;
begin
  Result := Format('v%d.%d.%d', [ConstMajor, ConstMinor, ConstPatch]);
  if ConstPreRelease <> '' then
  begin
    Result := Result + '-' + ConstPreRelease;

    // TODO: Add metadata about the commit or build hash.
    // See https://golang.org/issue/29814
    // See https://golang.org/issue/33533
    vMetadata := '';
    if (Pos('devel', ConstPreRelease) > 0) and (vMetadata <> '') then
    begin
      Result := Result + '+' + vMetadata;
    end;
  end;
end;

end.
