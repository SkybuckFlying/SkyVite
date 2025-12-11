{$MODE DELPHIUNICODE}
unit Ledger.Chain.Sync.Cache.Segment.Test;

interface

uses
  fpcunit,
  testregistry;

type
  TTestSegment = class(TTestCase)
  published
    procedure TestNewSegmentByFilename;
  end;

implementation

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  Common.Types.Hash,
  Interfaces,
  Ledger.Chain.Sync.Cache.Segment;

procedure TTestSegment.TestNewSegmentByFilename;
var
  vName: string;
  vSeg: IInterfaces.TSegment;
  vExpectedPrevHash: TTypes.THash;
  vExpectedHash: TTypes.THash;
begin
  vName := 'f_100_0000000000000000000000000000000000000000000000000000000000000001_200_0000000000000000000000000000000000000000000000000000000000000002';
  vExpectedPrevHash := TTypes.HexToHash('0000000000000000000000000000000000000000000000000000000000000001');
  vExpectedHash := TTypes.HexToHash('0000000000000000000000000000000000000000000000000000000000000002');

  vSeg := NewSegmentByFilename(vName);

  AssertEquals(UInt64(100), vSeg.From, 'From field mismatch');
  AssertEquals(UInt64(200), vSeg.To, 'To field mismatch');
  AssertEquals(vExpectedPrevHash, vSeg.PrevHash, 'PrevHash mismatch');
  AssertEquals(vExpectedHash, vSeg.Hash, 'Hash mismatch');

  vName := 'f_100_0000000000000000000000000000000000000000000000000000000000000001_200_0000000000000000000000000000000000000000000000000000000000000002.v';
  vSeg := NewSegmentByFilename(vName);
  AssertEquals(UInt64(100), vSeg.From, 'From field mismatch after extension');
  AssertEquals(UInt64(200), vSeg.To, 'To field mismatch after extension');
  AssertEquals(vExpectedPrevHash, vSeg.PrevHash, 'PrevHash mismatch after extension');
  AssertEquals(vExpectedHash, vSeg.Hash, 'Hash mismatch after extension');
end;

initialization
  RegisterTest(TTestSegment);
end.
