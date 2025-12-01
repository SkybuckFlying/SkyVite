unit Common.Db.Xleveldb.Storage;

interface

uses
  System.SysUtils,
  System.Classes;

type
  TFileType = (
    TypeManifest,
    TypeJournal,
    TypeTable,
    TypeTemp
  );

  TFileTypes = set of TFileType;

const
  TypeAll: TFileTypes = [TypeManifest, TypeJournal, TypeTable, TypeTemp];

type
  EStorageError = class(Exception);
  EInvalidFile = class(EStorageError);
  ELocked = class(EStorageError);
  EClosed = class(EStorageError);

  ECorrupted = class(Exception)
  public
    Fd: TFileDesc;
    Err: Exception;
    constructor Create(AFd: TFileDesc; AErr: Exception);
  end;

  ISyncer = interface
    ['{7F8B941A-2F1B-4B6F-8C6D-3E5A693A8C2F}']
    function Sync: Exception;
  end;

  IReader = interface
    ['{8A7B6C5D-3E5A-4B6F-8C6D-3E5A693A8C2F}']
    function Read(var Buffer; Count: Longint): Longint;
    function Seek(Offset: Longint; Origin: TSeekOrigin): Longint;
    function ReadAt(var Buffer; Count, Offset: Longint): Longint;
    procedure Close;
  end;

  IWriter = interface
    ['{9B6C5D4E-4B6F-4B6F-8C6D-3E5A693A8C2F}']
    function Write(const Buffer; Count: Longint): Longint;
    function Sync: Exception;
    procedure Close;
  end;

  ILocker = interface
    ['{AD5E4F3C-5B8A-4B6F-8C6D-3E5A693A8C2F}']
    procedure Unlock;
  end;

  TFileDesc = record
    FType: TFileType;
    FNum: Int64;
    function ToString: string;
    function IsZero: Boolean;
    class function Ok(const AFd: TFileDesc): Boolean; static;
  end;

  IStorage = interface
    ['{BE4D3C2B-6C7D-4B6F-8C6D-3E5A693A8C2F}']
    function Lock: ILocker;
    procedure Log(const Str: string);
    procedure SetMeta(const AFd: TFileDesc);
    function GetMeta: TFileDesc;
    function List(AFT: TFileTypes): TArray<TFileDesc>;
    function Open(const AFd: TFileDesc): IReader;
    function Create(const AFd: TFileDesc): IWriter;
    procedure Remove(const AFd: TFileDesc);
    procedure Rename(const AOldFd, ANewFd: TFileDesc);
    procedure Close;
  end;

function FileTypeToString(AType: TFileType): string;

implementation

function FileTypeToString(AType: TFileType): string;
begin
  case AType of
    TypeManifest: Result := 'manifest';
    TypeJournal: Result := 'journal';
    TypeTable: Result := 'table';
    TypeTemp: Result := 'temp';
  else
    Result := Format('<unknown:%d>', [Ord(AType)]);
  end;
end;

{ ECorrupted }

constructor ECorrupted.Create(AFd: TFileDesc; AErr: Exception);
begin
  inherited CreateFmt('%s [file=%s]', [AErr.Message, AFd.ToString]);
  Fd := AFd;
  Err := AErr;
end;

{ TFileDesc }

function TFileDesc.ToString: string;
begin
  case FType of
    TypeManifest: Result := Format('MANIFEST-%06d', [FNum]);
    TypeJournal: Result := Format('%06d.log', [FNum]);
    TypeTable: Result := Format('%06d.ldb', [FNum]);
    TypeTemp: Result := Format('%06d.tmp', [FNum]);
  else
    Result := Format('%#x-%d', [Ord(FType), FNum]);
  end;
end;

function TFileDesc.IsZero: Boolean;
begin
  Result := (Ord(FType) = 0) and (FNum = 0);
end;

class function TFileDesc.Ok(const AFd: TFileDesc): Boolean;
begin
  Result := (AFd.FType in [TypeManifest, TypeJournal, TypeTable, TypeTemp]) and (AFd.FNum >= 0);
end;

end.