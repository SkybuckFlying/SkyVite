unit Interfaces.Core.Token;

interface

uses
  System.SysUtils,
  Common.Types;

var
  ViteTokenId: TTokenTypeId;
  VCPTokenId: TTokenTypeId;

implementation

var
  vError: Exception;

initialization
  ViteTokenId := TTokenTypeId.FromBytes([Byte('V'), Byte('I'), Byte('T'), Byte('E'), Byte(' '), Byte('T'), Byte('O'), Byte('K'), Byte('E'), Byte('N')], vError);
  VCPTokenId := TTokenTypeId.FromHexString('tti_251a3e67a41b5ea2373936c8', vError);

end.
