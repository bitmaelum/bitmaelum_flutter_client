package main

import (
	"github.com/go-flutter-desktop/plugins/path_provider"

	flutter "github.com/go-flutter-desktop/go-flutter"
)

func init() {
	// Only the init function can be tweaked by plugin maker.
	options = append(options, flutter.AddPlugin(&path_provider.PathProviderPlugin{
		VendorName:      "BitMaelum",
		ApplicationName: "BM-GUI",
	}))

}
