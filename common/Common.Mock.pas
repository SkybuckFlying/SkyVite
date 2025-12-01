unit Common.Mock;

interface

uses
  System.SysUtils,
  Common.Types,
  Common.Types.Address,
  Common.Types.Hash;

function MockAddress(const ParaIndex: Integer): TAddress;
function MockHash(const ParaIndex: Integer): THash;
function MockHashBy(const ParaIndex1: Integer; const ParaIndex2: Integer): THash;

implementation

uses
  System.Net.Encodings;

function MockAddress(const ParaIndex: Integer): TAddress;
var
  vBase: string;
  vBytes: TBytes;
begin
  vBase := '0000000000000000000fff' + Format('%.6d', [ParaIndex]) + 'fff00000000000';
  try
    vBytes := TNetEncoding.Base16.Decode(vBase);
    Result := BytesToAddress(vBytes);
  except
    on E: Exception do
    begin
      // The original Go code panics on error. Re-raising is the equivalent.
      raise Exception.Create('Failed to create mock address: ' + E.Message);
    end;
  end;
end;

function MockHash(const ParaIndex: Integer): THash;
var
  vBase: string;
  vBytes: TBytes;
begin
  vBase := '0000000000000000000000000000fff' + Format('%.6d', [ParaIndex]) + 'fff000000000000000000000000';
  try
    vBytes := TNetEncoding.Base16.Decode(vBase);
    Result := BytesToHash(vBytes);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to create mock hash: ' + E.Message);
    end;
  end;
end;

function MockHashBy(const ParaIndex1: Integer; const ParaIndex2: Integer): THash;
var
  vBase: string;
  vBytes: TBytes;
begin
  vBase := Format('%.6d', [ParaIndex1]) + '0000000000000000000000fff' + Format('%.6d', [ParaIndex2]) + 'fff000000000000000000000000';
  try
    vBytes := TNetEncoding.Base16.Decode(vBase);
    Result := BytesToHash(vBytes);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to create mock hash by: ' + E.Message);
    end;
  end;
end;

end.
