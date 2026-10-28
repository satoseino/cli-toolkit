package version

import (
	"runtime/debug"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestResolve(t *testing.T) {
	tests := []struct {
		info    *debug.BuildInfo
		name    string
		stamped string
		want    string
		ok      bool
	}{
		{
			name:    "stamped wins over build info",
			stamped: "1.2.3",
			info:    &debug.BuildInfo{Main: debug.Module{Version: "v9.9.9"}},
			ok:      true,
			want:    "1.2.3",
		},
		{
			name:    "stamped without build info",
			stamped: "1.2.3",
			want:    "1.2.3",
		},
		{
			name:    "tagged go install",
			stamped: devVersion,
			info:    &debug.BuildInfo{Main: debug.Module{Version: "v1.2.3"}},
			ok:      true,
			want:    "v1.2.3",
		},
		{
			name:    "untagged go install",
			stamped: devVersion,
			info:    &debug.BuildInfo{Main: debug.Module{Version: "v0.0.0-20261027120000-49e2854abcde"}},
			ok:      true,
			want:    "v0.0.0-20261027120000-49e2854abcde",
		},
		{
			name:    "devel build is ignored",
			stamped: devVersion,
			info:    &debug.BuildInfo{Main: debug.Module{Version: "(devel)"}},
			ok:      true,
			want:    devVersion,
		},
		{
			name:    "empty main module version",
			stamped: devVersion,
			info:    &debug.BuildInfo{},
			ok:      true,
			want:    devVersion,
		},
		{
			name:    "no build info",
			stamped: devVersion,
			want:    devVersion,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, resolve(tt.stamped, tt.info, tt.ok))
		})
	}
}
