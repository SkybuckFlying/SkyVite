unit Common.VitePb.Onroad;

interface

uses
  System.SysUtils;

type
  {
    TOnroadMeta corresponds to the OnroadMeta message in onroad.proto
  }
  TOnroadMeta = class
  private
    mNum: UInt64;
    mAmount: TBytes;
    mXXX_NoUnkeyedLiteral: record end;
    mXXX_unrecognized: TBytes;
    mXXX_sizecache: Int32;
  public
    constructor Create;
    procedure Reset;
    procedure ProtoMessage; // Placeholder
    property Num: UInt64 read mNum write mNum;
    property Amount: TBytes read mAmount write mAmount;
  end;

implementation

{ TOnroadMeta }

constructor TOnroadMeta.Create;
begin
  inherited Create;
  Reset;
end;

procedure TOnroadMeta.Reset;
begin
  mNum := 0;
  mAmount := nil;
  mXXX_sizecache := 0;
  mXXX_unrecognized := nil;
end;

procedure TOnroadMeta.ProtoMessage;
begin
  // This method is a marker for protobuf messages.
end;

end.