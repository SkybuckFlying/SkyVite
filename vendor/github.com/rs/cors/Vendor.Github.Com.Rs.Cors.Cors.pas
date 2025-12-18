unit Vendor.Github.Com.Rs.Cors.Cors;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	Vendor.Github.Com.Rs.Cors.Utils;

type
	// Stubs for net/http types
	IHeader = interface
		['{4E534845-4144-4552-2D49-4E54-4620-20202020}']
		procedure Add( const ParaKey, ParaValue : string );
		procedure SetValue( const ParaKey, ParaValue : string );
		function Get( const ParaKey : string ) : string;
	end;

	IResponseWriter = interface
		['{4E535245-5350-5752-4954-4552-2D49-4E54-46}']
		function Header : IHeader;
		procedure WriteHeader( ParaStatusCode : Integer );
	end;

	IRequest = interface
		['{4E535245-5155-4553-542D-494E-5446-20202020}']
		function Method : string;
		function Header : IHeader;
	end;

	ILogger = interface
		['{4E534C4F-4747-4552-2D49-4E54-4620-20202020}']
		procedure Printf( const ParaFormat : string; const ParaArgs : array of const );
	end;

	TOptions = record
		AllowedOrigins         : TArray<string>;
		AllowOriginFunc        : reference to function( const ParaOrigin : string ) : Boolean;
		AllowOriginRequestFunc : reference to function( ParaR : IRequest; const ParaOrigin : string ) : Boolean;
		AllowedMethods         : TArray<string>;
		AllowedHeaders         : TArray<string>;
		ExposedHeaders         : TArray<string>;
		MaxAge                 : Integer;
		AllowCredentials       : Boolean;
		OptionsPassthrough     : Boolean;
		Debug                  : Boolean;
	end;

	TCors = class
	private
		mLog                   : ILogger;
		mAllowedOrigins        : TArray<string>;
		mAllowedWOrigins       : TArray<TWildcard>;
		mAllowOriginFunc       : reference to function( const ParaOrigin : string ) : Boolean;
		mAllowOriginRequestFunc : reference to function( ParaR : IRequest; const ParaOrigin : string ) : Boolean;
		mAllowedHeaders        : TArray<string>;
		mAllowedMethods        : TArray<string>;
		mExposedHeaders        : TArray<string>;
		mMaxAge                : Integer;
		mAllowedOriginsAll     : Boolean;
		mAllowedHeadersAll     : Boolean;
		mAllowCredentials      : Boolean;
		mOptionPassthrough     : Boolean;

		procedure Logf( const ParaFormat : string; const ParaArgs : array of const );
		function IsOriginAllowed( ParaR : IRequest; const ParaOrigin : string ) : Boolean;
		function IsMethodAllowed( const ParaMethod : string ) : Boolean;
		function AreHeadersAllowed( const ParaRequestedHeaders : TArray<string> ) : Boolean;
		procedure HandlePreflight( ParaW : IResponseWriter; ParaR : IRequest );
		procedure HandleActualRequest( ParaW : IResponseWriter; ParaR : IRequest );
	public
		constructor Create( const ParaOptions : TOptions );
		
		class function New( const ParaOptions : TOptions ) : TCors;
		class function Default : TCors;
		class function AllowAll : TCors;

		procedure HandlerFunc( ParaW : IResponseWriter; ParaR : IRequest );
	end;

implementation

{ TCors }

constructor TCors.Create( const ParaOptions : TOptions );
var
	vOrigin : string;
	vH      : string;
	vI      : Integer;
	vW      : TWildcard;
