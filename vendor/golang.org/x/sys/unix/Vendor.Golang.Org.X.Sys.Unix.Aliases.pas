unit Vendor.Golang.Org.X.Sys.Unix.Aliases;

interface

uses
  System.SysUtils;

// In Delphi, we can't directly alias types across different units like Go's type alias.
// We provide local type definitions.

type
  TSignal = Integer;
  TErrno = Integer;
  // TSysProcAttr = ...

implementation

end.
