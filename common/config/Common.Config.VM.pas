unit Common.Config.Vm;

interface

uses
  System.SysUtils,
  System.Classes;

/*
 * Copyright 2019 The go-vite Authors
 * This file is part of the go-vite library.
 *
 * The go-vite library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The go-vite library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the go-vite library. If not, see <http://www.gnu.org/licenses/>.
 */

type
  TVm = class
	private
		mIsVmTest : boolean;
		mIsUseVmTestParam : boolean;
		mIsUseQuotaTestParam : boolean;
		mIsVmDebug : boolean;
	public
		constructor Create;
		destructor Destroy; override;
		procedure Reset;
		property IsVmTest : boolean read mIsVmTest write mIsVmTest;
		property IsUseVmTestParam : boolean read mIsUseVmTestParam write mIsUseVmTestParam;
		property IsUseQuotaTestParam : boolean read mIsUseQuotaTestParam write mIsUseQuotaTestParam;
		property IsVmDebug : boolean read mIsVmDebug write mIsVmDebug;
	end;

implementation

{ TVm }

constructor TVm.Create;
begin
	Reset;
end;

destructor TVm.Destroy;
begin
	// Add any necessary cleanup here
	inherited;
end;

procedure TVm.Reset;
begin
	mIsVmTest := False;
	mIsUseVmTestParam := False;
	mIsUseQuotaTestParam := False;
	mIsVmDebug := False;
end;


end.