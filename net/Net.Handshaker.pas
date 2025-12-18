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
unit Handshaker;

interface

uses
  Common.BigInt,
  Common.Bytes,
  Crypto,
  Ed25519,
  GoToDelphi.Helpers.Net,
  Interfaces,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Connector.Connector,
  Net.Database.Database,
  Net.Database.Database.Test,
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  Net.Discovery.Message,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Protos.Message.PB,
  Net.Discovery.Simular.Simular,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
  Net.MsgHandler.Test,
  Net.Net,
  Net.Netool.Blacklist,
  Net.Netool.Net,
  Net.Netool.Net.Test,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
  Net.Sync.Cache.Reader.Test,
  Net.Sync.Conn,
  Net.Sync.Conn.Test,
  Net.Sync.Downloader,
  Net.Sync.Downloader.Test,
  Net.Sync.Server,
  Net.Sync.Server.Test,
  Net.Sync.State,
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  NetTool,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Types,
  VitePB,
  VNode;

const
	HandshakeTimeout = 10 * 1000; // 10 seconds in milliseconds

type
	THandshakeMsg = record
	public
		mVersion: Int64;
		mNetID: Int64;
		mName: string;
		mID: TNodeID;
		mTimestamp: Int64;
		mHeight: UInt64;
		mHead: THash;
		mGenesis: THash;
		mKey: TPublicKey; // is producer
		mToken: TBytes;
		mFileAddress: TBytes;
		mPublicAddress: TBytes;
		function Serialize(): TBytes;
		procedure Deserialize(ParaData: TBytes);
	end;

	TOnHandshakerEvent = reference to function(
		ParaCodec: ICodec;
		ParaFlag: TPeerFlag;
		ParaTheir: THandshakeMsg
	): Boolean;

	THandshaker = class
	private
		mVersion: Integer;
		mNetId: Integer;
		mName: string;
		mId: TNodeID;
		mGenesis: THash;
		mFileAddress: TBytes;
		mPublicAddress: TBytes;
		mPeerKey: TPrivateKey;
		mKey: TPrivateKey;
		mCodecFactory: ICodecFactory;
		mChain: IChainReader;
		mBlackList: IBlackList;
		mOnHandshaker: TOnHandshakerEvent;
		procedure BanAddr(ParaAddr: IAddr; ParaTime: Int64);
		function BannedAddr(ParaAddr: IAddr): Boolean;
		function GetSecret(ParaTheirId: TPeerId): TBytes;
		function VerifyHandshake(ParaTheir: THandshakeMsg; ParaSecret: TBytes): TPeerError;
		function MakeHandshake(ParaSecret: TBytes): THandshakeMsg;
		procedure SendHandshake(ParaCodec: ICodec; ParaOur: THandshakeMsg; ParaMsgId: TMsgId);
		function DoHandshake(ParaCodec: ICodec; ParaFlag: TPeerFlag; ParaTheir: THandshakeMsg): TPeerError;
		function ReadHandshake(ParaCodec: ICodec; out ParaTheir: THandshakeMsg; out ParaMsgId: TMsgId): TPeerError;
	public
		constructor Create(
			ParaVersion: Integer;
			ParaNetId: Integer;
			ParaName: string;
			ParaId: TNodeID;
			ParaGenesis: THash;
			ParaFileAddress: TBytes;
			ParaPublicAddress: TBytes;
			ParaPeerKey: TPrivateKey;
			ParaKey: TPrivateKey;
			ParaCodecFactory: ICodecFactory;
			ParaBlackList: IBlackList;
			ParaOnHandshaker: TOnHandshakerEvent
		);
		procedure SetChain(ParaChain: IChainReader);
		function ReceiveHandshake(
			ParaConn: IConn;
			out ParaCodec: ICodec;
			out ParaTheir: THandshakeMsg;
			out ParaSuperior: Boolean
		): TPeerError;
		function InitiateHandshake(
			ParaConn: IConn;
			ParaId: TNodeID;
			out ParaCodec: ICodec;
			out ParaTheir: THandshakeMsg;
			out ParaSuperior: Boolean
		): TPeerError;
	end;

implementation

{ THandshakeMsg }