begin
	inherited Create;
	mExposedHeaders := ParaOptions.ExposedHeaders; // Simplified: usually canonicalized
	mAllowOriginFunc := ParaOptions.AllowOriginFunc;
	mAllowOriginRequestFunc := ParaOptions.AllowOriginRequestFunc;
	mAllowCredentials := ParaOptions.AllowCredentials;
	mMaxAge := ParaOptions.MaxAge;
	mOptionPassthrough := ParaOptions.OptionsPassthrough;

	if ParaOptions.Debug then
	begin
		// In a real app, mLog would be assigned here
	end;

	// Allowed Origins
	if Length( ParaOptions.AllowedOrigins ) = 0 then
	begin
		if ( not Assigned( mAllowOriginFunc ) ) and ( not Assigned( mAllowOriginRequestFunc ) ) then
			mAllowedOriginsAll := True;
	end
	else
	begin
		for vOrigin in ParaOptions.AllowedOrigins do
		begin
			vOrigin := vOrigin.ToLower;
			if vOrigin = '*' then
			begin
				mAllowedOriginsAll := True;
				mAllowedOrigins := nil;
				mAllowedWOrigins := nil;
				break;
			end
			else if vOrigin.Contains( '*' ) then
			begin
				vI := Pos( '*', vOrigin );
				vW.Prefix := Copy( vOrigin, 1, vI - 1 );
				vW.Suffix := Copy( vOrigin, vI + 1, MaxInt );
				SetLength( mAllowedWOrigins, Length( mAllowedWOrigins ) + 1 );
				mAllowedWOrigins[ High( mAllowedWOrigins ) ] := vW;
			end
			else
			begin
				SetLength( mAllowedOrigins, Length( mAllowedOrigins ) + 1 );
				mAllowedOrigins[ High( mAllowedOrigins ) ] := vOrigin;
			end;
		end;
	end;

	// Allowed Headers
	if Length( ParaOptions.AllowedHeaders ) = 0 then
	begin
		mAllowedHeaders := [ 'Origin', 'Accept', 'Content-Type', 'X-Requested-With' ];
	end
	else
	begin
		mAllowedHeaders := ParaOptions.AllowedHeaders;
		for vH in ParaOptions.AllowedHeaders do
		begin
			if vH = '*' then
			begin
				mAllowedHeadersAll := True;
				mAllowedHeaders := nil;
				break;
			end;
		end;
	end;

	// Allowed Methods
	if Length( ParaOptions.AllowedMethods ) = 0 then
	begin
		mAllowedMethods := [ 'GET', 'POST', 'HEAD' ];
	end
	else
	begin
		mAllowedMethods := ParaOptions.AllowedMethods;
		for vI := 0 to High( mAllowedMethods ) do
			mAllowedMethods[ vI ] := mAllowedMethods[ vI ].ToUpper;
	end;
end;

class function TCors.New( const ParaOptions : TOptions ) : TCors;
begin
	Result := TCors.Create( ParaOptions );
end;

class function TCors.Default : TCors;
var
	vOpts : TOptions;
begin
	FillChar( vOpts, SizeOf( vOpts ), 0 );
	Result := TCors.New( vOpts );
end;

class function TCors.AllowAll : TCors;
var
	vOpts : TOptions;
begin
	FillChar( vOpts, SizeOf( vOpts ), 0 );
	vOpts.AllowedOrigins := [ '*' ];
	vOpts.AllowedMethods := [ 'HEAD', 'GET', 'POST', 'PUT', 'PATCH', 'DELETE' ];
	vOpts.AllowedHeaders := [ '*' ];
	vOpts.AllowCredentials := False;
	Result := TCors.New( vOpts );
end;

procedure TCors.Logf( const ParaFormat : string; const ParaArgs : array of const );
begin
	if Assigned( mLog ) then
		mLog.Printf( ParaFormat, ParaArgs );
end;

function TCors.IsOriginAllowed( ParaR : IRequest; const ParaOrigin : string ) : Boolean;
var
	vO : string;
	vW : TWildcard;
	vLowOrigin : string;
begin
	if Assigned( mAllowOriginRequestFunc ) then
		Exit( mAllowOriginRequestFunc( ParaR, ParaOrigin ) );
	if Assigned( mAllowOriginFunc ) then
		Exit( mAllowOriginFunc( ParaOrigin ) );
	if mAllowedOriginsAll then
		Exit( True );
	
	vLowOrigin := ParaOrigin.ToLower;
	for vO in mAllowedOrigins do
		if vO = vLowOrigin then
			Exit( True );
	
	for vW in mAllowedWOrigins do
		if vW.Match( vLowOrigin ) then
			Exit( True );
	
	Result := False;
end;

function TCors.IsMethodAllowed( const ParaMethod : string ) : Boolean;
var
	vM : string;
	vUpperMethod : string;
begin
	if Length( mAllowedMethods ) = 0 then
		Exit( False );
	
	vUpperMethod := ParaMethod.ToUpper;
	if vUpperMethod = 'OPTIONS' then
		Exit( True );
	
	for vM in mAllowedMethods do
		if vM = vUpperMethod then
			Exit( True );
	
	Result := False;
