{$MODE DELPHIUNICODE}
unit Ledger.Chain.Sync.Cache.Cache.Item.Test;

interface

uses
  fpcunit,
  testregistry;

type
  TTestCacheItem = class(TTestCase)
  published
    procedure TestSerialize;
  end;

implementation

uses
{$IFDEF FPC}
  SysUtils,
  Math,
{$ELSE}
  System.SysUtils,
  System.Math,
{$ENDIF}
  Common.Types.Hash,
  Interfaces,
  Ledger.Chain.Sync.Cache.Cache.Item;

procedure FillRandom(var ParaBuffer: TBytes);
var
  vIndex: Integer;
begin
  for vIndex := 0 to Length(ParaBuffer) - 1 do
  begin
    ParaBuffer[vIndex] := System.Random(256);
  end;
end;

procedure TTestCacheItem.TestSerialize;
var
  vC1, vC2: TCacheItem;
  vData: TBytes;
  vIndex: Integer;
  vP1, vP2: TInterfaces.TPoint;
begin
  vC1 := TCacheItem.Create;
  try
    vC1.Segment.From := 101;
    vC1.Segment.To := 1000;
    FillRandom(TTypes.THash(vC1.Segment.Hash).Bytes);
    FillRandom(TTypes.THash(vC1.Segment.PrevHash).Bytes);
    vC1.Segment.Points := nil;

    vC1.mDone := true;
    vC1.mVerified := true;
    vC1.mFilename := 'chunk101_1000';
    vC1.mSize := 1837;

    vData := vC1.Serialize;
    AssertTrue(Length(vData) > 0, 'Serialization produced no data');

    vC2 := TCacheItem.Create;
    try
      vC2.DeSerialize(vData);

      AssertTrue(vC1.Segment.Equal(vC2.Segment), 'Segments are not equal');

      if (vC1.Segment.Points <> nil) and (vC2.Segment.Points <> nil) then
      begin
        AssertEquals(Length(vC1.Segment.Points), Length(vC2.Segment.Points), 'Points array length mismatch');
        for vIndex := 0 to Length(vC1.Segment.Points) - 1 do
        begin
          vP1 := vC1.Segment.Points[vIndex];
          vP2 := vC2.Segment.Points[vIndex];
          AssertEquals(vP1.Height, vP2.Height, 'Point heights are different');
          AssertEquals(vP1.Hash, vP2.Hash, 'Point hashes are different');
        end;
      end
      else if (vC1.Segment.Points <> nil) or (vC2.Segment.Points <> nil) then
      begin
        Fail('One of the Points arrays is nil while the other is not');
      end;


      AssertEquals(vC1.mVerified, vC2.mVerified, 'Verified fields are different');
      AssertEquals(vC1.mFilename, vC2.mFilename, 'Filename fields are different');
      AssertEquals(vC1.mDone, vC2.mDone, 'Done fields are different');
      AssertEquals(vC1.mSize, vC2.mSize, 'Size fields are different');

    finally
      vC2.Free;
    end;
  finally
    vC1.Free;
  end;
end;

initialization
  RegisterTest(TTestCacheItem);
end.
