program hd_bip_main;

uses
  SysUtils, hd_bip.derivation.bip_example;

begin
  try
    RandomMnemonic24('');
  except
    on E: Exception do
      Writeln(E.Message);
  end;
end.
