unit Common.Errors.Errors;

interface

uses
  System.SysUtils;

var
  ErrNotFound: Exception;
  ErrNotMatch: Exception;

implementation

initialization
  ErrNotFound := Exception.Create('error: Not Found');
  ErrNotMatch := Exception.Create('error: Not Match');

end.
