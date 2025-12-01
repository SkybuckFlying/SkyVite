unit block_db_test;

interface

uses
  SysUtils, Classes, TestFramework, core, file_manager;

procedure TestReadSnapshotBlocks;
procedure TestReadAccountBlocks;

implementation

procedure TestReadSnapshotBlocks;
var
  ChainDir: string;
  DB: TObject; // Replace with actual BlockDB type
  StatusList: TList; // Replace with actual status type
  Start, Current: TLocation;
  I: Integer;
  SB: TObject; // Replace with actual SnapshotBlock type
  NextLocation: TLocation;
  Err: Exception;
begin
  // Skipped by default. This test can be used to inspect ledger data.
  Exit;
  ChainDir := HomeDir + '.gvite/mockdata/ledger_2101_2';
  // DB := NewBlockDB(ChainDir);
  // StatusList := DB.GetStatus;
  // for each status in StatusList do
  //   Log(status.Name, status.Count, status.Size, status.Status);
  Start := TLocation.Create(1, 0);
  Current := Start;
  I := 0;
  while I < 10 do
  begin
    // SB, _, NextLocation, Err := DB.ReadUnit(Current);
    // if Err = EOF then Break;
    // Assert(Err = nil);
    // if NextLocation = nil then Break;
    // Log('location', NextLocation.ToString);
    // if SB <> nil then
    // begin
    //   Inc(I);
    //   Log(SB.Height, SB.Hash, Current.ToString);
    // end;
    // Current := NextLocation;
  end;
end;

procedure TestReadAccountBlocks;
begin
  // Skipped by default. This test can be used to inspect ledger data.
  Exit;
  // Similar structure as TestReadSnapshotBlocks
end;

end.
