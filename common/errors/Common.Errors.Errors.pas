unit Common.Errors.Errors;

interface

uses
  Common.Errors.Wallet.Errors,
  System.SysUtils;

var
  ErrNotFound: Exception;
  ErrNotMatch: Exception;

implementation

initialization
  ErrNotFound := Exception.Create('error: Not Found');
  ErrNotMatch := Exception.Create('error: Not Match');

end.