end;

function TCors.AreHeadersAllowed( const ParaRequestedHeaders : TArray<string> ) : Boolean;
var
	vH, vAh : string;
	vFound  : Boolean;
begin
	if mAllowedHeadersAll or ( Length( ParaRequestedHeaders ) = 0 ) then
		Exit( True );
	
	for vH in ParaRequestedHeaders do
	begin
		vFound := False;
		for vAh in mAllowedHeaders do
		begin
			if vAh.ToLower = vH.ToLower then // Simplified heuristic
			begin
				vFound := True;
				break;
			end;
		end;
		if not vFound then
			Exit( False );
	end;
	Result := True;
end;

procedure TCors.HandlePreflight( ParaW : IResponseWriter; ParaR : IRequest );
var
	vHeaders : IHeader;
	vOrigin  : string;
	vReqMethod : string;
	vReqHeaders : TArray<string>;
begin
	vHeaders := ParaW.Header;
	vOrigin := ParaR.Header.Get( 'Origin' );

	if ParaR.Method <> 'OPTIONS' then
		Exit;
	
	vHeaders.Add( 'Vary', 'Origin' );
	vHeaders.Add( 'Vary', 'Access-Control-Request-Method' );
	vHeaders.Add( 'Vary', 'Access-Control-Request-Headers' );

	if vOrigin = '' then
		Exit;
	
	if not IsOriginAllowed( ParaR, vOrigin ) then
		Exit;
	
	vReqMethod := ParaR.Header.Get( 'Access-Control-Request-Method' );
	if not IsMethodAllowed( vReqMethod ) then
		Exit;
	
	vReqHeaders := ParseHeaderList( ParaR.Header.Get( 'Access-Control-Request-Headers' ) );
	if not AreHeadersAllowed( vReqHeaders ) then
		Exit;
	
	if mAllowedOriginsAll then
		vHeaders.SetValue( 'Access-Control-Allow-Origin', '*' )
	else
		vHeaders.SetValue( 'Access-Control-Allow-Origin', vOrigin );
	
	vHeaders.SetValue( 'Access-Control-Allow-Methods', vReqMethod.ToUpper );
	if Length( vReqHeaders ) > 0 then
		vHeaders.SetValue( 'Access-Control-Allow-Headers', string.Join( ', ', vReqHeaders ) );
	
	if mAllowCredentials then
		vHeaders.SetValue( 'Access-Control-Allow-Credentials', 'true' );
	
	if mMaxAge > 0 then
		vHeaders.SetValue( 'Access-Control-Max-Age', IntToStr( mMaxAge ) );
end;

procedure TCors.HandleActualRequest( ParaW : IResponseWriter; ParaR : IRequest );
var
	vHeaders : IHeader;
	vOrigin  : string;
begin
	vHeaders := ParaW.Header;
	vOrigin := ParaR.Header.Get( 'Origin' );

	vHeaders.Add( 'Vary', 'Origin' );
	if vOrigin = '' then
		Exit;
	
	if not IsOriginAllowed( ParaR, vOrigin ) then
		Exit;
	
	if not IsMethodAllowed( ParaR.Method ) then
		Exit;
	
	if mAllowedOriginsAll then
		vHeaders.SetValue( 'Access-Control-Allow-Origin', '*' )
	else
		vHeaders.SetValue( 'Access-Control-Allow-Origin', vOrigin );
	
	if Length( mExposedHeaders ) > 0 then
		vHeaders.SetValue( 'Access-Control-Expose-Headers', string.Join( ', ', mExposedHeaders ) );
	
	if mAllowCredentials then
		vHeaders.SetValue( 'Access-Control-Allow-Credentials', 'true' );
end;

procedure TCors.HandlerFunc( ParaW : IResponseWriter; ParaR : IRequest );
begin
	if ( ParaR.Method = 'OPTIONS' ) and ( ParaR.Header.Get( 'Access-Control-Request-Method' ) <> '' ) then
	begin
		HandlePreflight( ParaW, ParaR );
		if not mOptionPassthrough then
			ParaW.WriteHeader( 204 ); // StatusNoContent
	end
	else
	begin
		HandleActualRequest( ParaW, ParaR );
	end;
end;

end.
