unit Common.DB.XLevelDB.Storage;

interface

uses
  System.SysUtils,
  Common.DB.XLevelDB.Storage.Storage; // Assuming this unit defines IStorage, IReader, IWriter, TFileDesc

type
  TIStorage = class; // Forward declaration

  TIStorageReader = class(TInterfacedObject, IReader)
  private
    mReader: IReader;
    mOwner: TIStorage;
  public
    constructor Create(const AReader: IReader; AOwner: TIStorage);
    function Read(P: TBytes): Integer;
    function ReadAt(P: TBytes; Off: Int64): Integer;
    function Seek(Offset: Int64; Whence: Integer): Int64;
    procedure Close;
    function Fd: UInt64;
  end;

  TIStorageWriter = class(TInterfacedObject, IWriter)
  private
    mWriter: IWriter;
    mOwner: TIStorage;
  public
    constructor Create(const AWriter: IWriter; AOwner: TIStorage);
    function Write(P: TBytes): Integer;
    function Sync: HResult;
    procedure Close;
    function Fd: UInt64;
  end;

  TIStorage = class(TInterfacedObject, IStorage)
  private
    mStorage: IStorage;
    mRead: UInt64;
    mWrite: UInt64;
  public
    constructor Create(const AStorage: IStorage);
    function Open(fd: TFileDesc): IReader;
    function Create(fd: TFileDesc): IWriter;
    procedure Remove(fd: TFileDesc);
    procedure Rename(oldfd, newfd: TFileDesc);
    function SetMeta(fd: TFileDesc): HResult;
    function GetMeta: TFileDesc;
    function List(Type: TFileType): TArray<TFileDesc>;
    procedure Log(const AStr: string);
    function GetReads: UInt64;
    function GetWrites: UInt64;
    // Implement other IStorage methods by forwarding
  end;

function NewIStorage(const AStorage: IStorage): IStorage;

implementation

{ TIStorageReader }

constructor TIStorageReader.Create(const AReader: IReader; AOwner: TIStorage);
begin
  inherited Create;
  mReader := AReader;
  mOwner := AOwner;
end;

function TIStorageReader.Read(P: TBytes): Integer;
begin
  Result := mReader.Read(P);
  if Result > 0 then
    TInterlocked.Add(mOwner.mRead, Result);
end;

function TIStorageReader.ReadAt(P: TBytes; Off: Int64): Integer;
begin
  Result := mReader.ReadAt(P, Off);
  if Result > 0 then
    TInterlocked.Add(mOwner.mRead, Result);
end;

function TIStorageReader.Seek(Offset: Int64; Whence: Integer): Int64;
begin
  Result := mReader.Seek(Offset, Whence);
end;

procedure TIStorageReader.Close;
begin
  mReader.Close;
end;

function TIStorageReader.Fd: UInt64;
begin
  Result := mReader.Fd;
end;

{ TIStorageWriter }

constructor TIStorageWriter.Create(const AWriter: IWriter; AOwner: TIStorage);
begin
  inherited Create;
  mWriter := AWriter;
  mOwner := AOwner;
end;

function TIStorageWriter.Write(P: TBytes): Integer;
begin
  Result := mWriter.Write(P);
  if Result > 0 then
    TInterlocked.Add(mOwner.mWrite, Result);
end;

function TIStorageWriter.Sync: HResult;
begin
  Result := mWriter.Sync;
end;

procedure TIStorageWriter.Close;
begin
  mWriter.Close;
end;

function TIStorageWriter.Fd: UInt64;
begin
  Result := mWriter.Fd;
end;

{ TIStorage }

constructor TIStorage.Create(const AStorage: IStorage);
begin
  inherited Create;
  mStorage := AStorage;
  mRead := 0;
  mWrite := 0;
end;

function TIStorage.Open(fd: TFileDesc): IReader;
var
  vReader: IReader;
begin
  vReader := mStorage.Open(fd);
  if vReader <> nil then
    Result := TIStorageReader.Create(vReader, Self)
  else
    Result := nil;
end;

function TIStorage.Create(fd: TFileDesc): IWriter;
var
  vWriter: IWriter;
begin
  vWriter := mStorage.Create(fd);
  if vWriter <> nil then
    Result := TIStorageWriter.Create(vWriter, Self)
  else
    Result := nil;
end;

procedure TIStorage.Remove(fd: TFileDesc);
begin
  mStorage.Remove(fd);
end;

procedure TIStorage.Rename(oldfd, newfd: TFileDesc);
begin
  mStorage.Rename(oldfd, newfd);
end;

function TIStorage.SetMeta(fd: TFileDesc): HResult;
begin
  Result := mStorage.SetMeta(fd);
end;

function TIStorage.GetMeta: TFileDesc;
begin
  Result := mStorage.GetMeta;
end;

function TIStorage.List(Type: TFileType): TArray<TFileDesc>;
begin
  Result := mStorage.List(Type);
end;

procedure TIStorage.Log(const AStr: string);
begin
  mStorage.Log(AStr);
end;

function TIStorage.GetReads: UInt64;
begin
  Result := TInterlocked.Read(mRead);
end;

function TIStorage.GetWrites: UInt64;
begin
  Result := TInterlocked.Read(mWrite);
end;

{ Global function }

function NewIStorage(const AStorage: IStorage): IStorage;
begin
  Result := TIStorage.Create(AStorage);
end;

end.
