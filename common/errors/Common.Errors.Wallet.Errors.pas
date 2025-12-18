unit Common.Errors.WalletErrors;

interface

uses
  Common.Errors.Errors,
  System.SysUtils;

var
  ErrLocked: Exception;
  ErrAddressNotFound: Exception;
  ErrInvalidPrikey: Exception;
  ErrDecryptEntropy: Exception;
  ErrEmptyStore: Exception;
  ErrStoreNotFound: Exception;

implementation

initialization
  ErrLocked := Exception.Create('the crypto store is locked');
  ErrAddressNotFound := Exception.Create('not found the given address in the crypto store file');
  ErrInvalidPrikey := Exception.Create('invalid prikey');
  ErrDecryptEntropy := Exception.Create('error decrypt store');
  ErrEmptyStore := Exception.Create('error empty store');
  ErrStoreNotFound := Exception.Create('error given store not found ');

end.