procedure THandshakeMsg.Deserialize(ParaData: TBytes);
var
	vPb: THandshake;
	vError: TPeerError;
begin
	vPb := THandshake.Create;
	try
		TProto.Unmarshal(ParaData, vPb);

		Self.mID := TNodeID.BytesToNodeID(vPb.ID);
		Self.mVersion := vPb.Version;
		Self.mNetID := vPb.NetId;
		Self.mName := vPb.Name;
		Self.mTimestamp := vPb.Timestamp;
		Self.mHeight := vPb.Height;
		Self.mHead := THash.BytesToHash(vPb.Head);
		Self.mGenesis := THash.BytesToHash(vPb.Genesis);
		Self.mFileAddress := vPb.FileAddress;
		Self.mPublicAddress := vPb.PublicAddress;
		Self.mKey := vPb.Key;
		Self.mToken := vPb.Token;
	finally
		vPb.Free;
	end;
end;

function THandshakeMsg.Serialize: TBytes;
var
	vPb: THandshake;
begin
	vPb := THandshake.Create;
	try
		vPb.Version := Self.mVersion;
		vPb.NetId := Self.mNetID;
		vPb.Name := Self.mName;
		vPb.ID := Self.mID.Bytes;
		vPb.Timestamp := Self.mTimestamp;
		vPb.Genesis := Self.mGenesis.Bytes;
		vPb.Height := Self.mHeight;
		vPb.Head := Self.mHead.Bytes;
		vPb.FileAddress := Self.mFileAddress;
		vPb.Key := Self.mKey;
		vPb.Token := Self.mToken;
		vPb.PublicAddress := Self.mPublicAddress;
		Result := TProto.Marshal(vPb);
	finally
		vPb.Free;
	end;
end;

{ THandshaker }

constructor THandshaker.Create(
	ParaVersion: Integer;
	ParaNetId: Integer;
	ParaName: string;
	ParaId: TNodeID;
	ParaGenesis: THash;
	ParaFileAddress: TBytes;
	ParaPublicAddress: TBytes;
	ParaPeerKey: TPrivateKey;
	ParaKey: TPrivateKey;
	ParaCodecFactory: ICodecFactory;
	ParaBlackList: IBlackList;
	ParaOnHandshaker: TOnHandshakerEvent
);
begin
	mVersion := ParaVersion;
	mNetId := ParaNetId;
	mName := ParaName;
	mId := ParaId;
	mGenesis := ParaGenesis;
	mFileAddress := ParaFileAddress;
	mPublicAddress := ParaPublicAddress;
	mPeerKey := ParaPeerKey;
	mKey := ParaKey;
	mCodecFactory := ParaCodecFactory;
	mBlackList := ParaBlackList;
	mOnHandshaker := ParaOnHandshaker;
end;

procedure THandshaker.SetChain(ParaChain: IChainReader);
begin
	mGenesis := ParaChain.GetGenesisSnapshotBlock.Hash;
	mChain := ParaChain;
end;

procedure THandshaker.BanAddr(ParaAddr: IAddr; ParaTime: Int64);
var
	vTcpAddr: ITCPAddr;
	vIp: IIP;
begin
	if Supports(ParaAddr, ITCPAddr, vTcpAddr) then
	begin
		vIp := vTcpAddr.IP;
		mBlackList.Ban(vIp, ParaTime);
	end;
end;

function THandshaker.BannedAddr(ParaAddr: IAddr): Boolean;
var
	vTcpAddr: ITCPAddr;
	vIp: IIP;
begin
	Result := False;
	if Supports(ParaAddr, ITCPAddr, vTcpAddr) then
	begin
		vIp := vTcpAddr.IP;
		Result := mBlackList.Banned(vIp);
	end;
end;

function THandshaker.ReadHandshake(
	ParaCodec: ICodec;
	out ParaTheir: THandshakeMsg;
	out ParaMsgId: TMsgId
): TPeerError;
var
	vMsg: TMsg;
