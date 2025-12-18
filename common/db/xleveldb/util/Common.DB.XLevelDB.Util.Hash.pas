unit Common.Db.Xleveldb.Util.Hash;

interface

uses
  Common.DB.XLevelDB.Util.Buffer,
  Common.DB.XLevelDB.Util.Buffer.Pool,
  Common.DB.XLevelDB.Util.Crc32,
  Common.DB.XLevelDB.Util.Range,
  Common.DB.XLevelDB.Util.Util,
  System.SysUtils;

function Hash(const ParaData: TBytes; ParaSeed: Cardinal): Cardinal;

implementation

function Hash(const ParaData: TBytes; ParaSeed: Cardinal): Cardinal;
const
  ConstM = $c6a4a793;
  ConstR = 24;
var
  vH: Cardinal;
  vIndex: Integer;
  vN: Integer;
  vDataPtr: PByte;
begin
  vH := ParaSeed xor (Length(ParaData) * ConstM);
  vN := Length(ParaData) - (Length(ParaData) mod 4);
  vIndex := 0;
  vDataPtr := PByte(ParaData);

  while vIndex < vN do
  begin
    vH := vH + PUInt32(vDataPtr + vIndex)^;
    vH := vH * ConstM;
    vH := vH xor (vH shr 16);
    Inc(vIndex, 4);
  end;

  case Length(ParaData) - vIndex of
    3:
      begin
        vH := vH + (Cardinal(ParaData[vIndex + 2]) shl 16);
        vH := vH + (Cardinal(ParaData[vIndex + 1]) shl 8);
        vH := vH + Cardinal(ParaData[vIndex]);
        vH := vH * ConstM;
        vH := vH xor (vH shr ConstR);
      end;
    2:
      begin
        vH := vH + (Cardinal(ParaData[vIndex + 1]) shl 8);
        vH := vH + Cardinal(ParaData[vIndex]);
        vH := vH * ConstM;
        vH := vH xor (vH shr ConstR);
      end;
    1:
      begin
        vH := vH + Cardinal(ParaData[vIndex]);
        vH := vH * ConstM;
        vH := vH xor (vH shr ConstR);
      end;
  end;
  Result := vH;
end;

end.
