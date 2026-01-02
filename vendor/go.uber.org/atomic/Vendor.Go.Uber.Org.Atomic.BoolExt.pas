unit Vendor.Go.Uber.Org.Atomic.BoolExt;

interface

uses
  System.SysUtils,
  Vendor.Go.Uber.Org.Atomic.Bool;

// This file in Go contains additional methods for the Bool type.
// In Delphi, we include them in the main TBool class if possible,
// or as a helper.

type
  TBoolHelper = class helper for TBool
  public
    // Toggle and String are already in our TBool implementation
  end;

implementation

end.
