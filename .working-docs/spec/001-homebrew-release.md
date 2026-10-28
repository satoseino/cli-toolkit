# Release the toolkit binaries to `satoseino/homebrew-tap` (GoReleaser, version flags, `toolkit` shell completions)

## Background

The four user-facing binaries (`toolkit`, `toolkit-assume-role`, `toolkit-show-md`, `toolkit-serve-static`) install only through `go install`. None of them has a version flag, and there is no release config. `gelato` already publishes to the same tap. Its `.goreleaser.yaml` (`brews:` → `satoseino/homebrew-tap`, `directory: Formula`, `skip_upload: auto`, `extra_install: prefix.install "THIRD_PARTY_LICENSES"`) and `.github/workflows/release.yaml` (tag `v*` → `goreleaser-action@v7`, `version: "~> v2"`, `HOMEBREW_TAP_TOKEN`) are the template. `jarvis-registry-cli` ships hand-written completion scripts through the same mechanism:

```yaml
extra_install: |
  bash_completion.install "completions/jarvis-registry.bash" => "jarvis-registry"
  zsh_completion.install "completions/jarvis-registry.zsh" => "_jarvis-registry"
  fish_completion.install "completions/jarvis-registry.fish"
```

`toolkit-tui` is not shipped.

Facts that shaped the design:

- **One archive per platform holding all four binaries yields a single formula that installs all four.** A snapshot run with GoReleaser 2.19 and four `builds` ids plus one default archive generated `bin.install` for each binary, followed by the `extra_install` lines. The brew pipe rejects more than one archive per OS/arch, so one formula requires one archive.
- **`CGO_ENABLED=0` is safe.** `zalando/go-keyring` v0.2.6 on darwin shells out to `/usr/bin/security` (`keyring_darwin.go`: `execPathKeychain = "/usr/bin/security"`), and on Linux it uses pure-Go D-Bus. All four binaries cross-build for darwin/linux × amd64/arm64 with `CGO_ENABLED=0`.
- **`toolkit-assume-role` opens `/dev/tty` before `flag.Parse()`.** With no controlling terminal (e.g. a CI runner), it exits 1 before reading any flag. A version flag must be handled before the tty is opened.
- **`LICENSE` is the Unlicense** (SPDX `Unlicense`). The linked modules include Apache-2.0 ones (`aws-sdk-go-v2`, `smithy-go`, which ship `NOTICE` files), MIT and BSD ones, and the Go standard library, so the archive needs a `THIRD_PARTY_LICENSES` file, as gelato's does.

---

## Changes

### 1. `version` package (new)

```go
// Package version reports the version of the running toolkit binary.
package version

// devVersion is the version of a build with neither a stamped version nor a
// usable module version in its build info.
const devVersion = "dev"

// stamped is set at release time with
// -ldflags "-X github.com/satoseino/cli-toolkit/version.stamped=...".
var stamped = devVersion

// String returns the stamped release version, or, for builds without one
// (go install), the main module version from the build info, or "dev".
func String() string
```

The logic is gelato's `resolveVersion`, moved into one place: an unexported `resolve(stamped string, info *debug.BuildInfo, ok bool) string` that ignores `(devel)`. One `-X` target serves all four builds, so no binary needs its own `main.version`. This package owns real behavior, so it satisfies the no-organizational-packages rule. `version_test.go` covers `resolve` with a table: stamped wins, fallback to `Main.Version`, `(devel)` ignored, `!ok`.

### 2. `cmd/toolkit/main.go`

