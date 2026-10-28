# cli-toolkit

Personal Go CLI programs, one `main` package per binary under `cmd/`. See `README.md` for what each binary does.

## CLI parsing: kong only for `cmd/toolkit`

Only `cmd/toolkit` uses `github.com/alecthomas/kong`. The other binaries (`toolkit-assume-role`, `toolkit-show-md`, `toolkit-serve-static`) are single-purpose and use the standard library `flag` package with a hand-written `helpMsg` assigned to `flag.Usage`. Keep it that way: don't bring kong into them, and don't add another CLI framework.

### `toolkit` subcommands (kong)

Kong drives command structs through a three-phase DI lifecycle:

1. **`BeforeReset`**: set defaults that don't depend on parsed flags.
2. **`AfterApply`**: derive fields that depend on parsed flags.
3. **`Run`**: assumes all dependencies are already set. If a dependency needs something only known at `Run` time, resolve it as the first step of `Run`.

`scaffold.GoProjectCmd` is the reference implementation. `BeforeReset` builds `VersionSetters` (tagged `kong:"-"`) that point at the `SemVer` flag fields. `AfterApply` captures the working directory and, under a `--timeout-seconds` context, resolves every flag still at `LATEST` from GitHub/PyPI/npm. `Run` only renders files. When you add a new field that tests need to swap out, inject it as an interface-typed or func-typed struct field, not a package-level var. The `githubAPIURLPrefix`/`pypiURLPrefix`/`npmAPIBURLPrefix` vars that `scaffold/project_test.go` overrides are legacy, so don't extend that pattern.

To add a subcommand, define the command type in the package that owns its behavior and register it as a field with a `cmd:"" name:"<subcommand-name>" help:"..."` tag on the `cli` struct in `cmd/toolkit/main.go`.

Shell completions for `toolkit` live in `completions/toolkit.{bash,zsh,fish}`. They are hand-written, not generated, and they hard-code every subcommand and flag name, with the `help:` text as the zsh and fish description. Any change to the CLI surface (a subcommand or flag added, renamed or removed) must update all three scripts in the same change. Nothing tests them against the kong model.

To pin a new tool in a scaffold, add four things:

- a `SemVer` field with `default:"LATEST"`
- a matching `VersionSetter` entry in that command's `BeforeReset`
- a route for it on the `httptest` mux in `TestProjects` if its URL doesn't already match a generic pattern
- its `--<name>` flag in all three `completions/toolkit.*` scripts

## Scaffold templates

- Templates live in the dot-prefixed `scaffold/.go/`, `scaffold/.python/` and `scaffold/.ts.cdk/` trees and are embedded with `//go:embed "all:..."`. Each file must end in `.tmplt`, which is stripped on output. They use `{% %}` delimiters, not `{{ }}`, so GitHub Actions `${{ }}` expressions pass through untouched. The data passed in is the command struct itself (e.g. `{% .GolangcilintVersion %}`), plus the `DashLower` func.
- A new file in a tree is picked up automatically, with no registration needed.
- `scaffold/.go/` is a lighter copy of this repo's own `.golangci.yaml`, `Makefile` and `.pre-commit-config.yaml`. When you change shared lint or tooling policy here, check whether the template should get the same change. Repo-specific exclusion rules stay out of it.

## `tui` and `cmd/toolkit-tui`: intentional pre-MVP

`tui` and `cmd/toolkit-tui` are a deliberately half-baked bubbletea TUI for the Python scaffold. Don't polish, refactor, extend or add tests for them unless asked. Do keep them compiling: `tui` embeds `scaffold.VersionSetter` and `cmd/toolkit-tui` calls `PythonProjectCmd.BeforeReset()` by hand, so changes to the scaffold's exported API must carry through there. `scripts/` holds release tooling that GoReleaser runs (`third-party-licenses.sh`), not Go code.

## Credentials (`toolkit-assume-role`)

- `toolkit-assume-role` is an AWS CLI `credential_process`. **Stdout carries only the credential JSON.** All prompts (MFA code) and logs go through `terminal.TTY` on `/dev/tty`, which is why it only works on macOS/Linux. Never print anything else to stdout there.
- Cached credentials are AES-GCM encrypted on disk (`creds` + `cipher`). The key lives in the OS keyring via `key.KeyringProvider`. Credentials and keys are never logged.

## Package layout and naming

- No Go package folders that exist purely for organization. Every top-level package (`cipher`, `creds`, `jsonstream`, `key`, `scaffold`, `terminal`, `tui`, `version`) owns real behavior. This doesn't constrain non-Go asset directories such as the scaffold template trees or `scripts/`.
- Exported names read naturally with their package qualifier and don't stutter (`creds.Processor`, `key.KeyringProvider`, not `creds.CredsProcessor`). Read a new name back as `pkg.TypeName` before committing to it.

## Composition and interfaces

