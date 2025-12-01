program Cmd.Generator.Wallet;

{$APPTYPE CONSOLE}

uses
	System.SysUtils,
	Wallet.Wallet;

var
	vNum: Integer;
	vIndex: Integer;
	vAddr: TAddress;
	vKey: IKey;
	vMnemonic: string;
	vNumStr: string;
	vSwitchValue: string;

begin
	vNum := 1;
	if FindCmdLineSwitch('num', vSwitchValue) then
	begin
		vNum := StrToIntDef(vSwitchValue, 1);
	end;

	for vIndex := 0 to vNum - 1 do
	begin
		try
			if not TWallet.RandomMnemonic24(vAddr, vKey, vMnemonic) then
			begin
				raise Exception.Create('Error generating mnemonic');
			end;
			WriteLn(Format('address:%s, key:%s, mnemonic:%s', [vAddr.ToString, vKey.Hex, vMnemonic]));
		except
			on E: Exception do
			begin
				WriteLn(E.Message);
				Halt(1);
			end;
		end;
	end;
end.
