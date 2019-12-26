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

function androidstudio.findManifest( prj )
	if( prj.kind == 'ConsoleApp' or prj.kind == 'WindowedApp' ) then
		local project_location = string.format( '%s/%s', prj.location, prj.name )

		for _, fname in ipairs( prj.files ) do
			if( path.getname( fname ) == 'AndroidManifest.xml' ) then
				return path.getrelative( project_location, fname )
			end
		end
	else
		return 'AndroidManifest.xml'
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

function androidstudio.findResourceDirs( prj )
	local project_location    = string.format( '%s/%s', prj.location, prj.name )
	local res_dirs            = { }
	local res_dirs_unique_map = { }

	for _, fname in ipairs( prj.files ) do
		local res_dir_name  = '/res/'
		local res_dir_index = string.find( fname, res_dir_name )

		if( not res_dir_index ) then
			res_dir_name = 'res/'
			if( string.match( fname, res_dir_name ) ) then
				res_dir_index = 1
			end
		end

		if( res_dir_index ) then
			local res_dir_sub = string.sub( fname, 0, res_dir_index + string.len( res_dir_name ) - 1 )

			res_dirs_unique_map[ res_dir_sub ] = 0
		end
	end

	for dir, _ in pairs( res_dirs_unique_map ) do
		table.insert( res_dirs, path.getrelative( project_location, dir ) )
	end

	return res_dirs
end

function androidstudio.findAssetDirs( prj )
	local project_location      = string.format( '%s/%s', prj.location, prj.name )
	local asset_dirs            = { }
	local asset_dirs_unique_map = { }

	for _, dir in ipairs( prj.assetdirs ) do
		asset_dirs_unique_map[ dir ] = 0
	end

	for _, fname in ipairs( prj.files ) do
		local asset_dir_name  = '/assets/'
		local asset_dir_index = string.find( fname, asset_dir_name )

		if( not asset_dir_index ) then
			asset_dir_name = 'assets/'
			if( string.match( fname, asset_dir_name ) ) then
				asset_dir_index = 1
			end
		end

		if( asset_dir_index ) then
			local asset_dir_sub = string.sub( fname, 0, asset_dir_index + string.len( asset_dir_name ) - 1 )

			asset_dirs_unique_map[ asset_dir_sub ] = 0
		end
	end

	for dir, _ in pairs( asset_dirs_unique_map ) do
		table.insert( asset_dirs, path.getrelative( project_location, dir ) )
	end

	return asset_dirs
end
