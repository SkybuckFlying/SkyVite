unit vm.util.intpool;

interface

uses
  GoToDelphi.Helpers.BigInt,
  System.Generics.Collections,
  VM.Util.Common,
  VM.Util.Consensus.Reader,
  VM.Util.DB.Helper,
  VM.Util.Errors,
  VM.Util.Intpool.Test,
  VM.Util.Quota,
  VM.Util.Quota.Test,
  VM.Util.Types;

const
  poolLimit = 256;

type
  TIntPool = class
  private
    FPool: TStack<TBigInt>;
  public
    constructor Create;
    destructor Destroy; override;
    function Get: TBigInt;
    function GetZero: TBigInt;
    procedure Put(const ints: array of TBigInt);
  end;

  TIntPoolPool = class
  private
    FPools: TStack<TIntPool>;
    FMutex: TMutex;
    constructor Create;
  public
    destructor Destroy; override;
    function Get: TIntPool;
    procedure Put(pool: TIntPool);
    class var PoolOfIntPools: TIntPoolPool;
  end;

implementation

uses
  System.SysUtils;

{ TIntPool }

constructor TIntPool.Create;
begin
  FPool := TStack<TBigInt>.Create;
end;

destructor TIntPool.Destroy;
begin
  while FPool.Count > 0 do
    FPool.Pop.Free;
  FPool.Free;
  inherited;
end;

function TIntPool.Get: TBigInt;
begin
  if FPool.Count > 0 then
    Result := FPool.Pop
  else
    Result := TBigInt.Create;
end;

function TIntPool.GetZero: TBigInt;
begin
  if FPool.Count > 0 then
    Result := FPool.Pop.SetUInt64(0)
  else
    Result := TBigInt.Create(0);
end;

procedure TIntPool.Put(const ints: array of TBigInt);
var
  i: TBigInt;
begin
  if FPool.Count > poolLimit then
    Exit;
  for i in ints do
    FPool.Push(i);
end;

{ TIntPoolPool }

constructor TIntPoolPool.Create;
begin
  FPools := TStack<TIntPool>.Create;
  FMutex := TMutex.Create;
end;

destructor TIntPoolPool.Destroy;
begin
  while FPools.Count > 0 do
    FPools.Pop.Free;
  FPools.Free;
  FMutex.Free;
  inherited;
end;

function TIntPoolPool.Get: TIntPool;
begin
  FMutex.Acquire;
  try
    if FPools.Count > 0 then
      Result := FPools.Pop
    else
      Result := TIntPool.Create;
  finally
    FMutex.Release;
  end;
end;

procedure TIntPoolPool.Put(pool: TIntPool);
begin
  FMutex.Acquire;
  try
    if FPools.Count < 25 then // poolDefaultCap
      FPools.Push(pool)
    else
      pool.Free;
  finally
    FMutex.Release;
  end;
end;

initialization
  TIntPoolPool.PoolOfIntPools := TIntPoolPool.Create;

finalization
  TIntPoolPool.PoolOfIntPools.Free;

end.