begin
	Result := peNoError;
	ParaCodec.SetReadTimeout(HandshakeTimeout);
	try
		vMsg := ParaCodec.ReadMsg;
	except
		on E: Exception do
		begin
			TNetLog.Warn(Format('failed to handshake with %s: read error: %s', [ParaCodec.Address, E.Message]));
			Result := peNetworkError;
			Exit;
		end;
	end;

	ParaMsgId := vMsg.Id;

	if vMsg.Code = TMsgCode.mcDisconnect then
	begin
		if Length(vMsg.Payload) > 0 then
		begin
			Result := TPeerError(vMsg.Payload[0]);
		end
		else
		begin
			Result := peUnknownReason;
		end;
		Exit;
	end;

	if vMsg.Code <> TMsgCode.mcHandshake then
	begin
		Result := peNotHandshakeMsg;
		TNetLog.Warn(Format('failed to handshake with %s: not handshakeMsg %d', [ParaCodec.Address, vMsg.Code]));
		Exit;
	end;

	try
		ParaTheir.Deserialize(vMsg.Payload);
	except
		on E: Exception do
		begin
			Result := peUnmarshalError;
			Exit;
		end;
	end;
end;

function THandshaker.GetSecret(ParaTheirId: TPeerId): TBytes;
var
	vPub: TPublicKey;
	vPriv: TPrivateKey;
begin
	vPub := TPublicKey.FromBytes(ParaTheirId.Bytes).ToX25519Pk;
	vPriv := mPeerKey.ToX25519Sk;
	Result := TCrypto.X25519ComputeSecret(vPriv, vPub);
end;

function THandshaker.VerifyHandshake(ParaTheir: THandshakeMsg; ParaSecret: TBytes): TPeerError;
var
	vTimestampBytes: TBytes;
	vHash: THash;
	vToken: TBytes;
begin
	Result := peNoError;
	SetLength(vTimestampBytes, 8);
	TBigEndian.PutUint64(vTimestampBytes, ParaTheir.mTimestamp);
	vHash := TCrypto.Hash256(vTimestampBytes);
	vToken := TXOR.XOR(vHash.Bytes, ParaSecret);

	if Length(ParaTheir.mKey) <> 0 then
	begin
		if not TEd25519.Verify(ParaTheir.mKey, vToken, ParaTheir.mToken) then
		begin
			Result := peInvalidSignature;
			Exit;
		end;
	end
	else
	begin
		if not TBytes.Equal(vToken, ParaTheir.mToken) then
		begin
			Result := peInvalidToken;
			Exit;
		end;
	end;
end;

function THandshaker.MakeHandshake(ParaSecret: TBytes): THandshakeMsg;
var
	vLatestBlock: TSnapshotBlock;
	vTimestampBytes: TBytes;
	vHash: THash;
begin
	vLatestBlock := mChain.GetLatestSnapshotBlock;
	Result.mVersion := mVersion;
	Result.mNetID := mNetId;
	Result.mName := mName;
	Result.mID := mId;
	Result.mTimestamp := TTime.Now.ToUnix;
	Result.mHeight := vLatestBlock.Height;
	Result.mHead := vLatestBlock.Hash;
	Result.mGenesis := mGenesis;
	Result.mKey := nil;
	Result.mToken := nil;
	Result.mFileAddress := mFileAddress;
	Result.mPublicAddress := mPublicAddress;

	SetLength(vTimestampBytes, 8);
	TBigEndian.PutUint64(vTimestampBytes, Result.mTimestamp);
	vHash := TCrypto.Hash256(vTimestampBytes);

	Result.mToken := TXOR.XOR(vHash.Bytes, ParaSecret);
	if mKey <> nil then
	begin
		Result.mKey := mKey.PubByte;
		Result.mToken := TEd25519.Sign(mKey, Result.mToken);
	end;
end;

procedure THandshaker.SendHandshake(ParaCodec: ICodec; ParaOur: THandshakeMsg; ParaMsgId: TMsgId);
var
	vData: TBytes;
	vMsg: TMsg;
begin
	try
		vData := ParaOur.Serialize;
	except
		on E: Exception do
		begin
			raise EPeerError.Create(peUnmarshalError);
		end;
	end;

	ParaCodec.SetWriteTimeout(HandshakeTimeout);
	vMsg.Code := TMsgCode.mcHandshake;
	vMsg.Id := ParaMsgId;
	vMsg.Payload := vData;

	try
		ParaCodec.WriteMsg(vMsg);
	except
		on E: Exception do
		begin
			TNetLog.Warn(Format('failed to handshake with %s: write error: %s', [ParaCodec.Address, E.Message]));
			raise EPeerError.Create(peNetworkError);
		end;
	end;
