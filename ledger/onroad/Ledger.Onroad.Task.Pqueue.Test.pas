unit V2.Ledger.OnRoad.TaskPQueue.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  V2.Common.Types,
  V2.Ledger.OnRoad;

type
  // A Delphi implementation of the priority queue for TContractTask
  TTestContractTaskPQueue = class
  private
    FHeap: TList<TContractTask>;
    procedure HeapifyUp(AIndex: Integer);
    procedure HeapifyDown(AIndex: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(ATask: TContractTask);
    function Pop: TContractTask;
    procedure Fix(ATask: TContractTask);
    function Len: Integer;
    function Find(AAddr: TAddress): TContractTask;
  end;

  [TestFixture]
  TTaskPQueueTest = class(TObject)
  public
    [Test]
    procedure TestContractTaskPQueue;
    [Test]
    procedure TestContractTaskPQueue_PushOrFix;
  end;

implementation

uses System.Math;

{ TTestContractTaskPQueue }

constructor TTestContractTaskPQueue.Create;
begin
  inherited Create;
  FHeap := TList<TContractTask>.Create;
end;

destructor TTestContractTaskPQueue.Destroy;
begin
  FHeap.Free;
  inherited;
end;

function TTestContractTaskPQueue.Len: Integer;
begin
  Result := FHeap.Count;
end;

procedure TTestContractTaskPQueue.HeapifyUp(AIndex: Integer);
var
  ParentIndex, I: Integer;
  Temp: TContractTask;
begin
  I := AIndex;
  while I > 0 do
  begin
    ParentIndex := (I - 1) div 2;
    // Less(j, i) is true if i has higher priority than j.
    // Here, higher quota is higher priority.
    if FHeap[I].Quota <= FHeap[ParentIndex].Quota then
      Break;

    Temp := FHeap[I];
    FHeap[I] := FHeap[ParentIndex];
    FHeap[ParentIndex] := Temp;
    I := ParentIndex;
  end;
end;

procedure TTestContractTaskPQueue.HeapifyDown(AIndex: Integer);
var
  I, Left, Right, Largest: Integer;
  Temp: TContractTask;
begin
  I := AIndex;
  while True do
  begin
    Left := 2*I + 1;
    Right := 2*I + 2;
    Largest := I;

    if (Left < FHeap.Count) and (FHeap[Left].Quota > FHeap[Largest].Quota) then
      Largest := Left;

    if (Right < FHeap.Count) and (FHeap[Right].Quota > FHeap[Largest].Quota) then
      Largest := Right;

    if Largest = I then
      Break;

    Temp := FHeap[I];
    FHeap[I] := FHeap[Largest];
    FHeap[Largest] := Temp;
    I := Largest;
  end;
end;

procedure TTestContractTaskPQueue.Push(ATask: TContractTask);
begin
  FHeap.Add(ATask);
  HeapifyUp(FHeap.Count - 1);
end;

function TTestContractTaskPQueue.Pop: TContractTask;
begin
  if FHeap.Count = 0 then
    Exit(nil);

  Result := FHeap[0];
  FHeap[0] := FHeap[FHeap.Count - 1];
  FHeap.Delete(FHeap.Count - 1);
  HeapifyDown(0);
end;

function TTestContractTaskPQueue.Find(AAddr: TAddress): TContractTask;
begin
  for Result in FHeap do
    if Result.Addr.IsEqual(AAddr) then
      Exit;
  Result := nil;
end;

procedure TTestContractTaskPQueue.Fix(ATask: TContractTask);
var
  I: Integer;
begin
  for I := 0 to FHeap.Count - 1 do
  begin
    if FHeap[I] = ATask then
    begin
      HeapifyUp(I);
      HeapifyDown(I);
      Break;
    end;
  end;
end;


{ TTaskPQueueTest }

procedure TTaskPQueueTest.TestContractTaskPQueue;
var
  PQ: TTestContractTaskPQueue;
  Addr1, Addr2: TAddress;
  Task1, Task2, Popped: TContractTask;
begin
  PQ := TTestContractTaskPQueue.Create;
  try
    Addr1 := HexToAddress('vite_0f12dabefaff2e01dd0ab3bc2cbbe1c375ad253c8744bf95c9');
    Addr2 := HexToAddress('vite_5c84c3bc3c554060d17ae7c66924b379a2896ba7b3d4dd318f');

    Task1 := TContractTask.Create(Addr1, 0, 100);
    Task2 := TContractTask.Create(Addr2, 0, 200);

    PQ.Push(Task1);
    PQ.Push(Task2);

    Assert.AreEqual(2, PQ.Len);

    Popped := PQ.Pop;
    Assert.IsNotNull(Popped);
    Assert.AreEqual(Task2.Addr, Popped.Addr, 'Highest quota should be popped first');
    Assert.AreEqual(TUInt64(200), Popped.Quota);

    Popped := PQ.Pop;
    Assert.IsNotNull(Popped);
    Assert.AreEqual(Task1.Addr, Popped.Addr);
    Assert.AreEqual(TUInt64(100), Popped.Quota);

    Assert.AreEqual(0, PQ.Len);
  finally
    PQ.Free;
  end;
end;

procedure TTaskPQueueTest.TestContractTaskPQueue_PushOrFix;
var
  PQ: TTestContractTaskPQueue;
  Addr1, Addr2: TAddress;
  Task1, Task2, ExistingTask: TContractTask;
begin
  PQ := TTestContractTaskPQueue.Create;
  try
    Addr1 := HexToAddress('vite_0f12dabefaff2e01dd0ab3bc2cbbe1c375ad253c8744bf95c9');
    Addr2 := HexToAddress('vite_5c84c3bc3c554060d17ae7c66924b379a2896ba7b3d4dd318f');

    Task1 := TContractTask.Create(Addr1, 0, 100);
    Task2 := TContractTask.Create(Addr2, 0, 200);
    PQ.Push(Task1);
    PQ.Push(Task2);

    // Now, push a task for an existing address (Addr1) with a higher quota
    ExistingTask := PQ.Find(Addr1);
    Assert.IsNotNull(ExistingTask);
    ExistingTask.Quota := 300;
    PQ.Fix(ExistingTask);

    // Addr1 should now be the highest priority
    var Popped := PQ.Pop;
    Assert.AreEqual(Addr1, Popped.Addr);
    Assert.AreEqual(TUInt64(300), Popped.Quota);

    // Addr2 should be next
    Popped := PQ.Pop;
    Assert.AreEqual(Addr2, Popped.Addr);
    Assert.AreEqual(TUInt64(200), Popped.Quota);

  finally
    PQ.Free;
  end;
end;

initialization
  RegisterTest(TTaskPQueueTest.Suite);
end.
