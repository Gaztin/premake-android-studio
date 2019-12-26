local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.gradle_dot_properties = m

--
-- Generate the 'gradle.properties' file
--

function m.generate( wks )
	p.w( 'org.gradle.jvmargs=%s', androidstudio.jvmargs( wks ) )
end
