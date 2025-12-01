unit Monitor.Ring;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs;

type
  TRing = class
  private
    mCap: Integer;
    mDatas: TArray<TObject>;
    mI: Integer;
    mMutex: TCriticalSection;
    function NextI(ParaI: Integer): Integer;
    function LastI(ParaI: Integer): Integer;
  public
    constructor Create(ParaN: Integer);
    destructor Destroy; override;
    procedure Add(ParaData: TObject);
    procedure Reset;
    function All: TArray<TObject>;
  end;

implementation

{ TRing }

constructor TRing.Create(ParaN: Integer);
begin
  inherited Create;
  mMutex := TCriticalSection.Create;
  SetLength(mDatas, ParaN);
  mCap := 0;
  mI := 0;
end;

destructor TRing.Destroy;
begin
  mMutex.Free;
  inherited Destroy;
end;

procedure TRing.Add(ParaData: TObject);
begin
  mMutex.Acquire;
  try
    mDatas[mI] := ParaData;
    mI := NextI(mI);
    if mCap < Length(mDatas) then
      Inc(mCap);
  finally
    mMutex.Release;
  end;
end;

procedure TRing.Reset;
begin
  mMutex.Acquire;
  try
    mI := 0;
    mCap := 0;
  finally
    mMutex.Release;
  end;
end;

function TRing.All: TArray<TObject>;
var
  vC, vJ, vN: Integer;
begin
  mMutex.Acquire;
  try
    vC := mCap;
    SetLength(Result, vC);
    vJ := mI;
    for vN := vC - 1 downto 0 do
    begin
      vJ := LastI(vJ);
      Result[vN] := mDatas[vJ];
    end;
  finally
    mMutex.Release;
  end;
end;

function TRing.LastI(ParaI: Integer): Integer;
var
  vL: Integer;
begin
  if ParaI = 0 then
  begin
    vL := Length(mDatas);
    Result := vL - 1;
  end
  else
    Result := ParaI - 1;
end;

function TRing.NextI(ParaI: Integer): Integer;
var
  vL: Integer;
begin
  vL := Length(mDatas);
  Inc(ParaI);
  if ParaI >= vL then
    Result := 0
  else
    Result := ParaI;
end;

end.