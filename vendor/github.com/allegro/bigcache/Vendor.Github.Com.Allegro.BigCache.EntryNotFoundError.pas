unit Vendor.Github.Com.Allegro.BigCache.EntryNotFoundError;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils;

type
  // ErrEntryNotFound is an error type struct which is returned when entry was not found for provided key
  EEntryNotFound = class(Exception);

implementation

end.
