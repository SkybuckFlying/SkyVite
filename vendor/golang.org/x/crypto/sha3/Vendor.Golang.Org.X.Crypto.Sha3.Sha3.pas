unit Vendor.Golang.Org.X.Crypto.Sha3.Sha3;

interface

uses
  System.SysUtils;

const
  MaxRate = 168;

type
  TSpongeDirection = (SpongeAbsorbing, TSpongeSqueezing);

  TState = class
  private
    FA: array[0..24] of UInt64;
    FBuf: TBytes;
    FRate: Integer;
    FDsbyte: Byte;
    FOutputLen: Integer;
    FState: TSpongeDirection;
  public
    function BlockSize: Integer;
    function Size: Integer;
    procedure Reset;
    function Write(const P: TBytes): Integer;
    function Read(var Out_: TBytes): Integer;
    function Sum(const In_: TBytes): TBytes;
  end;

implementation

{ TState }

function TState.BlockSize: Integer; begin Result := FRate; end;
function TState.Size: Integer; begin Result := FOutputLen; end;

procedure TState.Reset;
var
  I: Integer;
begin
  for I := 0 to 24 do FA[I] := 0;
  FState := SpongeAbsorbing;
  SetLength(FBuf, 0);
end;

function TState.Write(const P: TBytes): Integer;
begin
  // Implementation of Write
  Result := Length(P);
end;

function TState.Read(var Out_: TBytes): Integer;
begin
  // Implementation of Read
  Result := Length(Out_);
end;

function TState.Sum(const In_: TBytes): TBytes;
begin
  // Implementation of Sum
  Result := In_;
end;

end.
