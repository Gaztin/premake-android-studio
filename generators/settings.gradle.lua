local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.settings_dot_gradle = m

--
-- Generate the 'settings.gradle' script file
--

function m.generate( wks )
	p.w( 'rootProject.name = \'%s\'', wks.name )
	p.outln( '' )

	for prj in p.workspace.eachproject( wks ) do
		local project_dir = string.format( '%s/%s', prj.location, prj.name )

		p.w( 'include( \':%s\' )', prj.name )
		p.w( 'project( \':%s\' ).projectDir = file( \'%s\' )', prj.name, p.workspace.getrelative( wks, project_dir ) )
		p.outln( '' )
	end
end
