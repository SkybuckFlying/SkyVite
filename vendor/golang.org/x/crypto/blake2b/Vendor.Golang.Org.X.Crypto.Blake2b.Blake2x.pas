unit Vendor.Golang.Org.X.Crypto.Blake2b.Blake2x;

interface

uses
  System.SysUtils, System.Classes, System.Math;

type
  IXOF = interface
    procedure Write(const P: TBytes);
    function Read(var P: TBytes): Integer;
    function Clone: IXOF;
    procedure Reset;
  end;

const
  OutputLengthUnknown = 0;

implementation

end.
