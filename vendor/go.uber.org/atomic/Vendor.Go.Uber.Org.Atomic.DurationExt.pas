unit Vendor.Go.Uber.Org.Atomic.DurationExt;

interface

uses
  System.SysUtils, System.TimeSpan,
  Vendor.Go.Uber.Org.Atomic.Duration;

type
  TDurationHelper = class helper for TDuration
  public
    // Add, Sub and ToString are already in our TDuration implementation
  end;

implementation

end.
