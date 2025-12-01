unit Interfaces.Core.HashHeight;

interface

uses
  System.SysUtils,
  Common.Types,
  Common.VitePb;

type
  THashHeight = record
    Height: UInt64;
    Hash: THash;
    function Equal(const ParaHash: THash; ParaHeight: UInt64): Boolean;
    function ToProto: THashHeightPb;
    function DeProto(const ParaPb: THashHeightPb): Exception;
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaData: TBytes): Exception;
  end;

  THeightRange = record
    Start: THashHeight;
    EndRange: THashHeight;
    class function New(ParaHeight: UInt64; const ParaHash: THash): THeightRange;
    procedure Update(ParaHeight: UInt64; const ParaHash: THash);
  end;

implementation

{ THashHeight }

function THashHeight.Equal(const ParaHash: THash; ParaHeight: UInt64): Boolean;
begin
  Result := (Self.Hash.Equal(ParaHash)) and (Self.Height = ParaHeight);
end;

function THashHeight.ToProto: THashHeightPb;
begin
  Result := THashHeightPb.Create;
  Result.Hash := Self.Hash.Bytes;
  Result.Height := Self.Height;
end;

function THashHeight.DeProto(const ParaPb: THashHeightPb): Exception;
var
  vError: Exception;
begin
  Result := nil;
  Self.Hash := THash.FromBytes(ParaPb.Hash, vError);
  if vError <> nil then
    Exit(vError);
  Self.Height := ParaPb.Height;
end;

function THashHeight.Serialize(out ParaError: Exception): TBytes;
var
  vPb: THashHeightPb;
begin
  vPb := Self.ToProto;
  Result := vPb.ToBytes(ParaError);
end;

function THashHeight.Deserialize(const ParaData: TBytes): Exception;
var
  vPb: THashHeightPb;
begin
  Result := nil;
  vPb := THashHeightPb.Create;
  Result := vPb.FromBytes(ParaData);
  if Result = nil then
    Result := Self.DeProto(vPb);
end;

{ THeightRange }

class function THeightRange.New(ParaHeight: UInt64; const ParaHash: THash): THeightRange;
begin
  Result.Start.Hash := ParaHash;
  Result.Start.Height := ParaHeight;
  Result.EndRange.Hash := ParaHash;
  Result.EndRange.Height := ParaHeight;
end;

procedure THeightRange.Update(ParaHeight: UInt64; const ParaHash: THash);
begin
  if ParaHeight > Self.EndRange.Height then
  begin
    Self.EndRange.Hash := ParaHash;
    Self.EndRange.Height := ParaHeight;
  end;
  if ParaHeight < Self.Start.Height then
  begin
    Self.Start.Hash := ParaHash;
    Self.Start.Height := ParaHeight;
  end;
end;

end.
