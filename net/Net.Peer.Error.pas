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
unit net.peer_error;

interface

type
	PeerError = (
		PeerNetworkError, // read/write timeout, read/write error
		PeerDifferentNetwork,
		PeerTooManyPeers,
		PeerTooManySameNetPeers,
		PeerTooManyInboundPeers,
		PeerAlreadyConnected,
		PeerIncompatibleVersion,
		PeerQuitting,
		PeerNotHandshakeMsg,
		PeerInvalidSignature,
		PeerConnectSelf,
		PeerUnknownMessage,
		PeerUnmarshalError,
		PeerNoPermission,
		PeerBanned,
		PeerDifferentGenesis,
		PeerInvalidBlock,
		PeerInvalidMessage,
		PeerResponseTimeout,
		PeerInvalidToken,
		PeerUnknownReason = 255
	);

	Exception = (
		ExpMissing, // I don`t have the resource you requested
		ExpUnsolicited, // the request must have pre-checked
		ExpUnauthorized,
		ExpServerError,
		ExpChunkNotMatch,
		ExpOther
	);

function PeerErrorToString(ParaPeerError: PeerError): string;
function ExceptionToString(ParaException: Exception): string;

type
	TPeerErrorHelper = record helper for PeerError
	public
		function ToString: string;
		function ToErrorString: string;
		function Serialize: TBytes;
	end;

	TExceptionHelper = record helper for Exception
	public
		function ToString: string;
		function ToErrorString: string;
		function Serialize: TBytes;
		procedure Deserialize(ParaBuffer: TBytes);
	end;

implementation

function PeerErrorToString(ParaPeerError: PeerError): string;
begin
	case ParaPeerError of
		PeerNetworkError:
			Result := 'network error';
		PeerDifferentNetwork:
			Result := 'different network';
		PeerTooManyPeers:
			Result := 'too many peers';
		PeerTooManySameNetPeers:
			Result := 'too many peers in the same net';
		PeerTooManyInboundPeers:
			Result := 'too many inbound peers';
		PeerAlreadyConnected:
			Result := 'already connected';
		PeerIncompatibleVersion:
			Result := 'incompatible version';
		PeerQuitting:
			Result := 'client quitting';
		PeerNotHandshakeMsg:
			Result := 'not handshake message';
		PeerInvalidSignature:
			Result := 'invalid signature';
		PeerConnectSelf:
			Result := 'connected to self';
		PeerUnknownMessage:
			Result := 'unknown message code';
		PeerUnmarshalError:
			Result := 'message unmarshal error';
		PeerNoPermission:
			Result := 'no permission';
		PeerBanned:
			Result := 'banned';
		PeerDifferentGenesis:
			Result := 'different genesis';
		PeerInvalidBlock:
			Result := 'invalid block';
		PeerInvalidMessage:
			Result := 'invalid message';
		PeerResponseTimeout:
			Result := 'response timeout';
		PeerInvalidToken:
			Result := 'invalid token';
		PeerUnknownReason:
			Result := 'unknown reason';
	else
		Result := 'unknown error';
	end;
end;

function ExceptionToString(ParaException: Exception): string;
begin
	case ParaException of
		ExpMissing:
			Result := 'missing resource';
		ExpUnsolicited:
			Result := 'unsolicited request';
		ExpUnauthorized:
			Result := 'unauthorized';
		ExpServerError:
			Result := 'server error';
		ExpChunkNotMatch:
			Result := 'chunk not match';
		ExpOther:
			Result := 'other exception';
	else
		Result := 'unknown exception';
	end;
end;

{ TPeerErrorHelper }

function TPeerErrorHelper.ToString: string;
begin
	Result := PeerErrorToString(Self);
end;

function TPeerErrorHelper.ToErrorString: string;
begin
	Result := ToString;
end;

function TPeerErrorHelper.Serialize: TBytes;
begin
	SetLength(Result, 1);
	Result[0] := Byte(Self);
end;

{ TExceptionHelper }

function TExceptionHelper.ToString: string;
begin
	Result := ExceptionToString(Self);
end;

function TExceptionHelper.ToErrorString: string;
begin
	Result := ToString;
end;

function TExceptionHelper.Serialize: TBytes;
begin
	SetLength(Result, 1);
	Result[0] := Byte(Self);
end;

procedure TExceptionHelper.Deserialize(ParaBuffer: TBytes);
begin
	if Length(ParaBuffer) > 0 then
	begin
		Self := Exception(ParaBuffer[0]);
	end;
end;

end.
