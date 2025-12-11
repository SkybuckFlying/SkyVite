{$MODE DELPHIUNICODE}
unit Ledger.Chain.Sync.Cache.Reader.Test;

interface

uses
  fpcunit,
  testregistry;

type
  TTestReader = class(TTestCase)
  published
    procedure TestRead3;
  end;

implementation

uses
{$IFDEF FPC}
  SysUtils,
  Classes,
{$ELSE}
  System.SysUtils,
  System.Classes,
{$ENDIF}
  Ledger.Chain.Sync.Cache.Reader,
  Interfaces.Core,
  Ledger.Chain.Block;

procedure TTestReader.TestRead3;
begin
  // This test is designed for manual inspection of a specific sync cache file.
  // It is skipped by default.
end;

initialization
  RegisterTest(TTestReader);
end.
