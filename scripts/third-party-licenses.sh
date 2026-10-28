#!/usr/bin/env bash
# Writes THIRD_PARTY_LICENSES: the license notices of every module linked into
# the four shipped toolkit binaries and of the Go standard library, which their
# licenses require to ship with the binaries. Run from the repository root
# (GoReleaser before hook).
set -euo pipefail

out=THIRD_PARTY_LICENSES
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

section() {
	printf '%s\n%s\n\n' "$1" "$(printf '%*s' "${#1}" '' | tr ' ' '=')"
}

# The dependency set differs per OS (go-keyring links shellescape on darwin and
# godbus on linux), and every archive ships this one file, so list the union
# over the shipped GOOS values (.goreleaser.yaml builds), not the host's.
modules=$(for goos in darwin linux; do
	GOOS=$goos go list -deps -f '{{with .Module}}{{if not .Main}}{{.Path}} {{.Dir}}{{end}}{{end}}' \
		./cmd/toolkit ./cmd/toolkit-assume-role ./cmd/toolkit-show-md ./cmd/toolkit-serve-static
done | sort -u)

while read -r path dir; do
	[[ -n $path ]] || continue

	shopt -s nullglob
	files=("$dir"/LICENSE* "$dir"/COPYING* "$dir"/NOTICE*)
	shopt -u nullglob

	if ((${#files[@]} == 0)); then
		echo "third-party-licenses: no license file in module $path ($dir)" >&2
		exit 1
	fi

	section "$path" >>"$tmp"
	for f in "${files[@]}"; do
		cat "$f" >>"$tmp"
		printf '\n' >>"$tmp"
	done
done <<<"$modules"

goroot=$(go env GOROOT)
golicense=$goroot/LICENSE
# Homebrew's go sets GOROOT to the keg's libexec and moves LICENSE to the keg root.
[[ -f $golicense ]] || golicense=$goroot/../LICENSE
if [[ ! -f $golicense ]]; then
	echo "third-party-licenses: no LICENSE in GOROOT ($goroot) or its parent" >&2
	exit 1
fi

section "Go standard library" >>"$tmp"
cat "$golicense" >>"$tmp"

chmod 644 "$tmp"
mv "$tmp" "$out"
trap - EXIT
