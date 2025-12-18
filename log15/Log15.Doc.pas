unit Log15.Doc;

interface

{
	Package log15 provides an opinionated, simple toolkit for best-practice logging that is
	both human and machine readable. It is modeled after the standard library's io and net/http
	packages.

	This package enforces you to only log key/value pairs. Keys must be strings. Values may be
	any type that you like. The default output format is logfmt, but you may also choose to use
	JSON instead if that suits you. Here's how you log:

			log.Info("page accessed", "path", r.URL.Path, "user_id", user.id)

	This will output chain line that looks like:

			 lvl=info t=2014-05-02T16:07:23-0700 msg="page accessed" path=/org/71/profile user_id=9
}

implementation

end.
