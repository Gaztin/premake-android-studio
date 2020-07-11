local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.application_dot_mk = m

--
-- Generate the 'Android.mk' file
--

function m.generate( prj )
	m.appStl( prj )
end

--
-- Utility functions
--

function m.appStl( prj )
	if prj.staticruntime and prj.staticruntime == 'On' then
		p.w 'APP_STL := c++_static'
	else
		p.w 'APP_STL := c++_shared'
	end
end
