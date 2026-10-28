package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/satoseino/cli-toolkit/version"
)

var (
	port        string
	showVersion bool
	logger      = log.New(os.Stderr, "toolkit-serve-static: ", 0)
	helpMsg     = `Usage: %s [flags] <DIR>

Serve static contents from the <DIR> folder.

Arguments:
  <DIR>    Directory that contains the static contents.

Flags:
`
)

func main() {
	flag.StringVar(&port, "port", "8090", "HTTP port of the local static files server.")
	flag.BoolVar(&showVersion, "version", false, "Print the version and exit.")

	flag.Usage = func() {
		_, _ = fmt.Fprintf(flag.CommandLine.Output(), helpMsg, os.Args[0])

		flag.PrintDefaults()
	}

	flag.Parse()

	if showVersion {
		_, _ = fmt.Fprintln(flag.CommandLine.Output(), version.String())

		return
	}

	args := flag.Args()
	if len(args) == 0 {
		logger.Fatalf("The <DIR> argument is required.")
	}

	staticDir := args[0]

	logger.Fatal(http.ListenAndServe(":"+port, http.FileServer(http.Dir(staticDir))))
}
