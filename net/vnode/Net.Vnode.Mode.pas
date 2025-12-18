{
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
}
unit net.vnode.mode;

interface
uses
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test;

type
	// NodeMode mean the level of a node in the current hierarchy
	// Core nodes works on the highest level, usually are producers
	// Relay nodes usually are the standby producers, and partial full nodes (like static nodes)
	// Regular nodes usually are the full nodes
	// Edge nodes usually are the light nodes
	TNodeMode = (
		Edge = 1,
		Regular = 2,
		Relay = 4,
		Core = 8
	);

function NodeModeToString(ParaNodeMode: TNodeMode): string;

type
	TNodeModeHelper = record helper for TNodeMode
	public
		function ToString: string;
	end;

implementation

function NodeModeToString(ParaNodeMode: TNodeMode): string;
begin
	case ParaNodeMode of
		Edge:
			Result := 'edge';
		Regular:
			Result := 'regular';
		Relay:
			Result := 'relay';
		Core:
			Result := 'core';
	else
		Result := 'unknown';
	end;
end;

{ TNodeModeHelper }

function TNodeModeHelper.ToString: string;
begin
	Result := NodeModeToString(Self);
end;

end.
