---
description: >
  Front matter tracks which findings have been posted to GitHub as change requests,
  which have been dismissed, and remaining concerns if any.
  changes_requested is a flow sequence of finding labels posted to GitHub that are still open.
  findings_dismissed is a flow sequence of finding labels the reviewer chose not to post.
  merged is a boolean that tracks if the PR has been merged.
  notes is for optional notes about remaining concerns.
pr_url: https://github.com/satoseino/cli-toolkit/pull/31
changes_requested: [M1]
findings_dismissed: [m1]
merged:
notes:
---
# PR Review: Feature: Homebrew release pipeline, version flags and toolkit shell completions

**PR:** https://github.com/satoseino/cli-toolkit/pull/31
**Spec:** .working-docs/spec/001-homebrew-release.md
**Reviewed:** 2026-10-28

## Summary

The PR follows the spec closely. The `version` package, the four version flags, the reordered `/dev/tty` open, the GoReleaser config, the release workflow, the doc updates and the `scripts/` cleanup all match what the spec asks for. `make all` passes, `go mod tidy -diff` is clean, and `HOMEBREW_TAP_TOKEN` is set on the repo. The completion flag lists match every `name:` tag in `scaffold/project.go`. One real defect: `THIRD_PARTY_LICENSES` is built from a single-GOOS dependency list, so the darwin archives ship without the notice for a dependency linked only into darwin builds. Fish completions also remain unverified.

## Spec Compliance

| Requirement | Status |
|---|---|
| 1. `version` package + table test | Met |
| 2. `toolkit -V/--version` via kong | Met |
| 3. `-version` on the three flag binaries, stderr, before arg validation; assume-role parses before `/dev/tty`; show-md `Flags:` section | Met (checked: `toolkit-assume-role -version` prints to stderr, nothing on stdout, exit 0) |
| 4. Completions (subcommands, all flags, help text, no value completion, zsh `funcstack` dispatch, ASCII/LF) | Met (flags cross-checked against `scaffold/project.go`; `bash -n`/`zsh -n` pass) |
| 5. `scripts/third-party-licenses.sh` (mode 100755, `.gitignore`) | Partially Met — see [M1] |
| 6. `.goreleaser.yaml` | Met |
| 7. `.github/workflows/release.yaml` | Met |
| 8. README | Met |
| 9. CLAUDE.md | Met |
| 10. Remove `scripts/debug-tui`, `scripts/rename-files`, lint rules, `/messages.log`, tidy `go-spew` | Met (`go mod tidy -diff` clean) |
| AC: `HOMEBREW_TAP_TOKEN` listed before first tag | Met (set 2026-10-28T15:30:24Z) |
| AC: `THIRD_PARTY_LICENSES` covers every linked module | Not Met for the darwin archives — see [M1] |
| AC: `fish --no-execute` + interactive completion in each shell | Partially Met — see [m1] |
| AC: `make all` passes | Met |

## Findings

### Critical

_None._

### Major

**[M1] `THIRD_PARTY_LICENSES` omits modules linked only into the other OS's binaries** — `scripts/third-party-licenses.sh:43-45` runs `go list -deps` once, for the host GOOS. The dependency sets differ by OS: `GOOS=darwin` pulls in `al.essio.dev/pkg/shellescape` (MIT, through `zalando/go-keyring`'s darwin backend), and `GOOS=linux` pulls in `github.com/godbus/dbus/v5` (BSD-2-Clause) instead. The release job runs on `ubuntu-latest`, so the single `THIRD_PARTY_LICENSES` file shared by all four archives leaves out `shellescape`'s MIT notice, even though that module is linked into both darwin binaries. A local macOS snapshot hides this in the opposite direction: it drops `godbus`, which the linux archives need. Fix: build the union over the shipped targets, e.g. `for goos in darwin linux; do GOOS=$goos go list -deps -f '…' ./cmd/…; done | sort -u`. `go list` downloads the cross-OS module, so `.Dir` is still populated. GOARCH doesn't change the set today, but looping over it as well would be cheap insurance.

### Minor

**[m1] Fish completions are unverified** — The PR description says fish isn't installed locally, so the spec's acceptance criterion (`fish --no-execute` plus `start-go-project --g<TAB>` interactively) hasn't been run for `completions/toolkit.fish`. Reading the file, I see no obvious defect, but it ships in every formula.

## Positive Observations

- `version.resolve` is a clean, pure function behind a thin `String()` wrapper, and its table test covers every branch, including `(devel)` and an empty `Main.Version`.
- Moving `flag.Parse()` ahead of the `/dev/tty` open is minimal and keeps stdout credential-only. The comment explains both constraints.
- `.goreleaser.yaml` uses YAML anchors to share the build keys and explains each non-obvious choice (single archive, `brews` vs casks, `skip_upload: auto`, `extra_install` for `THIRD_PARTY_LICENSES`).
- `third-party-licenses.sh` fails loudly when a module has no license, and it handles Homebrew's relocated GOROOT `LICENSE`.
- The completion flag lists and descriptions match the kong `name:`/`help:` tags exactly, and the new CLAUDE.md checklist item will help keep them in sync.

## Recommendation

**Request Changes** — fix [M1] before the first tag so the darwin archives carry every required license notice.
