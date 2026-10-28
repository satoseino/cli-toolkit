# Personal CLI Toolkit

Various CLI programs that aid my own workflows.

## Installation

With [Homebrew](https://brew.sh) (macOS and Linux), one formula installs all four binaries below, plus bash, zsh and fish completions for `toolkit`:

```bash
brew install satoseino/tap/cli-toolkit
```

Restart the shell after the first install so the completions load. zsh picks them up only if `$(brew --prefix)/share/zsh/site-functions` is on `FPATH` before `compinit` runs. bash needs `bash-completion@2` installed and sourced. fish needs nothing.

Alternatively, install each binary with `go install`, as shown below. This doesn't install any completions.

- `toolkit` provides starter templates for Go, Python or AWS CDK projects.

  ```bash
  go install github.com/satoseino/cli-toolkit/cmd/toolkit@latest
  ```

- `toolkit-assume-role` performs the AWS CLI credential process.
  It only works on macOS and Linux because it needs to read and write `/dev/tty`.

  ```bash
  go install github.com/satoseino/cli-toolkit/cmd/toolkit-assume-role@latest
  ```

- `toolkit-show-md` takes a Markdown file, converts it to a GitHub style HTML and displays the HTML in user's default browser.

  ```bash
  go install github.com/satoseino/cli-toolkit/cmd/toolkit-show-md@latest
  ```

- `toolkit-serve-static` provides a local server of static websites. It can be used together with
  [air-verse/air](https://github.com/air-verse/air) to add live-reload capability to the server.

  ```bash
  go install github.com/satoseino/cli-toolkit/cmd/toolkit-serve-static@latest
  ```

## Version

`toolkit --version` (or `-V`) prints the installed version. The other three binaries take `-version`, e.g. `toolkit-assume-role -version`, and print it to stderr.
