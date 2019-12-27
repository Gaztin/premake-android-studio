-- Fix for when the module isn't embedded
include( '_preload.lua' )
include( 'fields.lua' )
include( 'utils.lua' )
include( 'generators/build.gradle.lua' )
include( 'generators/gradle.properties.lua' )
include( 'generators/settings.gradle.lua' )
include( 'generators/Android.mk.lua' )
include( 'generators/Application.mk.lua' )
include( 'generators/AndroidManifest.xml.lua' )

-- Set default prefix and extension for app binaries
filter { "system:android", "kind:ConsoleApp or WindowedApp" }
	targetprefix "lib"
	targetextension ".so"

filter { }
