{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Allegro.BigCache.EntryNotFoundError;

interface

var
	// ErrEntryNotFound is an error type struct which is returned when entry was not found for provided key
	ErrEntryNotFound : string;

implementation

initialization
	ErrEntryNotFound := 'Entry not found';

end.
