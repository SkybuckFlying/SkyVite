unit Ledger.Chain.FileManager.Interfaces;

interface

uses
  Ledger.Chain.File.Manager.FD,
  Ledger.Chain.File.Manager.FD.Manager,
  Ledger.Chain.File.Manager.File.Manager,
  Ledger.Chain.File.Manager.Location,
  System.Classes,
  System.SysUtils,
  Vite.Common,
  Vite.Interfaces;

type
  ILocation = interface
    ['{A1B2C3D4-E5F6-47A8-9B0C-1D2E3F4A5B6D}']
    function FileId: UInt64;
    function Offset: Int64;
    function Compare(ParaOther: ILocation): Integer;
    function ToString: string;
  end;

  IDataParser = interface
    ['{B1C2D3E4-F5A6-47B8-9C0D-1E2F3A4B5C6E}']
    function Write(ParaBuf: TBytes): TError;
    procedure WriteError(ParaError: TError);
    procedure Close;
  end;

  IFileManager = interface
    ['{C1D2E3F4-A5B6-47C8-9D0E-1F2A3B4C5D6F}']
    function NextFlushStartLocation: ILocation;
  end;

  IFdManager = interface
    ['{D1E2F3A4-B5C6-47D8-9E0F-1A2B3C4D5E6A}']
    function createNewFile(ParaFileId: UInt64): TFileStream;
    function getFileFd(ParaFileId: UInt64): TFileStream;
  end;

implementation

end.
