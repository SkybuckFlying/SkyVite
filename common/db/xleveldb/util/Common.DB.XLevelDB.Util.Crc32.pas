unit Common.Db.Xleveldb.Util.Crc32;

interface

uses
<<<<<<< HEAD
  System.SysUtils,
  GoToDelphi.Helpers.CRC32;

type
  CRC = type Cardinal;

  CRCHelper = record helper for CRC
  public
    function Update(const ParaBuffer: TBytes): CRC; overload;
    function Update(const ParaBuffer: Pointer; ParaLength: Integer): CRC; overload;
    function Value: Cardinal;
  end;

function NewCRC(const ParaBuffer: TBytes): CRC; overload;
function NewCRC(const ParaBuffer: Pointer; ParaLength: Integer): CRC; overload;

implementation

function NewCRC(const ParaBuffer: TBytes): CRC;
var
  vInitial: CRC;
begin
  vInitial := 0;
  Result := vInitial.Update(ParaBuffer);
end;

function NewCRC(const ParaBuffer: Pointer; ParaLength: Integer): CRC;
var
  vInitial: CRC;
begin
  vInitial := 0;
  Result := vInitial.Update(ParaBuffer, ParaLength);
end;

{ CRCHelper }

function CRCHelper.Update(const ParaBuffer: TBytes): CRC;
begin
  Result := CRC(TCRC32C.Update(Cardinal(Self), ParaBuffer));
end;

function CRCHelper.Update(const ParaBuffer: Pointer; ParaLength: Integer): CRC;
begin
  Result := CRC(TCRC32C.Update(Cardinal(Self), ParaBuffer, ParaLength));
end;

function CRCHelper.Value: Cardinal;
begin
  Result := (Cardinal(Self) shr 15) or (Cardinal(Self) shl 17) + $a282ead8;
=======
  System.SysUtils;

type
  TCRC = class
  private
    mValue: Cardinal;
    class var mTable: array[0..255] of Cardinal;
    class constructor Create;
  public
    constructor Create(const ParaBytes: TBytes);
    function Update(const ParaBytes: TBytes): TCRC;
    function Value: Cardinal;
    class function NewCRC(const ParaBytes: TBytes): TCRC;
  end;

implementation

{ TCRC }

class constructor TCRC.Create;
const
  ConstCastagnoli = $82F63B78;
var
  vIndex: integer;
  vEntry: Cardinal;
  vIndex2: integer;
begin
  for vIndex := 0 to 255 do
  begin
    vEntry := vIndex;
    for vIndex2 := 0 to 7 do
    begin
      if (vEntry and 1) = 1 then
      begin
        vEntry := (vEntry shr 1) xor ConstCastagnoli;
      end
      else
      begin
        vEntry := vEntry shr 1;
      end;
    end;
    mTable[vIndex] := vEntry;
  end;
end;

constructor TCRC.Create(const ParaBytes: TBytes);
begin
  inherited Create;
  mValue := 0;
  Update(ParaBytes);
end;

class function TCRC.NewCRC(const ParaBytes: TBytes): TCRC;
begin
  Result := TCRC.Create(ParaBytes);
end;

function TCRC.Update(const ParaBytes: TBytes): TCRC;
var
  vByte: byte;
begin
  for vByte in ParaBytes do
  begin
    mValue := mTable[(mValue xor vByte) and $FF] xor (mValue shr 8);
  end;
  Result := Self;
end;

function TCRC.Value: Cardinal;
begin
  Result := (mValue shr 15) or (mValue shl 17) + $a282ead8;
>>>>>>> origin/AI0010
end;

end.
