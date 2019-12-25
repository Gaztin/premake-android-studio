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
		p.generate( prj, 'build.gradle', m.build_dot_gradle.generateProject )
	end,
}

--
-- Decide when the full module should be loaded.
--

return function( cfg )
	return ( _ACTION == 'gradle' )
end
