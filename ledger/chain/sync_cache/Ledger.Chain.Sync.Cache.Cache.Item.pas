unit Ledger.Chain.Sync.Cache.Cache.Item;

interface

uses
  Common.Types,
  Common.VitePB,
  Interfaces.Core,
  Ledger.Chain.Sync.Cache.Cache.Item.Test,
  Ledger.Chain.Sync.Cache.Reader,
  Ledger.Chain.Sync.Cache.Reader.Test,
  Ledger.Chain.Sync.Cache.Segment,
  Ledger.Chain.Sync.Cache.Segment.Test,
  Ledger.Chain.Sync.Cache.Sync.Cache,
  Ledger.Chain.Sync.Cache.Sync.Cache.Test,
  Ledger.Chain.Sync.Cache.Writer,
  Proto,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

var
  dbItemPrefix: TBytes;

type
  TCacheItem = class(TSegment)
  private
    FDone: Boolean;
    FVerified: Boolean;
    FFilename: string;
    FSize: Int64;
  public
    function DbKey: TBytes;
    function Serialize: TBytes;
    function DeSerialize(AData: TBytes): HResult;
    property Done: Boolean read FDone write FDone;
    property Verified: Boolean read FVerified write FVerified;
    property Filename: string read FFilename write FFilename;
    property Size: Int64 read FSize write FSize;
  end;

  TCacheItems = class(TObjectList<TCacheItem>);

implementation

{ TCacheItem }

function TCacheItem.DbKey: TBytes;
begin
  SetLength(Result, 18);
  System.Move(dbItemPrefix[0], Result[0], Length(dbItemPrefix));
  TBitConverter.GetBytes(Self.From, Result, 2);
  TBitConverter.GetBytes(Self.To, Result, 10);
end;

function TCacheItem.Serialize: TBytes;
var
  pb: TCacheItemPB;
  p: THashHeight;
  hh: THashHeightPB;
begin
  pb := TCacheItemPB.Create;
  try
    pb.From := Self.From;
    pb.To := Self.To;
    pb.PrevHash := Self.PrevHash.Bytes;
    pb.Hash := Self.Hash.Bytes;
    pb.Verified := Self.Verified;
    pb.Filename := Self.Filename;
    pb.Done := Self.Done;
    pb.Size := Self.Size;
    if Length(Self.Points) > 0 then
    begin
      SetLength(pb.Points, Length(Self.Points));
      for p in Self.Points do
      begin
        hh := THashHeightPB.Create;
        hh.Height := p.Height;
        hh.Hash := p.Hash.Bytes;
        pb.Points[Length(pb.Points) - 1] := hh;
      end;
    end;
    Result := TProto.Marshal(pb);
  finally
    pb.Free;
  end;
end;

function TCacheItem.DeSerialize(AData: TBytes): HResult;
var
  pb: TCacheItemPB;
  p: THashHeightPB;
  hh: THashHeight;
begin
  pb := TCacheItemPB.Create;
  try
    if TProto.Unmarshal(AData, pb) <> S_OK then
    begin
      Result := E_FAIL;
      Exit;
    end;
    Self.From := pb.From;
    Self.To := pb.To;
    Self.PrevHash := THash.FromBytes(pb.PrevHash);
    Self.Hash := THash.FromBytes(pb.Hash);
    Self.Filename := pb.Filename;
    Self.Verified := pb.Verified;
    Self.Done := pb.Done;
    Self.Size := pb.Size;
    if Length(pb.Points) > 0 then
    begin
      SetLength(Self.Points, Length(pb.Points));
      for p in pb.Points do
      begin
        hh := THashHeight.Create;
        hh.Height := p.Height;
        hh.Hash := THash.FromBytes(p.Hash);
        Self.Points[Length(Self.Points) - 1] := hh;
      end;
    end;
    Result := S_OK;
  finally
    pb.Free;
  end;
end;

initialization
  SetLength(dbItemPrefix, 2);
  dbItemPrefix[0] := Ord('c');
  dbItemPrefix[1] := Ord(':');
end.
