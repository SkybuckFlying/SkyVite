unit RpcApi.Api.Debug;

interface

uses
  System.SysUtils;

type
  TDeprecated = class
  public
    function ToString: string; override;
    function Hello: string;
  end;

implementation

{ TDeprecated }

function TDeprecated.ToString: string;
begin
  Result := 'DeprecatedApi';
end;

function TDeprecated.Hello: string;
begin
  Result := 'hello world';
end;

end.
