unit Ledger.Chain.Sync.Cache.Reader.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  Ledger.Chain.Sync.Cache.Reader,
  Interfaces.Core;

type
  [TestFixture]
  TReaderTest = class(TObject)
  public
    [Test]
    procedure TestRead3;
  end;

implementation

uses
  System.IOUtils;

procedure TReaderTest.TestRead3;
var
  vFilename: string;
  vFileStream: TFileStream;
  vReader: TReader;
  vAb: IAccountBlock;
  vSb: ISnapshotBlock;
begin
  Assert.Ignore('Skipped by default. This test is for manual inspection of sync cache files and requires a valid file path.');

  // To run this test:
  // 1. Replace the placeholder path in vFilename with a valid path to a sync cache file.
  // 2. Uncomment the test logic below.
  // 3. Provide valid TSyncCache and TCacheItem instances to the TReader constructor.
  vFilename := 'xxxxx/f_57990301_57991300_1617778532';
  if not TFile.Exists(vFilename) then
  begin
    TestFramework.Log('File not found: ' + vFilename);
    Exit;
  end;

  vFileStream := TFileStream.Create(vFilename, fmOpenReadWrite);
  try
    // The original Go test creates a Reader struct directly with some nil members.
    // The Delphi TReader constructor requires valid objects.
    // Since this test is skipped and for manual inspection only,
    // we cannot fully replicate it without a valid TSyncCache and TCacheItem instance.
    // vReader := TReader.Create(nil, nil); // This would not compile
    // For now, the logic below is commented out to allow the project to compile.
    {
    while True do
    begin
      if not vReader.Read(vAb, vSb) then
        Break;

      if vAb <> nil then
        TestFramework.LogFmt('[ab] height:%d, hash:%s, address:%s', [vAb.Height, vAb.Hash.ToString, vAb.AccountAddress.ToString])
      else if vSb <> nil then
        TestFramework.LogFmt('[sb] height:%d, hash:%s', [vSb.Height, vSb.Hash.ToString]);
    end;
    }
  finally
    vFileStream.Free;
  end;
end;

end.
