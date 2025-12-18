unit Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface;

interface

uses
	System.Classes,
	System.SysUtils;

type
	ILRUCache = interface
		['{C93F1D1E-109E-4F8B-BA7C-402877D41E24}']
		function Add( ParaKey, ParaValue : TObject ) : Boolean;
		function Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Contains( ParaKey : TObject ) : Boolean;
		function Peek( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Remove( ParaKey : TObject ) : Boolean;
		function RemoveOldest( out ParaKey, ParaValue : TObject ) : Boolean;
		function GetOldest( out ParaKey, ParaValue : TObject ) : Boolean;
		function Keys : TArray<TObject>;
		function Len : Integer;
		procedure Purge;
		function Resize( ParaSize : Integer ) : Integer;
	end;

implementation

end.
