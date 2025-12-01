unit Common.Types.Error;

interface

uses
  System.SysUtils;

const
  ConstErrGetLatestAccountBlock = 'get latest account block failed';
  ConstErrGetLatestSnapshotBlock = 'get latest snapshot block failed';
  ConstErrVmRunPanic = 'generator_vm panic error';
  ConstErrJsonNotString = 'json: not a string';

var
  gErrGetLatestAccountBlock: Exception;
  gErrGetLatestSnapshotBlock: Exception;
  gErrVmRunPanic: Exception;
  gErrJsonNotString: Exception;

implementation

initialization
  gErrGetLatestAccountBlock := Exception.Create(ConstErrGetLatestAccountBlock);
  gErrGetLatestSnapshotBlock := Exception.Create(ConstErrGetLatestSnapshotBlock);
  gErrVmRunPanic := Exception.Create(ConstErrVmRunPanic);
  gErrJsonNotString := Exception.Create(ConstErrJsonNotString);

finalization
  if Assigned(gErrGetLatestAccountBlock) then
  begin
    gErrGetLatestAccountBlock.Free;
  end;
  if Assigned(gErrGetLatestSnapshotBlock) then
  begin
    gErrGetLatestSnapshotBlock.Free;
  end;
  if Assigned(gErrVmRunPanic) then
  begin
    gErrVmRunPanic.Free;
  end;
  if Assigned(gErrJsonNotString) then
  begin
    gErrJsonNotString.Free;
  end;

end.
