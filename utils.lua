local p             = premake
local androidstudio = p.extensions.androidstudio

--
-- Utility functions
--

function androidstudio.gradleVersion( wks )
	return ( wks.gradleversion or '3.0.0' )
end

function androidstudio.jvmargs( wks )
	if( #wks.jvmargs > 0 ) then
		return table.concat( wks.jvmargs, ' ' )
	end

	return '-Xmx2048m'
end

function androidstudio.minSdkVersion( prj )
	return ( prj.minsdkversion or '15' )
end

function androidstudio.maxSdkVersion( prj )
	return ( prj.maxsdkversion or '26' )
end

function androidstudio.getBuildType( cfg )
	return string.lower( cfg.buildcfg )
end
