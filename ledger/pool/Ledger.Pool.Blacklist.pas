unit Ledger.Pool.Blacklist;

interface

uses
  SysUtils, Classes, SyncObjs,
  System.Generics.Collections,
  Common.Types;

type
  TBlacklist = class
  private
    FList: TDictionary<TAddress, Boolean>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Add(Addr: TAddress);
    procedure Remove(Addr: TAddress);
    function Contains(Addr: TAddress): Boolean;
    function Count: Integer;
    function GetAddresses: TArray<TAddress>;
  end;

implementation

{ TBlacklist }

constructor TBlacklist.Create;
begin
  inherited Create;
  FList := TDictionary<TAddress, Boolean>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TBlacklist.Destroy;
begin
  FList.Free;
  FLock.Free;
  inherited;
end;

procedure TBlacklist.Add(Addr: TAddress);
begin
  FLock.BeginWrite;
  try
    FList.AddOrSetValue(Addr, True);
  finally
    FLock.EndWrite;
  end;
end;

procedure TBlacklist.Remove(Addr: TAddress);
begin
  FLock.BeginWrite;
  try
    FList.Remove(Addr);
  finally
    FLock.EndWrite;
  end;
end;

function TBlacklist.Contains(Addr: TAddress): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FList.ContainsKey(Addr);
  finally
    FLock.EndRead;
  end;
end;

function TBlacklist.Count: Integer;
begin
  FLock.BeginRead;
  try
    Result := FList.Count;
  finally
    FLock.EndRead;
  end;
end;

function TBlacklist.GetAddresses: TArray<TAddress>;
begin
  FLock.BeginRead;
  try
    Result := FList.Keys.ToArray;
  finally
    FLock.EndRead;
  end;
end;

end.
