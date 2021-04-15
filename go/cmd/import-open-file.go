package main

import (
	flutter "github.com/go-flutter-desktop/go-flutter"
	open_file "github.com/jld3103/go-flutter-open_file"
)

func init() {
	// Only the init function can be tweaked by plugin maker.
	options = append(options, flutter.AddPlugin(&open_file.OpenFilePlugin{}))

}
