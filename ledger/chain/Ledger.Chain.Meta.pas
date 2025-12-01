unit Ledger.Chain.Meta;

interface

uses
  System.SysUtils,
  System.Classes,
  V2.Common.Types,
  V2.Common.DB.XLevelDB,
  V2.Ledger.Chain.Chain;

const
  ConstGenesisKey = $00;

type
  TChainHelper = class helper for TChain
  public
    function WriteGenesisCheckSum(const ParaHash: THash): string;
    function QueryGenesisCheckSum(out ParaHash: THash): string;
  end;

implementation

{ TChainHelper }

function TChainHelper.WriteGenesisCheckSum(const ParaHash: THash): string;
var
  vKey: TBytes;
begin
  Result := '';
  SetLength(vKey, 1);
  vKey[0] := ConstGenesisKey;
  try
    Self.FMetaDB.Put(vKey, ParaHash.Bytes, nil);
  except
    on E: Exception do
    begin
      Result := Format('Failed to write genesis checksum: %s', [E.Message]);
    end;
  end;
end;

function TChainHelper.QueryGenesisCheckSum(out ParaHash: THash): string;
var
  vKey, vValue: TBytes;
begin
  Result := '';
  SetLength(vKey, 1);
  vKey[0] := ConstGenesisKey;
  try
    vValue := Self.FMetaDB.Get(vKey, nil);
  except
    on E: ELevelDB do
    begin
      if E.Message = 'not found' then
      begin
        ParaHash := nil;
        Exit;
      end;
      Result := E.Message;
      Exit;
    end;
  end;

  if Length(vValue) <= 0 then
  begin
    ParaHash := nil;
    Exit;
  end;

  try
    ParaHash := BytesToHash(vValue);
  except
    on E: Exception do
    begin
      Result := Format('Failed to convert bytes to hash: %s', [E.Message]);
    end;
  end;
end;

end.