end;

function THandshaker.ReceiveHandshake(
	ParaConn: IConn;
	out ParaCodec: ICodec;
	out ParaTheir: THandshakeMsg;
	out ParaSuperior: Boolean
): TPeerError;
var
	vMsgId: TMsgId;
	vSecret: TBytes;
	vOur: THandshakeMsg;
begin
	Result := peNoError;
	ParaSuperior := False;
	ParaCodec := mCodecFactory.CreateCodec(ParaConn);

	if BannedAddr(ParaConn.RemoteAddr) then
	begin
		Result := peBanned;
		Exit;
	end;

	try
		Result := ReadHandshake(ParaCodec, ParaTheir, vMsgId);
		if Result <> peNoError then
		begin
			BanAddr(ParaConn.RemoteAddr, 60);
			Exit;
		end;

		vSecret := GetSecret(ParaTheir.mID);
		Result := VerifyHandshake(ParaTheir, vSecret);
		if Result <> peNoError then
		begin
			BanAddr(ParaConn.RemoteAddr, 60);
			Exit;
		end;

		Result := DoHandshake(ParaCodec, pfInbound, ParaTheir);
		if Result <> peNoError then
		begin
			BanAddr(ParaConn.RemoteAddr, 60);
			Exit;
		end;

		if Assigned(mOnHandshaker) then
		begin
			ParaSuperior := mOnHandshaker(ParaCodec, pfOutbound, ParaTheir);
		end;

		vOur := MakeHandshake(vSecret);
		SendHandshake(ParaCodec, vOur, vMsgId);
	except
		on E: EPeerError do
		begin
			Result := E.Error;
			BanAddr(ParaConn.RemoteAddr, 60);
		end;
		on E: Exception do
		begin
			Result := peUnknownError;
			BanAddr(ParaConn.RemoteAddr, 60);
		end;
	end;
end;

function THandshaker.InitiateHandshake(
	ParaConn: IConn;
	ParaId: TNodeID;
	out ParaCodec: ICodec;
	out ParaTheir: THandshakeMsg;
	out ParaSuperior: Boolean
): TPeerError;
var
	vSecret: TBytes;
	vOur: THandshakeMsg;
	vMsgId: TMsgId;
begin
	Result := peNoError;
	ParaSuperior := False;
	ParaCodec := mCodecFactory.CreateCodec(ParaConn);

	try
		vSecret := GetSecret(ParaId);

		vOur := MakeHandshake(vSecret);
		SendHandshake(ParaCodec, vOur, 0);

		Result := ReadHandshake(ParaCodec, ParaTheir, vMsgId);
		if Result <> peNoError then
		begin
			mBlackList.Ban(ParaId.Bytes, 60);
			Exit;
		end;

		Result := VerifyHandshake(ParaTheir, vSecret);
		if Result <> peNoError then
		begin
			mBlackList.Ban(ParaId.Bytes, 60);
			Exit;
		end;

		Result := DoHandshake(ParaCodec, pfOutbound, ParaTheir);
		if Result <> peNoError then
		begin
			mBlackList.Ban(ParaId.Bytes, 60);
			Exit;
		end;

		if Assigned(mOnHandshaker) then
		begin
			ParaSuperior := mOnHandshaker(ParaCodec, pfOutbound, ParaTheir);
		end;
	except
		on E: EPeerError do
		begin
			Result := E.Error;
			mBlackList.Ban(ParaId.Bytes, 60);
		end;
		on E: Exception do
		begin
			Result := peUnknownError;
			mBlackList.Ban(ParaId.Bytes, 60);
		end;
	end;
end;

function THandshaker.DoHandshake(ParaCodec: ICodec; ParaFlag: TPeerFlag; ParaTheir: THandshakeMsg): TPeerError;
begin
	Result := peNoError;
	if ParaTheir.mNetID <> mNetId then
	begin
		Result := peDifferentNetwork;
		Exit;
	end;

	if not ParaTheir.mGenesis.IsEqual(mGenesis) then
	begin
		Result := peDifferentGenesis;
		Exit;
	end;
end;

end.