- Favor composition and small dedicated types for concerns that carry their own complexity or get reused elsewhere. For example, `creds.Processor` delegates to a `cacher`, an `stscreds.AssumeRoleProvider` and a `logger` rather than doing caching, STS and output itself.
- Method count on an orchestrating type is not itself a smell. Judge by interface depth instead (Ousterhout's "deep module": a simple external interface hiding non-trivial implementation). Extract a new type when private helpers start spanning *unrelated* responsibilities, not just because there are many of them.
- Define interfaces at the consumer for DI and testability, not in the producer's package. For example, `creds.KeyProvider` and `creds.logger` are declared in `creds`, and `key.KeyringProvider` and `terminal.TTY` satisfy them.

## Testing strategy

- Start every command with end-to-end test cases before smaller unit tests. Drive the real lifecycle methods against a real `httptest.Server` and a real temp filesystem, with hand-written stubs (not generated mocks) for the few things that must be faked. `scaffold/project_test.go` (`TestProjects`) is the reference. `creds/command_test.go` shows the hand-written stubs (`MockTerminal`, `AesKeyProvider`, `HomeDirMocker`). `testify`'s `assert`/`require` are the assertion libraries.
- Prefer `testdata/` fixture files over inline literals for inputs and expected outputs (e.g. `scaffold/testdata/*.resp.json`).
- Once an end-to-end baseline exists, add targeted cases for each later change rather than re-deriving the whole flow.
- For functional code with few side effects (input in, output out), use comprehensive table-driven and/or testdata-driven coverage. `jsonstream/angler_test.go` and `cmd/toolkit-show-md/main_test.go` are the references.
- Cover happy paths thoroughly, but don't chase a coverage percentage. Don't add production abstractions (interfaces, func-typed fields) solely so a test can force a rarely hit error branch. Test-only stubs of seams that already exist for other reasons (e.g. an `io.Writer` destination) are fine when the behavior they pin down is worth keeping, such as an error-message format.

## Local dev tooling (required)

- Run `pre-commit install -t pre-commit` before contributing.
- Use the `Makefile` targets rather than calling `go test` / `golangci-lint` directly. `make all` (test + lint) is the default target and the bar for a change being done. `make fmt` auto-fixes formatting.
- `golangci-lint` must pass. Suppress a false positive case by case in `.golangci.yaml` under `linters.exclusions.rules`, scoped to the specific `path` and `text`, with a comment explaining why. Never use a blanket `//nolint` or disable a linter. Exception: `govet`'s `fieldalignment` diagnostic encodes struct-specific byte counts, so it can't be pinned to a stable `text:` regex. Suppress it with an inline, linter-scoped `//nolint:govet // fieldalignment: ...` comment on the struct instead, explaining why the field order is intentional.
- [`gelato`](https://github.com/satoseino/gelato), a tartufo-compatible port, does secret scanning. It still reads `tartufo.toml`. Exclude false positives there, not by skipping the hook.
- Coding agents: never invoke the secret scanner yourself (`make lint-all`, a raw `pre-commit run ... gelato`, or `gelato scan`). It floods context for no benefit, and the git hook already enforces it.
- Import grouping (standard / third-party / this module, via `gci`) and other style rules are auto-fixed by the tooling. Run `make fmt` rather than hand-arranging imports.

## Error handling

Use `fmt.Errorf("...: %s", err.Error())` for context-only wrapping. This is the default (see `creds`, `key`). Use `%w` conservatively, because wrapping with `%w` makes that error part of the package's public interface. Reach for it when callers need to tell *what kind* of failure occurred, not just *whether* one did: define an exported `Err*` sentinel and wrap it with `%w`, as `creds.ErrInvalidCredential` is wrapped in `cacher.save` and branched on with `errors.Is` in `Processor.Run`. If the underlying cause is a sentinel from another package, don't propagate it directly. Handle it or wrap your own `Err*` around it, the way `key.KeyringProvider.Write` absorbs `keyring.ErrNotFound`. Don't mint a sentinel for every fallible call, only for failure modes a caller would plausibly branch on. The blanket `%w` in `scaffold` is older code: don't copy it into new code.

## Doc comments

All new or changed exported identifiers require godoc-style comments.

## Release and distribution (GoReleaser / Homebrew)

A `v*` tag runs `.github/workflows/release.yaml`, which runs GoReleaser with `.goreleaser.yaml`. One archive per platform holds `toolkit`, `toolkit-assume-role`, `toolkit-show-md` and `toolkit-serve-static`, so one `cli-toolkit` formula in `satoseino/homebrew-tap` installs all four, plus `toolkit`'s completions and `THIRD_PARTY_LICENSES`. `toolkit-tui` is not shipped. Every binary reports the `version` package's `-X`-stamped version (`toolkit --version`, `-version` for the others).

The tap token is the `HOMEBREW_TAP_TOKEN` repository secret, a fine-grained PAT limited to Contents read/write on `satoseino/homebrew-tap`. When it expires, releases still publish, but the tap update fails.

Use GoReleaser's legacy `brews:` config, not the newer `homebrew_casks:`, and don't re-litigate this. Casks quarantine installed binaries (`com.apple.quarantine`), and Gatekeeper blocks quarantined unsigned binaries. This project doesn't code-sign or notarize macOS builds, so casks would break the `toolkit*` binaries on first run. `brews:` Formulae install unquarantined. Revisit only after adopting Apple Developer code signing + notarization, or if GoReleaser removes `brews:` outright. `brews:` is gone in GoReleaser v3, so `goreleaser-action` stays pinned to `version: "~> v2"` while `brews:` exists.
