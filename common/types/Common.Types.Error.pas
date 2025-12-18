unit Common.Types.Error;

interface

uses
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
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
