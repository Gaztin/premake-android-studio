local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.settings_dot_gradle = m

--
-- Generate the 'settings.gradle' script file
--

function m.generate( wks )
	p.utf8()

	if( #wks.projects > 0 ) then
		local prj_strings = { }

		for prj in p.workspace.eachproject( wks ) do
			table.insert( prj_strings, '\':' .. prj.name:lower() .. '\'' )
		end

		p.w( 'include %s', table.concat( prj_strings, ', ' ) )
	end
end
