unit Vendor.Golang.Org.X.Sys.Unix.Race0;

interface

const
  RaceEnabled = False;

procedure RaceAcquire(Addr: Pointer);
procedure RaceReadRange(Addr: Pointer; Len: Integer);

implementation

procedure RaceAcquire(Addr: Pointer); begin end;
procedure RaceReadRange(Addr: Pointer; Len: Integer); begin end;

end.
