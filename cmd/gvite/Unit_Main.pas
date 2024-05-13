unit Unit_Main;

interface

procedure Main;

implementation

//uses
//  net_http_pprof,
//  github_com_vitelabs_go_vite_v2_cmd_gvite_plugins,
//  github_com_vitelabs_go_vite_v2_version;

uses
	unit_govite,
	unit_load_plugins;

// gvite is the official command-line client for SkyVite

procedure Main;
begin
  PrintBuildVersion;
  Loading;
end;

end.
