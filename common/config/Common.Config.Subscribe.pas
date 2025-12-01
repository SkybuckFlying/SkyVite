unit Common.Config.Subscribe;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON;

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
  TSubscribe = class
  private
    mIsSubscribe: boolean;
    procedure Reset;
  public
    constructor Create;
    destructor Destroy; override;

    [JsonName('IsSubscribe')]
    property IsSubscribe: boolean read mIsSubscribe write mIsSubscribe;
  end;

implementation

{ TSubscribe }

constructor TSubscribe.Create;
begin
  inherited Create;
  Reset;
end;

destructor TSubscribe.Destroy;
begin
  // No owned objects to free
  inherited Destroy;
end;

procedure TSubscribe.Reset;
begin
  mIsSubscribe := false;
end;

end.
