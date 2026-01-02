unit Vendor.Golang.Org.X.Sys.Cpu.Byteorder;

interface

uses
  System.SysUtils;

type
  IByteOrder = interface
    function Uint32(const B: TBytes): UInt32;
    function Uint64(const B: TBytes): UInt64;
  end;

  TLittleEndian = class(TInterfacedObject, IByteOrder)
  public
    function Uint32(const B: TBytes): UInt32;
    function Uint64(const B: TBytes): UInt64;
  end;

  TBigEndian = class(TInterfacedObject, IByteOrder)
  public
    function Uint32(const B: TBytes): UInt32;
    function Uint64(const B: TBytes): UInt64;
  end;

function HostByteOrder: IByteOrder;

implementation

{ TLittleEndian }

function TLittleEndian.Uint32(const B: TBytes): UInt32;
begin
  Result := UInt32(B[0]) or (UInt32(B[1]) shl 8) or (UInt32(B[2]) shl 16) or (UInt32(B[3]) shl 24);
end;

function TLittleEndian.Uint64(const B: TBytes): UInt64;
begin
  Result := UInt64(B[0]) or (UInt64(B[1]) shl 8) or (UInt64(B[2]) shl 16) or (UInt64(B[3]) shl 24) or
            (UInt64(B[4]) shl 32) or (UInt64(B[5]) shl 40) or (UInt64(B[6]) shl 48) or (UInt64(B[7]) shl 56);
end;

{ TBigEndian }

function TBigEndian.Uint32(const B: TBytes): UInt32;
begin
  Result := UInt32(B[3]) or (UInt32(B[2]) shl 8) or (UInt32(B[1]) shl 16) or (UInt32(B[0]) shl 24);
end;

function TBigEndian.Uint64(const B: TBytes): UInt64;
begin
  Result := UInt64(B[7]) or (UInt64(B[6]) shl 8) or (UInt64(B[5]) shl 16) or (UInt64(B[4]) shl 24) or
            (UInt64(B[3]) shl 32) or (UInt64(B[2]) shl 40) or (UInt64(B[1]) shl 48) or (UInt64(B[0]) shl 56);
end;

function HostByteOrder: IByteOrder;
begin
  {$IFDEF ENDIAN_LITTLE}
  Result := TLittleEndian.Create;
  {$ELSE}
  Result := TBigEndian.Create;
  {$ENDIF}
end;

end.
