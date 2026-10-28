---
load:
  - .working-docs/spec/001-homebrew-release.md
  - .working-docs/review/001-report.md
base_branch: main
next_labels:
  C: 1
  M: 2
  m: 2
---

# Session Notes

<!--
  `load:` paths are relative to CWD, not to this file.
  The last entry in `load:` is always the report file. All entries before it are spec or
  spec-like files. The user may manually add more spec-like files between sessions, but
  the last entry is always the report file.
  Record prior session conclusions, open questions, and constraints here.
  Write it as a future-you artifact.
-->

## 2026-10-28 start session (HEAD 9b75b0e)

- Verified at review time: `make all` passes; `go mod tidy -diff` clean; `bash -n`/`zsh -n` pass; `HOMEBREW_TAP_TOKEN` is set on satoseino/cli-toolkit (2026-10-28T15:30:24Z); `toolkit-assume-role -version` prints to stderr only, exit 0; completion flag lists match every `name:` tag in `scaffold/project.go`.
- M1 check: `diff <(GOOS=linux go list -deps …) <(GOOS=darwin go list -deps …)` over the four `./cmd/` packages. Before the fix: darwin-only `al.essio.dev/pkg/shellescape`, linux-only `github.com/godbus/dbus/v5`. Addressed when the generated `THIRD_PARTY_LICENSES` contains both, whatever the host OS.
- m1 (fish unverified) dismissed: don't re-raise fish verification.
- `.working-docs/` being committed in the PR is the user's convention (its README explains it). Not a finding.
- M1 fix committed locally as 4c4cefb (not pushed yet); the spec's section 5 and its THIRD_PARTY_LICENSES acceptance criterion were updated to match in the next commit. Verified locally: 22 sections (21 modules + stdlib) with both shellescape and godbus, including when run with `GOOS=linux`. Followup still has to rate M1 against the reviewer's posted comment.
