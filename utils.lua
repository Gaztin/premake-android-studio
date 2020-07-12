local p             = premake
local androidstudio = p.extensions.androidstudio

--
-- Utility functions
--

function androidstudio.isApp( prj )
	return prj.kind == 'ConsoleApp' or prj.kind == 'WindowedApp'
end
