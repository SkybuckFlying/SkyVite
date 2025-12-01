unit Common.Db.XLevelDB.Filter;

interface

uses
  System.SysUtils,
  Common.Db.XLevelDB.Filter.Filter,
  Common.Db.XLevelDB.Internal;

type
  TIFilter = class(TInterfacedObject, IFilter)
  private
    mFilter: IFilter;
  public
    constructor Create(const ParaFilter: IFilter);
    function Name: string;
    function NewGenerator: IFilterGenerator;
    function Contains(const ParaFilter, ParaKey: TBytes): boolean;
  end;

  TIFilterGenerator = class(TInterfacedObject, IFilterGenerator)
  private
    mFilterGenerator: IFilterGenerator;
  public
    constructor Create(const ParaFilterGenerator: IFilterGenerator);
    procedure Add(const ParaKey: TBytes);
    procedure Generate(const ParaBuffer: IBuffer);
  end;

implementation

{ TIFilter }

constructor TIFilter.Create(const ParaFilter: IFilter);
begin
  mFilter := ParaFilter;
end;

function TIFilter.Name: string;
begin
  Result := mFilter.Name;
end;

function TIFilter.NewGenerator: IFilterGenerator;
begin
  Result := TIFilterGenerator.Create(mFilter.NewGenerator);
end;

function TIFilter.Contains(const ParaFilter, ParaKey: TBytes): boolean;
var
  vInternalKey: TInternalKey;
begin
  vInternalKey := TInternalKey.New(ParaKey);
  Result := mFilter.Contains(ParaFilter, vInternalKey.UKey);
end;

{ TIFilterGenerator }

constructor TIFilterGenerator.Create(const ParaFilterGenerator: IFilterGenerator);
begin
  mFilterGenerator := ParaFilterGenerator;
end;

procedure TIFilterGenerator.Add(const ParaKey: TBytes);
var
  vInternalKey: TInternalKey;
begin
  vInternalKey := TInternalKey.New(ParaKey);
  mFilterGenerator.Add(vInternalKey.UKey);
end;

procedure TIFilterGenerator.Generate(const ParaBuffer: IBuffer);
begin
  mFilterGenerator.Generate(ParaBuffer);
end;

end.
