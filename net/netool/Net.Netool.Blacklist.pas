unit Net.Netool.Blacklist;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.DateUtils,
  System.Threading,
  Common.Bytes;

type
  TStrategy = reference to function(ParaT: Int64; ParaCount: Integer): Boolean;

  IBlackList = interface
    ['{A8B7C6D5-E4F3-A2B1-C0D9-E8F7A6B5C4D3}']
    procedure Ban(ParaBuf: TBytes; ParaExpiration: Int64);
    procedure UnBan(ParaBuf: TBytes);
    function Banned(ParaBuf: TBytes): Boolean;
  end;

  TRecord = class
  public
    c: Integer;
    t: Int64;
  end;

  TBlackList = class(TInterfacedObject, IBlackList)
  private
    mRecords: TDictionary<string, TRecord>;
    mStrategy: TStrategy;
    mRw: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create(ParaStrategy: TStrategy);
    destructor Destroy; override;
    procedure Ban(ParaBuf: TBytes; ParaExpiration: Int64);
    procedure UnBan(ParaBuf: TBytes);
    function Banned(ParaBuf: TBytes): Boolean;
  end;

function NewBlackList(ParaStrategy: TStrategy): IBlackList;

implementation

{ TBlackList }

constructor TBlackList.Create(ParaStrategy: TStrategy);
begin
  mRecords := TDictionary<string, TRecord>.Create;
  mStrategy := ParaStrategy;
  mRw := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TBlackList.Destroy;
var
  vRec: TRecord;
begin
  for vRec in mRecords.Values do
    vRec.Free;
  mRecords.Free;
  mRw.Free;
  inherited;
end;

procedure TBlackList.Ban(ParaBuf: TBytes; ParaExpiration: Int64);
var
  vId: string;
  vR: TRecord;
begin
  if Length(ParaBuf) = 0 then
    Exit;

  vId := BytesToHex(ParaBuf);

  mRw.BeginWrite;
  try
    if mRecords.TryGetValue(vId, vR) then
    begin
      vR.t := Round(Now * 86400) + ParaExpiration;
      Inc(vR.c);
    end
    else
    begin
      vR := TRecord.Create;
      vR.t := Round(Now * 86400) + ParaExpiration;
      vR.c := 1;
      mRecords.Add(vId, vR);
    end;
  finally
    mRw.EndWrite;
  end;
end;

procedure TBlackList.UnBan(ParaBuf: TBytes);
var
  vId: string;
  vR: TRecord;
begin
  vId := BytesToHex(ParaBuf);

  mRw.BeginWrite;
  try
    if mRecords.TryGetValue(vId, vR) then
    begin
      mRecords.Remove(vId);
      vR.Free;
    end;
  finally
    mRw.EndWrite;
  end;
end;

function TBlackList.Banned(ParaBuf: TBytes): Boolean;
var
  vId: string;
  vR: TRecord;
begin
  Result := False;
  vId := BytesToHex(ParaBuf);

  mRw.BeginWrite; // Use write lock because we might delete
  try
    if mRecords.TryGetValue(vId, vR) then
    begin
      if mStrategy(vR.t, vR.c) then
        Result := True
      else
      begin
        mRecords.Remove(vId);
        vR.Free;
      end;
    end;
  finally
    mRw.EndWrite;
  end;
end;

function NewBlackList(ParaStrategy: TStrategy): IBlackList;
begin
  Result := TBlackList.Create(ParaStrategy);
end;

end.
