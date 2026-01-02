unit Vendor.Go.Uber.Org.Atomic.StringExt;

interface

uses
  System.SysUtils, System.Classes,
  Vendor.Go.Uber.Org.Atomic.String;

type
  TStringHelper = class helper for TString
  public
    function MarshalText: TBytes;
    procedure UnmarshalText(const Text: TBytes);
  end;

implementation

{ TStringHelper }

function TStringHelper.MarshalText: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Load);
end;

procedure TStringHelper.UnmarshalText(const Text: TBytes);
begin
  Store(TEncoding.UTF8.GetString(Text));
end;

end.
