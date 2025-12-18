unit Common.Helper.Slice;

interface

uses
  Common.Helper.Common,
  Common.Helper.Common.Test,
  Common.Helper.Math.Big,
  Common.Helper.Math.Integer,
  Common.Helper.Math.Test,
  Common.Helper.Rand,
  Common.Helper.Rand.Test,
  System.SysUtils;

type
  TSliceHelper = class
  public
    class procedure Reverse<T>(var ParaSlice: TArray<T>);
  end;

implementation

{ TSliceHelper }

class procedure TSliceHelper.Reverse<T>(var ParaSlice: TArray<T>);
var
  vI, vJ: Integer;
  vTemp: T;
begin
  vI := 0;
  vJ := High(ParaSlice);
  while vI < vJ do
  begin
    vTemp := ParaSlice[vI];
    ParaSlice[vI] := ParaSlice[vJ];
    ParaSlice[vJ] := vTemp;
    Inc(vI);
    Dec(vJ);
  end;
end;

end.
