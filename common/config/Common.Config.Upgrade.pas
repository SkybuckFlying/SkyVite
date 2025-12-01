unit Common.Config.Upgrade;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  Common.Upgrade;

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
  // TUpgrade holds the configuration for fork points and upgrade levels.
  TUpgrade = class
  private
    mLevel: string;
    mPoints: TDictionary<string, TUpgradePoint>;
  public
    constructor Create;
    destructor Destroy; override;

    // Level can be "mainnet", "latest", or "custom".
    [JsonName('Level')]
    property Level: string read mLevel write mLevel;

    // Points defines custom fork points when Level is "custom".
    [JsonName('Points')]
    property Points: TDictionary<string, TUpgradePoint> read mPoints;

    function MakeUpgradeBox: IUpgradeBox;
  end;

implementation

{ TUpgrade }

constructor TUpgrade.Create;
begin
  inherited Create;
  try
    mPoints := TDictionary<string, TUpgradePoint>.Create;
  except
    on E: Exception do
    begin
      // Handle memory allocation failure if necessary
      raise;
    end;
  end;
end;

destructor TUpgrade.Destroy;
begin
  mPoints.Free;
  inherited Destroy;
end;

function TUpgrade.MakeUpgradeBox: IUpgradeBox;
begin
  if Self = nil then
  begin
    raise Exception.Create('Unknown upgrade config: instance is nil');
  end;

  if SameText(mLevel, 'mainnet') then
  begin
    Result := NewMainnetUpgradeBox;
  end
  else if SameText(mLevel, 'latest') then
  begin
    Result := NewLatestUpgradeBox;
  end
  else if SameText(mLevel, 'custom') then
  begin
    Result := NewCustomUpgradeBox(mPoints);
  end
  else
  begin
    raise Exception.Create('Unknown upgrade level: ' + mLevel);
  end;
end;

end.
