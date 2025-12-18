unit Cmd.Utils.Cli;

interface

uses
  Cli,
  Cmd.Utils.Customflags,
  Cmd.Utils.Customflags.Test,
  Cmd.Utils.Flags,
  Cmd.Utils.Path;

implementation

const
	ConstCommandHelpTemplate =
		'{{.cmd.Name}}{{if .cmd.Subcommands}} command{{end}}{{if .cmd.Flags}} [command options]{{end}} [arguments...]' +
		'{{if .cmd.Description}}{{.cmd.Description}}' +
		'{{end}}{{if .cmd.Subcommands}}' +
		'SUBCOMMANDS:' +
		'	{{range .cmd.Subcommands}}{{.Name}}{{with .ShortName}}, {{.}}{{end}}{{ "	" }}{{.Usage}}' +
		'	{{end}}{{end}}{{if .categorizedFlags}}' +
		'{{range $idx, $categorized := .categorizedFlags}}{{$categorized.Name}} OPTIONS:' +
		'{{range $categorized.Flags}}{{"	"}}{{.}}' +
		'{{end}}' +
		'{{end}}{{end}}';

	ConstAppHelpTemplate =
		'{{.Name}} {{if .Flags}}[global options] {{end}}command{{if .Flags}} [command options]{{end}} [arguments...]' +
		'' +
		'VERSION:' +
		'   {{.Version}}' +
		'' +
		'COMMANDS:' +
		'   {{range .Commands}}{{.Name}}{{with .ShortName}}, {{.}}{{end}}{{ "	" }}{{.Usage}}' +
		'   {{end}}{{if .Flags}}' +
		'GLOBAL OPTIONS:' +
		'   {{range .Flags}}{{.}}' +
		'   {{end}}{{end}}';

initialization
	Tcli.AppHelpTemplate := ConstAppHelpTemplate;
	Tcli.CommandHelpTemplate := ConstCommandHelpTemplate;

end.
