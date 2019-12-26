local p = premake
local m = { }

-- Initialize extension
p.extensions.androidstudio = m
m._VERSION                 = p._VERSION

--
-- Create the Android Studio action
--

newaction {
	-- Metadata
	trigger     = 'android-studio',
	shortname   = 'Android Studio',
	description = 'Generate build files for Android Studio by Google and JetBrains',

	-- Capabilities
	valid_kinds = {
		'ConsoleApp',
		'WindowedApp',
		'StaticLib',
		'SharedLib',
		'Utility',
	},
	valid_languages = {
		'C',
		'C++',
		'Java',
	},
	valid_tools = {
		cc = {
			'clang',
			'gcc',
		}
	},

	-- Workspace generator
	onWorkspace = function( wks )
		p.generate( wks, 'build.gradle',      m.build_dot_gradle.generateWorkspace )
		p.generate( wks, 'gradle.properties', m.gradle_dot_properties.generate )
		p.generate( wks, 'settings.gradle',   m.settings_dot_gradle.generate )
	end,

	-- Project generator
	onProject = function( prj )
		p.generate( prj, string.format( '%s/build.gradle', prj.name ), m.build_dot_gradle.generateProject )
		p.generate( prj, string.format( '%s/Android.mk',   prj.name ), m.android_dot_mk.generate )

		if( prj.kind ~= 'ConsoleApp' and prj.kind ~= 'WindowedApp' ) then
			p.generate( prj, string.format( '%s/AndroidManifest.xml', prj.name ), m.android_manifest_dot_xml.generate )
		end
	end,
}

--
-- Decide when the full module should be loaded.
--

return function( cfg )
	return ( _ACTION == 'gradle' )
end
