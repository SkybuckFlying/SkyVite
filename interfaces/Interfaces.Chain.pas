unit Interfaces.Chain;

interface

uses
  System.SysUtils;

type
  IDBStatus = interface
    ['{C1E3B8B8-3B3B-4B3B-8B3B-3B3B3B3B3B3D}']
    function GetName: string;
    function GetCount: UInt64;
    function GetSize: UInt64;
    function GetStatus: string;
    procedure SetName(const ParaName: string);
    procedure SetCount(ParaCount: UInt64);
    procedure SetSize(ParaSize: UInt64);
    procedure SetStatus(const ParaStatus: string);
    property Name: string read GetName write SetName;
    property Count: UInt64 read GetCount write SetCount;
    property Size: UInt64 read GetSize write SetSize;
    property Status: string read GetStatus write SetStatus;
  end;

  IStorageIterator = interface
    ['{430455A3-4910-449D-AF82-63455432543D}']
    function Last: boolean;
    function Prev: boolean;
    function Next: boolean;
    function Seek(ParaKey: TBytes): boolean;
    function Key: TBytes;
    function Value: TBytes;
    function Error: Exception;
    procedure Release;
  end;

  TDBStatus = class(TInterfacedObject, IDBStatus)
  private
    mName: string;
    mCount: UInt64;
    mSize: UInt64;
    mStatus: string;
    function GetName: string;
    function GetCount: UInt64;
    function GetSize: UInt64;
    function GetStatus: string;
    procedure SetName(const ParaName: string);
    procedure SetCount(ParaCount: UInt64);
    procedure SetSize(ParaSize: UInt64);
    procedure SetStatus(const ParaStatus: string);
  public
    constructor Create(const ParaName: string; ParaCount, ParaSize: UInt64; const ParaStatus: string);
  end;

implementation

{ TDBStatus }

constructor TDBStatus.Create(const ParaName: string; ParaCount, ParaSize: UInt64; const ParaStatus: string);
begin
  inherited Create;
  mName := ParaName;
  mCount := ParaCount;
  mSize := ParaSize;
  mStatus := ParaStatus;
end;

function TDBStatus.GetCount: UInt64;
begin
  Result := mCount;
end;

function TDBStatus.GetName: string;
begin
  Result := mName;
end;

function TDBStatus.GetSize: UInt64;
begin
  Result := mSize;
end;

function TDBStatus.GetStatus: string;
begin
  Result := mStatus;
end;

procedure TDBStatus.SetCount(ParaCount: UInt64);
begin
  mCount := ParaCount;
end;

procedure TDBStatus.SetName(const ParaName: string);
begin
  mName := ParaName;
end;

procedure TDBStatus.SetSize(ParaSize: UInt64);
begin
  mSize := ParaSize;
end;

procedure TDBStatus.SetStatus(const ParaStatus: string);
begin
  mStatus := ParaStatus;
end;

end.