unit Common.Types.Gid;

interface

uses
  Common.Bytes,
  Common.HexUtil,
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  Crypto.Hash,
  System.Math.BigInts,
  System.SysUtils;

const
  ConstGidSize = 10;
  ConstHexGidIdLength = 2 * ConstGidSize;

type
  TGid = array[0..ConstGidSize - 1] of Byte;

  TGidHelper = record helper for TGid
    procedure SetBytes(const ParaB: TBytes);
    function ToBytes: TBytes;
    function ToHex: string;
    function ToString: string;
    procedure UnmarshalJSON(const ParaInput: TBytes);
    function MarshalText: TBytes;
  end;

var
  PRIVATE_GID, SNAPSHOT_GID, DELEGATE_GID: TGid;

function DataToGid(const ParaData: array of TBytes): TGid;
function HexToGid(const ParaHexStr: string): TGid;
function BigToGid(const ParaData: TBigInteger): TGid;
function BytesToGid(const ParaB: TBytes): TGid;

implementation

uses
  System.StrUtils,
  Common.Helper,
  Common.Types.Error,
  Common.Math.Big;

function trimLeftRightQuotation(const ParaS: TBytes): TBytes;
var
  vStr: string;
begin
  vStr := TEncoding.UTF8.GetString(ParaS);
  vStr := vStr.Trim(['"']);
  Result := TEncoding.UTF8.GetBytes(vStr);
end;

{ TGidHelper }

procedure TGidHelper.SetBytes(const ParaB: TBytes);
begin
  if Length(ParaB) <> ConstGidSize then
  begin
    raise Exception.CreateFmt('error gid size %d', [Length(ParaB)]);
  end;
  Move(ParaB[0], Self[0], ConstGidSize);
end;

function TGidHelper.ToBytes: TBytes;
begin
  SetLength(Result, ConstGidSize);
  Move(Self[0], Result[0], ConstGidSize);
end;

function TGidHelper.ToHex: string;
begin
  Result := THexUtil.Encode(Self);
end;

function TGidHelper.ToString: string;
begin
  Result := Self.ToHex;
end;

procedure TGidHelper.UnmarshalJSON(const ParaInput: TBytes);
var
  vGid: TGid;
  vTrimmed: TBytes;
  vHex: string;
begin
  if not isString(ParaInput) then
  begin
    raise EJsonError.Create(ConstErrJsonNotString);
  end;
  try
    vTrimmed := trimLeftRightQuotation(ParaInput);
    vHex := TEncoding.UTF8.GetString(vTrimmed);
    vGid := HexToGid(vHex);
    Self.SetBytes(vGid.ToBytes);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to unmarshal GID from JSON: ' + E.Message);
    end;
  end;
end;

function TGidHelper.MarshalText: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Self.ToString);
end;

{ Standalone Functions }

function DataToGid(const ParaData: array of TBytes): TGid;
var
  vHashed: TBytes;
begin
  vHashed := THash.Hash(ConstGidSize, ParaData);
  Result := BytesToGid(vHashed);
end;

function HexToGid(const ParaHexStr: string): TGid;
var
  vGidBytes: TBytes;
begin
  if Length(ParaHexStr) <> ConstHexGidIdLength then
  begin
    raise Exception.Create('Not valid hex gid');
  end;
  try
    vGidBytes := THexUtil.Decode(ParaHexStr);
    Result := BytesToGid(vGidBytes);
  except
    on E: Exception do
    begin
      raise Exception.Create('Not valid hex gid: ' + E.Message);
    end;
  end;
end;

function BigToGid(const ParaData: TBigInteger): TGid;
var
  vSlice, vPadded: TBytes;
begin
  vSlice := ParaData.ToByteArray;
  if Length(vSlice) < ConstGidSize then
  begin
    vPadded := TBigMath.PaddedBigBytes(ParaData, ConstGidSize);
    Result := BytesToGid(vPadded);
  end
  else
  begin
    Result := BytesToGid(vSlice);
  end;
end;

function BytesToGid(const ParaB: TBytes): TGid;
begin
  if Length(ParaB) <> ConstGidSize then
  begin
    raise Exception.CreateFmt('error gid size %d', [Length(ParaB)]);
  end;
  Move(ParaB[0], Result[0], ConstGidSize);
end;

initialization
  PRIVATE_GID := BytesToGid([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  SNAPSHOT_GID := BytesToGid([0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
  DELEGATE_GID := BytesToGid([0, 0, 0, 0, 0, 0, 0, 0, 0, 2]);
end.
