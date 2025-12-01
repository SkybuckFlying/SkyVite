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
unit net.skeleton;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections,
	System.Diagnostics,
	System.Threading,
	common.types,
	net.peer,
	net.message,
	common.db.xleveldb.errors,
	interfaces.core;

const
	GetHashHeightListTimeout = 10 * 1000; // 10 seconds in milliseconds

var
	errTimeout: TObject;

type
	THashHeightPeers = record
		mHashHeightPoint: THashHeightPoint;
		mPeers: TDictionary<string, TPeer>;
	end;

	THashHeightNode = class
	private
		mHashHeightPeers: THashHeightPeers;
		mNodes: TDictionary<THash, THashHeightNode>;
	public
		constructor Create;
		destructor Destroy; override;
		procedure AddBranch(ParaList: TArray<THashHeightPoint>; ParaSender: TPeer);
		function BestBranch: TArray<THashHeightPoint>;
	end;

	TPending = class
	private
		mWaitGroup: TSimpleRWSync;
		mTree: THashHeightNode;
	public
		procedure Done(ParaMessage: TMessage; ParaSender: TPeer; ParaError: TObject);
	end;

	TSkeleton = class
	private
		mChecking: Integer;
		mTree: THashHeightNode;
		mBlackBlocks: TDictionary<THash, Boolean>;
		mPeers: TPeerSet;
		mIdGen: TMessageIdGenerator;
		mMutex: TCriticalSection;
		mPending: TDictionary<TMessageId, TPeer>;
		mWaitGroup: TSimpleRWSync;
		procedure GetHashList(ParaPeer: TPeer; ParaMessage: TGetHashHeightList);
		procedure GetHashListFailed(ParaId: TMessageId; ParaSender: TPeer; ParaError: TObject);
		procedure RemovePending(ParaId: TMessageId);
	public
		constructor Create(ParaPeers: TPeerSet; ParaIdGen: TMessageIdGenerator; ParaBlackBlocks: TDictionary<THash, Boolean>);
		destructor Destroy; override;
		function Construct(ParaStart: TArray<IHashHeight>; ParaEnd: UInt64): TArray<THashHeightPoint>;
		procedure ReceiveHashList(ParaMessage: TMessage; ParaSender: TPeer);
		procedure Reset;
	end;

implementation

{ THashHeightNode }

constructor THashHeightNode.Create;
begin
	inherited Create;
	mNodes := TDictionary<THash, THashHeightNode>.Create;
	mHashHeightPeers.mPeers := TDictionary<string, TPeer>.Create;
end;

destructor THashHeightNode.Destroy;
var
	vNode: THashHeightNode;
begin
	for vNode in mNodes.Values do
	begin
		vNode.Free;
	end;
	mNodes.Free;
	mHashHeightPeers.mPeers.Free;
	inherited Destroy;
end;

procedure THashHeightNode.AddBranch(ParaList: TArray<THashHeightPoint>; ParaSender: TPeer);
var
	vTree: THashHeightNode;
	vSubTree: THashHeightNode;
	vOk: Boolean;
	vHashHeight: THashHeightPoint;
begin
	vTree := Self;
	for vHashHeight in ParaList do
	begin
		vOk := vTree.mNodes.TryGetValue(vHashHeight.Hash, vSubTree);
		if vOk then
		begin
			vSubTree.mHashHeightPeers.mPeers.AddOrSetValue(ParaSender.Id, ParaSender);
		end
		else
		begin
			vSubTree := THashHeightNode.Create;
			vSubTree.mHashHeightPeers.mHashHeightPoint := vHashHeight;
			vSubTree.mHashHeightPeers.mPeers.Add(ParaSender.Id, ParaSender);
			vTree.mNodes.Add(vHashHeight.Hash, vSubTree);
		end;
		vTree := vSubTree;
	end;
end;

function THashHeightNode.BestBranch: TArray<THashHeightPoint>;
var
	vTree: THashHeightNode;
	vSubTree: THashHeightNode;
	vWeight: Integer;
	vNode: THashHeightNode;
	vList: TList<THashHeightPoint>;
begin
	vList := TList<THashHeightPoint>.Create;
	try
		vTree := Self;
		while True do
		begin
			if (vTree = nil) or (vTree.mNodes.Count = 0) then
			begin
				Break;
			end;

			vWeight := 0;
			vSubTree := nil;

			for vNode in vTree.mNodes.Values do
			begin
				if vNode.mHashHeightPeers.mPeers.Count > vWeight then
				begin
					vWeight := vNode.mHashHeightPeers.mPeers.Count;
					vSubTree := vNode;
				end;
			end;

			if vSubTree <> nil then
			begin
				vList.Add(vSubTree.mHashHeightPeers.mHashHeightPoint);
				vTree := vSubTree;
			end
			else
			begin
				Break;
			end;
		end;
		Result := vList.ToArray;
	finally
		vList.Free;
	end;
end;

{ TPending }

procedure TPending.Done(ParaMessage: TMessage; ParaSender: TPeer; ParaError: TObject);
var
	vHashHeightList: THashHeightPointList;
	vError: TObject;
begin
	mWaitGroup.EndWrite;
	if ParaError <> nil then
	begin
		// netLog.Warn(fmt.Sprintf("failed to get HashHeight list from %s: %v", sender, err))
	end
	else
	begin
		vHashHeightList := THashHeightPointList.Create;
		try
			vError := vHashHeightList.Deserialize(ParaMessage.Payload);
			if vError <> nil then
			begin
				Exit;
			end;
			mTree.AddBranch(vHashHeightList.Points, ParaSender);
		finally
			vHashHeightList.Free;
		end;
	end;
