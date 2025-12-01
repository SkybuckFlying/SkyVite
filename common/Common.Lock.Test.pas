unit Common.Lock.Test;

interface

uses
	System.SysUtils,
	System.Threading,
	DUnitX.TestFramework,
	Common.Lock;

type
	[TestFixture]
	TNonBlockLockTests = class(TObject)
	public
		[Test]
		procedure TestTryLockAndUnlock;
		[Test]
		procedure TestLockAndUnlock;
		[Test]
		procedure TestTryLockFailsWhenLocked;
		[Test]
		procedure TestUnlockFailsWhenUnlocked;
		[Test]
		procedure TestContention;
	end;

implementation

{ TNonBlockLockTests }

procedure TNonBlockLockTests.TestTryLockAndUnlock;
var
	vLock : TNonBlockLock;
begin
	// Arrange
	vLock := Default(TNonBlockLock);

	// Act & Assert
	Assert.IsTrue(vLock.TryLock, 'TryLock should succeed on an unlocked lock.');
	Assert.IsTrue(vLock.UnLock, 'UnLock should succeed on a locked lock.');
end;

procedure TNonBlockLockTests.TestLockAndUnlock;
var
	vLock : TNonBlockLock;
begin
	// Arrange
	vLock := Default(TNonBlockLock);

	// Act
	vLock.Lock;

	// Assert
	Assert.IsTrue(vLock.UnLock, 'UnLock should succeed after Lock.');
end;

procedure TNonBlockLockTests.TestTryLockFailsWhenLocked;
var
	vLock : TNonBlockLock;
begin
	// Arrange
	vLock := Default(TNonBlockLock);
	vLock.Lock;

	// Act & Assert
	Assert.IsFalse(vLock.TryLock, 'TryLock should fail on a locked lock.');

	// Cleanup
	vLock.UnLock;
end;

procedure TNonBlockLockTests.TestUnlockFailsWhenUnlocked;
var
	vLock : TNonBlockLock;
begin
	// Arrange
	vLock := Default(TNonBlockLock);

	// Act & Assert
	Assert.IsFalse(vLock.UnLock, 'UnLock should fail on an already unlocked lock.');
end;

procedure TNonBlockLockTests.TestContention;
var
	vLock : TNonBlockLock;
	vCounter : Integer;
	vTasks : TArray<ITask>;
	vIndex : Integer;
const
	ConstNumTasks = 10;
	ConstNumIncrements = 1000;
begin
	// Arrange
	vLock := Default(TNonBlockLock);
	vCounter := 0;
	SetLength(vTasks, ConstNumTasks);

	// Act
	for vIndex := 0 to High(vTasks) do
	begin
		vTasks[vIndex] := TTask.Run(
			procedure
			var
				vLoopIndex : Integer;
			begin
				for vLoopIndex := 1 to ConstNumIncrements do
				begin
					vLock.Lock;
					try
						vCounter := vCounter + 1;
					finally
						vLock.UnLock;
					end;
				end;
			end
			);
	end;

	TTask.WaitForAll(vTasks);

	// Assert
	Assert.AreEqual(ConstNumTasks * ConstNumIncrements, vCounter, 'The counter should be correctly incremented under lock.');
end;

initialization
	TDUnitX.RegisterTestFixture(TNonBlockLockTests);
end.