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

function androidstudio.findFileByName( prj, name )
	local project_location = string.format( '%s/%s', prj.location, prj.name )

	for _, fname in ipairs( prj.files ) do
		if( path.getname( fname ) == name ) then
			return path.getrelative( project_location, fname )
		end
	end
end

function androidstudio.findJavaDirs( prj )
	local project_location = string.format( '%s/%s', prj.location, prj.name )
	local appid            = prj.appid
	local java_dirs        = { }

	if( appid ) then
		local java_dirs_unique_map = { }
		local appid_dir_name       = string.gsub( appid, '[.]', '/' )

		for _, fname in ipairs( prj.files ) do
			local appid_dir_index = string.find( fname, appid_dir_name )

			if( appid_dir_index ) then
				local appid_dir_sub = string.sub( fname, 0, appid_dir_index + string.len( appid_dir_name ) )

				java_dirs_unique_map[ appid_dir_sub ] = 0
			end
		end

		for dir, _ in pairs( java_dirs_unique_map ) do
			table.insert( java_dirs, path.getrelative( project_location, dir ) )
		end
	end

	return java_dirs
end