end;

{ TSkeleton }

constructor TSkeleton.Create(ParaPeers: TPeerSet; ParaIdGen: TMessageIdGenerator; ParaBlackBlocks: TDictionary<THash, Boolean>);
begin
	inherited Create;
	mPeers := ParaPeers;
	mIdGen := ParaIdGen;
	mPending := TDictionary<TMessageId, TPeer>.Create;
	mBlackBlocks := ParaBlackBlocks;
	mMutex := TCriticalSection.Create;
	mWaitGroup := TSimpleRWSync.Create;
end;

destructor TSkeleton.Destroy;
begin
	mPending.Free;
	mMutex.Free;
	mWaitGroup.Free;
	if mTree <> nil then
	begin
		mTree.Free;
	end;
	inherited Destroy;
end;

function TSkeleton.Construct(ParaStart: TArray<IHashHeight>; ParaEnd: UInt64): TArray<THashHeightPoint>;
var
	vPeers: TArray<TPeer>;
	vMessage: TGetHashHeightList;
	vPeer: TPeer;
begin
	if TInterlocked.CompareExchange(mChecking, 1, 0) <> 0 then
	begin
		// netLog.Warn(fmt.Sprintf("skeleton is checking"))
		Exit;
	end;
	try
		mTree := THashHeightNode.Create;
		vPeers := mPeers.PickReliable(ParaEnd);
		if Length(vPeers) > 0 then
		begin
			vMessage := TGetHashHeightList.Create;
			vMessage.From := ParaStart;
			vMessage.Step := syncTaskSize;
			vMessage.To := ParaEnd;

			if Length(vPeers) > 10 then
			begin
				SetLength(vPeers, 10);
			end;

			for vPeer in vPeers do
			begin
				mWaitGroup.BeginWrite;
				GetHashList(vPeer, vMessage);
			end;
		end;

		mWaitGroup.BeginRead;
		mWaitGroup.EndRead;

		mMutex.Enter;
		try
			Result := mTree.BestBranch;
		finally
			mMutex.Leave;
		end;
	finally
		TInterlocked.Exchange(mChecking, 0);
	end;
end;

procedure TSkeleton.GetHashList(ParaPeer: TPeer; ParaMessage: TGetHashHeightList);
var
	vMessageId: TMessageId;
	vError: TObject;
begin
	vMessageId := mIdGen.MsgID;
	vError := ParaPeer.Send(TCodeGetHashList, vMessageId, ParaMessage);
	if vError <> nil then
	begin
		mWaitGroup.EndWrite;
		ParaPeer.Catch(vError);
	end
	else
	begin
		mMutex.Enter;
		try
			mPending.Add(vMessageId, ParaPeer);
		finally
			mMutex.Leave;
		end;

		TTask.Run(procedure
		begin
			TThread.Sleep(GetHashHeightListTimeout);
			GetHashListFailed(vMessageId, ParaPeer, errTimeout);
		end);
	end;
end;

procedure TSkeleton.ReceiveHashList(ParaMessage: TMessage; ParaSender: TPeer);
var
	vHashHeightList: THashHeightPointList;
	vError: TObject;
	vPoint: THashHeightPoint;
	vValue: Boolean;
begin
	if TInterlocked.Read(mChecking) = 1 then
	begin
		vHashHeightList := THashHeightPointList.Create;
		try
			vError := vHashHeightList.Deserialize(ParaMessage.Payload);
			if vError <> nil then
			begin
				GetHashListFailed(ParaMessage.Id, ParaSender, vError);
				Exit;
			end;

			RemovePending(ParaMessage.Id);

			if mBlackBlocks.Count > 0 then
			begin
				for vPoint in vHashHeightList.Points do
				begin
					if mBlackBlocks.TryGetValue(vPoint.Hash, vValue) then
					begin
						ParaSender.SetReliable(False);
						Exit;
					end;
				end;
			end;

			mMutex.Enter;
			try
				mTree.AddBranch(vHashHeightList.Points, ParaSender);
			finally
				mMutex.Leave;
			end;
		finally
			vHashHeightList.Free;
		end;
	end;
end;

procedure TSkeleton.GetHashListFailed(ParaId: TMessageId; ParaSender: TPeer; ParaError: TObject);
begin
	RemovePending(ParaId);
	// netLog.Warn(fmt.Sprintf("failed to get HashHeight list from %s: %v", sender, err))
end;

procedure TSkeleton.RemovePending(ParaId: TMessageId);
var
	vPeer: TPeer;
begin
	mMutex.Enter;
	try
		if mPending.TryGetValue(ParaId, vPeer) then
		begin
			mPending.Remove(ParaId);
			mWaitGroup.EndWrite;
			// todo handle response error
		end;
	finally
		mMutex.Leave;
	end;
end;

procedure TSkeleton.Reset;
var
	vId: TMessageId;
begin
	mMutex.Enter;
	try
		for vId in mPending.Keys do
		begin
			mPending.Remove(vId);
			mWaitGroup.EndWrite;
		end;
		mPending.Clear;
		if mTree <> nil then
		begin
			mTree.Free;
			mTree := nil;
		end;
		mTree := THashHeightNode.Create;
	finally
		mMutex.Leave;
	end;
end;

initialization
	errTimeout := Exception.Create('timeout');

finalization
	errTimeout.Free;

end.
