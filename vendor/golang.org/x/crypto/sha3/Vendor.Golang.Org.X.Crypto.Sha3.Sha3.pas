unit Vendor.Golang.Org.X.Crypto.Sha3.Sha3;

interface

uses
  System.SysUtils, Crypto.Hash;

type
  TSpongeDirection = (sdAbsorbing, sdSqueezing);

const
  MaxRate = 168;

type
  TState = class
  private
    FA: array [0 .. 24] of UInt64;
    FBuf: TBytes;
    FRate: Integer;
    FDSByte: Byte;
    FOutputLen: Integer;
    FState: TSpongeDirection;

    procedure Permute;
    procedure PadAndPermute(ADSByte: Byte);
  public
    procedure Reset;
    procedure Write(const P: TBytes);
    function Read(out P: TBytes): Integer;
    function Sum(const InBytes: TBytes): TBytes;
  end;

implementation

uses
  Vendor.Golang.Org.X.Crypto.Sha3.Keccakf;

{ TState }

procedure TState.Reset;
var
  I: Integer;
begin
  for I := 0 to 24 do
    FA[I] := 0;
  FState := sdAbsorbing;
  SetLength(FBuf, 0);
end;

procedure TState.Permute;
begin
  // Implementation
  KeccakF1600(FA);
end;

procedure TState.PadAndPermute(ADSByte: Byte);
begin
  // Implementation
end;

procedure TState.Write(const P: TBytes);
begin
  // Implementation
end;

function TState.Read(out P: TBytes): Integer;
begin
  // Implementation
  Result := 0;
end;

function TState.Sum(const InBytes: TBytes): TBytes;
begin
  // Implementation
  Result := nil;
end;

end.
