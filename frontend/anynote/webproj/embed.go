package webui

import "embed"

// Dist contains the built web application assets.
//
//go:embed all:dist
var Dist embed.FS
