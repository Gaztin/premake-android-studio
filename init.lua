require '_preload'
require 'customizations'
require 'fields'
require 'utils'

require 'generators/Android.mk'
require 'generators/AndroidManifest.xml'
require 'generators/Application.mk'
require 'generators/build.gradle'
require 'generators/gradle.properties'
require 'generators/settings.gradle'

-- Set default prefix and extension for app binaries
if _ACTION == 'android-studio' then
	appid 'com.example.app'
	gradleversion '3.0.0'
	jvmargs { '-Xmx2048m' }
	maxsdkversion '26'
	minsdkversion '15'
	toolset 'clang'

	-- Apps are compiled down to .so files
	filter 'kind:WindowedApp or ConsoleApp'
	targetprefix 'lib'
	targetextension '.so'

	-- Reset filter before exiting
	filter { }
end
