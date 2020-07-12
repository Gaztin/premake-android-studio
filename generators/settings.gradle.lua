local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.settings_dot_gradle = m

--
-- Generate the 'settings.gradle' script file
--

function m.generate( wks )
	p.w( 'rootProject.name = \'%s\'', wks.name )
	p.outln ''

	for prj in p.workspace.eachproject( wks ) do
		local relative_location = p.workspace.getrelative( wks, prj.location )

		p.w( 'include( \':%s\' )', prj.name )
		p.w( 'project( \':%s\' ).projectDir = file( \'%s\' )', prj.name, relative_location )
		p.w( 'project( \':%s\' ).buildFileName = file( \'%s.build.gradle\' )', prj.name, prj.name )
		p.outln ''
	end
end
