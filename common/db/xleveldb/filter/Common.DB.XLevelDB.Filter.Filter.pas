unit Common.Db.XLevelDB.Filter;

interface

uses
  System.SysUtils;

type
  IBuffer = interface
    ['{C1B7A6D2-C1B7-4E6F-8F3C-3D1B7A6D2C1B}']
    function Alloc(n: integer): TBytes;
    function Write(p: TBytes): integer;
    function WriteByte(c: byte): boolean;
  end;

  IFilterGenerator = interface
    ['{A6D2C1B7-A6D2-4E6F-8F3C-3D1B7A6D2C1B}']
    procedure Add(key: TBytes);
    procedure Generate(b: IBuffer);
  end;

  IFilter = interface
    ['{B7A6D2C1-B7A6-4E6F-8F3C-3D1B7A6D2C1B}']
    function Name: string;
    function NewGenerator: IFilterGenerator;
    function Contains(filter, key: TBytes): boolean;
  end;

implementation

end.
