unit unit_producer;

interface

uses
  SysUtils, StrUtils, Types;

type
  TProducer = class
  private
    FProducer: Boolean;
    FCoinbase: String;
    FEntropyStorePath: String;
    FVirtualSnapshotVerifier: Boolean;
    FcoinbaseAddress: TAddress;
    Findex: Cardinal;
  public
    function IsMine: Boolean;
    function GetCoinbase: TAddress;
    function GetIndex: Cardinal;
    function Parse: Exception;
  end;

function ParseCoinbase(coinbaseCfg: String): TAddress;

implementation

function TProducer.IsMine: Boolean;
begin
  Result := FProducer and (FCoinbase <> '');
end;

function TProducer.GetCoinbase: TAddress;
begin
  Result := FcoinbaseAddress;
end;

function TProducer.GetIndex: Cardinal;
begin
  Result := Findex;
end;

function TProducer.Parse: Exception;
var
  coinbase: TAddress;
  index: Cardinal;
  err: Exception;
begin
  if FCoinbase <> '' then
  begin
    err := ParseCoinbase(FCoinbase, coinbase, index);
    if err <> nil then
      Exit(err);
    FcoinbaseAddress := coinbase;
    Findex := index;
  end;
  Result := nil;
end;

function ParseCoinbase(coinbaseCfg: String; out coinbase: TAddress; out index: Cardinal): Exception;
var
  splits: TStringDynArray;
  i: Integer;
  addr: TAddress;
begin
  splits := SplitString(coinbaseCfg, ':');
  if Length(splits) <> 2 then
    Exit(Exception.Create('len is not equals 2'));
  i := StrToIntDef(splits[0], -1);
  if i = -1 then
    Exit(Exception.Create('Invalid integer value'));
  addr := HexToAddress(splits[1]);
  coinbase := addr;
  index := Cardinal(i);
  Result := nil;
end;

end.



