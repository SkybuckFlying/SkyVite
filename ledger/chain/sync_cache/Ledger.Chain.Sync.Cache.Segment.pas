unit Ledger.Chain.Sync.Cache.Segment;

interface

uses
  Common.Types,
  Interfaces,
  Ledger.Chain.Sync.Cache.Cache.Item,
  Ledger.Chain.Sync.Cache.Cache.Item.Test,
  Ledger.Chain.Sync.Cache.Reader,
  Ledger.Chain.Sync.Cache.Reader.Test,
  Ledger.Chain.Sync.Cache.Segment.Test,
  Ledger.Chain.Sync.Cache.Sync.Cache,
  Ledger.Chain.Sync.Cache.Sync.Cache.Test,
  Ledger.Chain.Sync.Cache.Writer,
  System.SysUtils;

function NewSegment(const aFrom, aTo: UInt64; const aPrevHash, aHash: THash): ISegment;
function NewSegmentByFilename(const aFilename: string): ISegment;

implementation

uses
  System.IOUtils,
  System.StrUtils;

function NewSegment(const aFrom, aTo: UInt64; const aPrevHash, aHash: THash): ISegment;
begin
  Result.From := aFrom;
  Result.To := aTo;
  Result.Hash := aHash;
  Result.PrevHash := aPrevHash;
  Result.Points := nil;
end;

function NewSegmentByFilename(const aFilename: string): ISegment;
var
  vBaseFilename: string;
  vParts: TArray<string>;
  vFrom, vTo: UInt64;
  vPrevHash, vHash: THash;
begin
  try
    vBaseFilename := TPath.GetFileNameWithoutExtension(aFilename);
    if not vBaseFilename.StartsWith('f_') then
      raise Exception.CreateFmt('%s is invalid.', [aFilename]);

    vBaseFilename := vBaseFilename.Substring(2);
    vParts := vBaseFilename.Split(['_']);

    if Length(vParts) <> 4 then
      raise Exception.CreateFmt('%s is invalid.', [aFilename]);

    vFrom := TUtils.ParseUInt64(vParts[0]);
    vPrevHash := THash.HexToHash(vParts[1]);
    vTo := TUtils.ParseUInt64(vParts[2]);
    vHash := THash.HexToHash(vParts[3]);

    Result := NewSegment(vFrom, vTo, vPrevHash, vHash);
  except
    on E: Exception do
      raise Exception.CreateFmt('%s is invalid. Error: %s', [aFilename, E.Message]);
  end;
end;

end.
