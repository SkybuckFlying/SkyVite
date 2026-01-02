unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.LegacyFile;

interface

uses
  System.SysUtils, System.Classes, System.ZLib, System.SyncObjs,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry;

type
  IEnumV1 = interface
    ['{D3E4F5A6-B7C8-49D0-A1B2-C3D4E5F60718}']
    function EnumDescriptor: TTuple<TBytes, TArray<Integer>>;
  end;

  IMessageV1 = interface
    ['{E4F5A6B7-C8D9-40E1-B2C3-D4E5F6071829}']
    function Descriptor: TTuple<TBytes, TArray<Integer>>;
  end;

function LegacyLoadFileDesc(B: TBytes): IFileDescriptor;

implementation

var
  LegacyFileDescCache: TSyncMap;

function LegacyLoadFileDesc(B: TBytes): IFileDescriptor;
var
  V: TValue;
  MS, OutStream: TMemoryStream;
  Decompressor: TZDecompressionStream;
  B2: TBytes;
  Builder: TFileDescBuilder;
begin
  if (Length(B) > 0) and LegacyFileDescCache.Load(TValue.From<Pointer>(@B[0]), V) then
    Exit(V.AsInterface as IFileDescriptor);

  MS := TMemoryStream.Create;
  try
    MS.WriteBuffer(B[0], Length(B));
    MS.Position := 0;
    Decompressor := TZDecompressionStream.Create(MS);
    try
      OutStream := TMemoryStream.Create;
      try
        OutStream.CopyFrom(Decompressor, 0);
        SetLength(B2, OutStream.Size);
        OutStream.Position := 0;
        OutStream.ReadBuffer(B2[0], Length(B2));
      finally
        OutStream.Free;
      end;
    finally
      Decompressor.Free;
    end;
  finally
    MS.Free;
  end;

  Builder.RawDescriptor := B2;
  // Builder.FileRegistry := ...
  Result := Builder.Build.File_;
  
  if Length(B) > 0 then
    LegacyFileDescCache.LoadOrStore(TValue.From<Pointer>(@B[0]), TValue.From<IFileDescriptor>(Result), V);
end;

initialization
  LegacyFileDescCache := TSyncMap.Create;

finalization
  LegacyFileDescCache.Free;

end.