Add `Version kong.VersionFlag \`short:"V" help:"Print the version and exit."\`` (gelato's flag) to the `cli` struct and `kong.Vars{"version": version.String()}` to the `kong.Parse` options.

### 3. `cmd/toolkit-{assume-role,show-md,serve-static}/main.go`

- Add a bool flag `-version`, spelled single-dash everywhere (help, README, formula test), in line with these binaries' existing style (`helpMsg`'s `-mfa-serial=STRING`, `PrintDefaults`' `-port`). Right after `flag.Parse()`, before any argument or input validation (`<RoleArn>`, `<PATH>`, `<DIR>`), print `version.String()` to `flag.CommandLine.Output()` (stderr, the same destination as `-h`) and exit 0. For `toolkit-assume-role` this keeps stdout credential-only, as CLAUDE.md requires.
- `toolkit-assume-role`: move `registerFlagsAndHelp()` and `flag.Parse()` ahead of the `/dev/tty` open, so `-version` is handled before the tty is opened. Parse errors already go to stderr, so their destination doesn't change.
- `toolkit-show-md`: its `flag.Usage` prints only `helpMsg` (no `PrintDefaults`), so add a `Flags:` section listing `-version` to `helpMsg` and change its usage line to `Usage: %s [flags] <PATH>`, as `toolkit-serve-static` has. The other two pick it up from `PrintDefaults`.

### 4. `completions/` (new top-level folder; non-Go assets)

`completions/toolkit.bash`, `completions/toolkit.zsh` and `completions/toolkit.fish` are written by hand in the style of `jarvis-registry-cli/completion/jarvis-registry.{bash,zsh,fish}`, without the `jr` alias or the `completion` subcommand. All three are ASCII, LF line endings, and end with a newline.

- Root: `start-ts-cdk-project`, `start-python-project` and `start-go-project`, described with the kong `help:` strings from `cmd/toolkit/main.go`, plus `-h/--help` and `-V/--version`.
- Each subcommand: `-h/--help` plus every flag of its `scaffold.*ProjectCmd` (`name:` tags in `scaffold/project.go`), with the `help:` text as the description in zsh and fish. Every scaffold flag takes a free-text value, and the positional `ModulePath`/`ProjectName` is free text, so nothing completes values or files: fish has `complete -c toolkit -f`, zsh uses `--flag[desc]:value: ` specs, and bash completes nothing after a value-taking flag.
- zsh keeps jarvis's `#compdef toolkit` and `funcstack` dispatch, so the file works both autoloaded as `_toolkit` and sourced.

There are no Go tests tying the completion scripts to the kong model. As in `jarvis-registry-cli`, the sync rule lives in CLAUDE.md (section 9).

### 5. `scripts/third-party-licenses.sh` (new; mode `100755`)

This is gelato's script with `./cmd/gelato` replaced by the four `./cmd/...` packages in a single `go list -deps` call. It collects `LICENSE*`/`COPYING*`/`NOTICE*` per module, which picks up `aws-sdk-go-v2`'s `NOTICE.txt` and `smithy-go`'s `NOTICE`, and fails when a module or GOROOT has no license file. Add `/THIRD_PARTY_LICENSES` to `.gitignore`; `dist/**/*` is already ignored.

### 6. `.goreleaser.yaml` (new; GoReleaser OSS, config `version: 2`)

- `before.hooks`: `go mod tidy`, `./scripts/third-party-licenses.sh`.
- `builds`: four entries, one each for `toolkit`, `toolkit-assume-role`, `toolkit-show-md` and `toolkit-serve-static`, with `id` and `binary` set to that name and `main: ./cmd/<name>`. Each has `env: [CGO_ENABLED=0]`, `goos: [darwin, linux]`, `goarch: [amd64, arm64]`, `ldflags: -s -w -X github.com/satoseino/cli-toolkit/version.stamped={{ .Version }}`. A YAML anchor may share the common keys. There is no Windows build: `toolkit-assume-role` needs `/dev/tty`, and Homebrew is macOS/Linux only.
- `archives`: one entry, `formats: [tar.gz]`, `files: [LICENSE, README.md, THIRD_PARTY_LICENSES, completions/*]`. `completions/` keeps its path inside the archive (checked with a snapshot in a scratch clone), which `extra_install` relies on.
- `checksum.name_template: checksums.txt`.
- `brews` (one entry, not `homebrew_casks`; see CLAUDE.md "Release and distribution"):
  - `name: cli-toolkit`, `repository: {owner: satoseino, name: homebrew-tap, token: "{{ .Env.HOMEBREW_TAP_TOKEN }}"}`, `directory: Formula`.
  - `homepage: https://github.com/satoseino/cli-toolkit`, `description: "Personal CLIs: project scaffolding, AWS credential_process, Markdown preview, static file server."`, `license: "Unlicense"`.
  - `skip_upload: auto`.
  - `extra_install`:
    ```ruby
    bash_completion.install "completions/toolkit.bash" => "toolkit"
    zsh_completion.install "completions/toolkit.zsh" => "_toolkit"
    fish_completion.install "completions/toolkit.fish"
    prefix.install "THIRD_PARTY_LICENSES"
    ```
  - `test` (stdout for kong, `2>&1` for the stderr ones):
    ```ruby
    assert_match version.to_s, shell_output("#{bin}/toolkit --version")
    assert_match version.to_s, shell_output("#{bin}/toolkit-assume-role -version 2>&1")
    assert_match version.to_s, shell_output("#{bin}/toolkit-show-md -version 2>&1")
    assert_match version.to_s, shell_output("#{bin}/toolkit-serve-static -version 2>&1")
    ```
- `brews` is deprecated, so each release logs a deprecation warning. That is expected.

### 7. `.github/workflows/release.yaml` (new)

The structure is gelato's: on `push` of tags `v*`, `permissions: contents: write`, checkout with `fetch-depth: 0`, then `goreleaser/goreleaser-action@v7` (`distribution: goreleaser`, `version: "~> v2"`, `args: release --clean`) with `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` and `HOMEBREW_TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}`. The checkout and setup-go versions (`actions/checkout@v7`, `actions/setup-go@v7`) and `go-version: "^1.25"` are copied from this repo's `test-and-lint.yaml`, so the shipped toolchain is the tested one.

**Prerequisite:** set the secret on this repository. As of 2026-10-28, `HOMEBREW_TAP_TOKEN` exists only on `satoseino/gelato`; `gh secret list --repo satoseino/cli-toolkit` is empty. The PAT's resource scope is `satoseino/homebrew-tap`, so the same token works from any source repository. GitHub can't reveal an existing secret's value, so if the token isn't saved elsewhere, regenerate it and update both repositories.

```bash
gh secret set HOMEBREW_TAP_TOKEN --repo satoseino/cli-toolkit   # prompts for the value
```

### 8. `README.md`

- Installation: `brew install satoseino/tap/cli-toolkit` (macOS and Linux) installs all four binaries plus `toolkit`'s bash/zsh/fish completions. Restart the shell after the first install. zsh loads them only when `$(brew --prefix)/share/zsh/site-functions` is on `FPATH` before `compinit`, and bash only with `bash-completion@2` installed and sourced; fish needs nothing. Keep the `go install` lines as the alternative, noting that they ship no completions.
- Mention `toolkit --version` and `-version` for the other three.

### 9. `CLAUDE.md`

- "Release and distribution": replace "GoReleaser integration is planned" with the facts: one `cli-toolkit` formula carries the four binaries; `toolkit-tui` is excluded; the tap token is the `HOMEBREW_TAP_TOKEN` secret, a fine-grained PAT limited to Contents read/write on `satoseino/homebrew-tap` (when it expires, releases publish but the tap update fails); `goreleaser-action` stays pinned to `"~> v2"` while `brews:` exists.
- `toolkit` subcommands, worded like `jarvis-registry-cli/CLAUDE.md`: nothing generates `completions/toolkit.{bash,zsh,fish}`, and they hard-code command and flag names, so any CLI surface change (subcommand or flag added, renamed or removed) must edit all three in the same change. Add this as a fourth item to the "pin a new tool in a scaffold" checklist, since every new `SemVer` flag is a new completion entry.
- Package layout: add `version` to the list of top-level packages.
- `tui` section: drop the sentence "`scripts/` holds throwaway dev-only `main` programs (`debug-tui`, `rename-files`) and is held to the same low bar." (section 10 deletes both). In its place, say that `scripts/` holds release tooling run by GoReleaser (`third-party-licenses.sh`), not Go code. Package layout's "or `scripts/`" (non-Go asset directories) stays accurate.

### 10. Remove `scripts/debug-tui/` and `scripts/rename-files/`

- Delete both directories. Nothing imports them, and `go build ./...` passes without them.
- `.golangci.yaml`: delete the three `linters.exclusions.rules` entries with `path: '^scripts/rename-files/main\.go$'` (gosec G703, G122, G706), which no longer match anything.
- `.gitignore`: delete `/messages.log`, the dump file only `debug-tui` writes.
- `go mod tidy`: `github.com/davecgh/go-spew` was a direct requirement only through `debug-tui`, so it moves to the `// indirect` block (testify still needs it). Commit the tidied `go.mod`, because the release's `go mod tidy` before hook (section 6) would otherwise change it during a release.

---

## What does NOT change

- `scaffold`, the kong lifecycle (`BeforeReset`/`AfterApply`/`Run`), `tui` and `cmd/toolkit-tui`. `toolkit` gets no `completion` subcommand.
- `test-and-lint.yaml`. No code signing, no Windows artifacts, no `homebrew_casks`.
- `homebrew-tap` is not edited by hand. GoReleaser commits `Formula/cli-toolkit.rb` on the first tag.

---

## Acceptance Criteria

- [ ] `HOMEBREW_TAP_TOKEN=unused goreleaser release --snapshot --clean` produces four archives (darwin, linux × amd64, arm64) and `checksums.txt`. Each archive contains the four binaries, `LICENSE`, `README.md`, `THIRD_PARTY_LICENSES` and `completions/toolkit.{bash,zsh,fish}`.
- [ ] The same run writes `dist/homebrew/Formula/cli-toolkit.rb` with four `bin.install` lines, the three completion installs, the `THIRD_PARTY_LICENSES` install and the four `assert_match` tests.
- [ ] `HOMEBREW_TAP_TOKEN` is listed by `gh secret list --repo satoseino/cli-toolkit` before the first tag.
- [ ] Each snapshot binary prints the snapshot version (`toolkit --version`, `-version` for the other three). `toolkit-assume-role -version` prints it with no controlling terminal (`setsid -w toolkit-assume-role -version` on Linux), and `toolkit-serve-static -version` and `toolkit-show-md -version` print it with no positional argument. `go version -m` shows `CGO_ENABLED=0`.
- [ ] A `go install`-built `toolkit --version` prints a module version or `dev`, not an empty string.
- [ ] `THIRD_PARTY_LICENSES` has a section per non-main module from `go list -deps` of the four `cmd/` packages (including the `NOTICE.txt` of `aws-sdk-go-v2` and the `NOTICE` of `smithy-go`), plus the Go standard library.
- [ ] `bash -n`, `zsh -n` and `fish --no-execute` accept the three scripts. In each shell, sourcing its script completes the subcommands, and `start-go-project --g<TAB>` completes `--gelato-version`, `--go-version` and `--golangci-lint-version`.
- [ ] `scripts/` contains only `third-party-licenses.sh`, and `go mod tidy` on the committed tree leaves `go.mod`/`go.sum` unchanged (`git diff --exit-code go.mod go.sum`).
- [ ] `make all` passes, including `version_test.go`.

---

## Files to Change

| File | Change |
|---|---|
| `version/version.go`, `version/version_test.go` | `String()`, `-X` target, build-info fallback |
| `cmd/toolkit/main.go` | `-V/--version` |
| `cmd/toolkit-assume-role/main.go` | `-version`; parse flags before opening `/dev/tty` |
| `cmd/toolkit-show-md/main.go` | `-version`; `Flags:` in `helpMsg` |
| `cmd/toolkit-serve-static/main.go` | `-version` |
| `completions/toolkit.{bash,zsh,fish}` | Hand-written completions |
| `scripts/third-party-licenses.sh` | Generate `THIRD_PARTY_LICENSES` for four binaries |
| `.goreleaser.yaml` | Builds, single archive, checksums, `cli-toolkit` formula |
| `.github/workflows/release.yaml` | Tag-triggered GoReleaser release |
| `scripts/debug-tui/`, `scripts/rename-files/` | Delete |
| `.golangci.yaml` | Delete the three `scripts/rename-files` exclusion rules |
| `go.mod` | `go mod tidy` (`go-spew` becomes indirect) |
| `.gitignore` | Add `/THIRD_PARTY_LICENSES`; delete `/messages.log` |
| `README.md` | Homebrew install, version flags |
| `CLAUDE.md` | Release facts, completion-sync rule, `version` package, `scripts/` description |
| GitHub repository secret (not a file) | `HOMEBREW_TAP_TOKEN` on `satoseino/cli-toolkit` |

---

## Out of scope / follow-up

- Verify the first tag (`v0.1.0`): `homebrew-tap` gets a `Formula/cli-toolkit.rb` commit, and `brew install satoseino/tap/cli-toolkit && brew test cli-toolkit` passes.
- Running `goreleaser check` in `test-and-lint.yaml` to catch config errors before a tag.
