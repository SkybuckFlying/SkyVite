unit Vendor.Go.Uber.Org.Atomic.UnsafePointer;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  /// <summary>
  /// UnsafePointer is an atomic wrapper around Pointer.
  /// </summary>
  TUnsafePointer = class
  private
    FV: Pointer;
  public
    constructor Create(Val: Pointer = nil);

    function Load: Pointer;
    procedure Store(Val: Pointer);
    function Swap(Val: Pointer): Pointer;
    function CAS(Old, NewVal: Pointer): Boolean;
  end;

implementation

{ TUnsafePointer }

constructor TUnsafePointer.Create(Val: Pointer);
begin
  FV := Val;
end;

function TUnsafePointer.Load: Pointer;
begin
  // TInterlocked.Read for Pointer is often CompareExchange with nil
  Result := TInterlocked.CompareExchange(FV, nil, nil);
end;

procedure TUnsafePointer.Store(Val: Pointer);
begin
  TInterlocked.Exchange(FV, Val);
end;

function TUnsafePointer.Swap(Val: Pointer): Pointer;
begin
  Result := TInterlocked.Exchange(FV, Val);
end;

function TUnsafePointer.CAS(Old, NewVal: Pointer): Boolean;
begin
  Result := TInterlocked.CompareExchange(FV, NewVal, Old) = Old;
end;

end.
