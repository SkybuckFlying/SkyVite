unit Common.Config.Wallet;

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
  TWallet = class
	private
		mDataDir : string;
		mMaxSearchIndex : cardinal;
	public
		constructor Create;
		destructor Destroy; override;
		procedure Reset;
		property DataDir : string read mDataDir write mDataDir;
		property MaxSearchIndex : cardinal read mMaxSearchIndex write mMaxSearchIndex;
	end;

implementation

{ TWallet }

constructor TWallet.Create;
begin
	Reset;
end;

destructor TWallet.Destroy;
begin
	// Add any necessary cleanup here
	inherited;
end;

procedure TWallet.Reset;
begin
	mDataDir := '';
	mMaxSearchIndex := 0;
end;

end.