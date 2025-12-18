unit RpcApi.API.Ledger.V2.Test;

interface

procedure RunLedgerV2Test;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.TestFramework;

// Assuming getHeightPage will be in this unit or a dependency.
// For now, providing a stub for compilation.
procedure getHeightPage(var startHeight, endHeight: UInt64; pageSize: Integer; out offset, count: UInt64; out finish: Boolean);
const
  pageCount: UInt64 = 100;
begin
  if startHeight > endHeight then
  begin
    offset := endHeight;
    count := 0;
    finish := True;
    exit;
  end;

  offset := startHeight + pageCount - 1;
  if offset >= endHeight then
  begin
    offset := endHeight;
    count := endHeight - startHeight + 1;
    finish := True;
  end
  else
  begin
    count := pageCount;
    finish := False;
  end;
end;


type
  THeightResult = record
    Offset: UInt64;
    Count: UInt64;
    Finish: Boolean;
  end;

  TTestCase = record
    StartHeight: UInt64;
    EndHeight: UInt64;
    AccHeight: UInt64;
    ResultList: TArray<THeightResult>;
  end;

procedure TestGetHeightPage;
var
  TestCases: TArray<TTestCase>;
  TestCase: TTestCase;
  StartH, EndH, AccH, Offset, Count: UInt64;
  Finish: Boolean;
  I, Index: Integer;
  ResultRec: THeightResult;
begin
  SetLength(TestCases, 6);
  TestCases[0] := TTestCase.Create(0, 50, 150, [THeightResult.Create(50, 50, True)]);
  TestCases[1] := TTestCase.Create(0, 0, 150, [THeightResult.Create(100, 100, False), THeightResult.Create(150, 50, True)]);
  TestCases[2] := TTestCase.Create(0, 500, 150, [THeightResult.Create(100, 100, False), THeightResult.Create(150, 50, True)]);
  TestCases[3] := TTestCase.Create(0, 500, 700, [THeightResult.Create(100, 100, False), THeightResult.Create(200, 100, False), THeightResult.Create(300, 100, False), THeightResult.Create(400, 100, False), THeightResult.Create(500, 100, True)]);
  TestCases[4] := TTestCase.Create(0, 501, 700, [THeightResult.Create(100, 100, False), THeightResult.Create(200, 100, False), THeightResult.Create(300, 100, False), THeightResult.Create(400, 100, False), THeightResult.Create(500, 100, False), THeightResult.Create(501, 1, True)]);
  TestCases[5] := TTestCase.Create(100, 200, 200, [THeightResult.Create(199, 100, False), THeightResult.Create(200, 1, True)]);


  for I := 0 to High(TestCases) do
  begin
    TestCase := TestCases[I];
    StartH := TestCase.StartHeight;
    EndH := TestCase.EndHeight;
    AccH := TestCase.AccHeight;

    if StartH = 0 then StartH := 1;
    if (EndH = 0) or (EndH > AccH) then EndH := AccH;

    Index := 0;
    while True do
    begin
      Assert.IsTrue(Index < Length(TestCase.ResultList), Format('Test Case %d: Loop index %d exceeds result list length', [I, Index]));

      getHeightPage(StartH, EndH, 100, Offset, Count, Finish);
      StartH := Offset + 1;

      ResultRec := TestCase.ResultList[Index];
      Assert.AreEqual(ResultRec.Offset, Offset, Format('Test Case %d Index %d: Offset mismatch', [I, Index]));
      Assert.AreEqual(ResultRec.Count, Count, Format('Test Case %d Index %d: Count mismatch', [I, Index]));
      Assert.AreEqual(ResultRec.Finish, Finish, Format('Test Case %d Index %d: Finish flag mismatch', [I, Index]));

      Index := Index + 1;
      if (Count = 0) or Finish then Break;
    end;
    Assert.AreEqual(Length(TestCase.ResultList), Index, Format('Test Case %d: Did not consume all results', [I]));
  end;
end;

procedure RunLedgerV2Test;
begin
  TestGetHeightPage;
end;

end.
