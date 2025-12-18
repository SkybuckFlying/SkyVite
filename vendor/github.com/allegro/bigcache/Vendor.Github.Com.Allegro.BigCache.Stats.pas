unit Vendor.Github.Com.Allegro.BigCache.Stats;

interface

type
	TStats = record
	public
		mHits       : Int64;
		mMisses     : Int64;
		mDelHits    : Int64;
		mDelMisses  : Int64;
		mCollisions : Int64;
	end;

implementation

end.
