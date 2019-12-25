local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.gradle_dot_properties = m

--
-- Generate the 'gradle.properties' file
--

function m.generate( wks )
	p.utf8()

	p.w( 'org.gradle.jvmargs=%s', androidstudio.jvmargs( wks ) )
end
