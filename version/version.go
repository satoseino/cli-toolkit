// Package version reports the version of the running toolkit binary.
package version

import "runtime/debug"

// devVersion is the version of a build with neither a stamped version nor a
// usable module version in its build info.
const devVersion = "dev"

// stamped is set at release time with
// -ldflags "-X github.com/satoseino/cli-toolkit/version.stamped=...".
var stamped = devVersion

// String returns the stamped release version, or, for builds without one
// (go install), the main module version from the build info, or "dev".
func String() string {
	info, ok := debug.ReadBuildInfo()

	return resolve(stamped, info, ok)
}

// resolve returns stamped unless it is devVersion. Builds without -ldflags,
// such as `go install`, fall back to the main module version that Go stamps
// from the module proxy or the repository's VCS tag or commit, when there is
// one.
func resolve(stamped string, info *debug.BuildInfo, ok bool) string {
	if stamped != devVersion || !ok {
		return stamped
	}

	if v := info.Main.Version; v != "" && v != "(devel)" {
		return v
	}

	return stamped
}
