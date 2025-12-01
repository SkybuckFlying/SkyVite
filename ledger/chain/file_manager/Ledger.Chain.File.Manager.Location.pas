unit Ledger.Chain.FileManager.Location;

interface

uses
  System.SysUtils,
  Ledger.Chain.FileManager.Interfaces;

const
  LocationSize = 12;

type
  TLocation = class(TInterfacedObject, ILocation)
  private
    mFileId: UInt64;
    mOffset: Int64;
  public
    constructor Create(ParaFileId: UInt64; ParaOffset: Int64);
    function FileId: UInt64;
    function Offset: Int64;
    function Compare(ParaOther: ILocation): Integer;
    function Distance(ParaFileSize: Int64; ParaBackLocation: ILocation): Int64;
    function ToString: string;
  end;

implementation

{ TLocation }

constructor TLocation.Create(ParaFileId: UInt64; ParaOffset: Int64);
begin
  inherited Create;
  mFileId := ParaFileId;
  mOffset := ParaOffset;
end;

function TLocation.FileId: UInt64;
begin
  Result := mFileId;
end;

function TLocation.Offset: Int64;
begin
  Result := mOffset;
end;

function TLocation.Compare(ParaOther: ILocation): Integer;
begin
  if mFileId < ParaOther.FileId then
    Result := -1
  else if mFileId > ParaOther.FileId then
    Result := 1
  else if mOffset < ParaOther.Offset then
    Result := -1
  else if mOffset > ParaOther.Offset then
    Result := 1
  else
    Result := 0;
end;

function TLocation.Distance(ParaFileSize: Int64; ParaBackLocation: ILocation): Int64;
begin
  Result := (ParaBackLocation.FileId - mFileId) * ParaFileSize + (ParaBackLocation.Offset - mOffset);
end;

function TLocation.ToString: string;
begin
  Result := mFileId.ToString + '-' + mOffset.ToString;
end;

end.
