unit Vendor.Golang.Org.X.Sys.Unix.IfreqLinux;

interface

uses
  System.SysUtils;

const
  IFNAMSIZ = 16;

type
  TIfreq = record
    Ifrn: array[0..IFNAMSIZ-1] of Byte;
    // ...
  end;
  PIfreq = ^TIfreq;

function NewIfreq(const Name: string): TTuple<PIfreq, Exception>;

implementation

function NewIfreq(const Name: string): TTuple<PIfreq, Exception>;
begin
  Result := Default(TTuple<PIfreq, Exception>);
end;

end.
