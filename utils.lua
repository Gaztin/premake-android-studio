local p             = premake
local androidstudio = p.extensions.androidstudio

--
-- Utility functions
--

function androidstudio.isApp( prj )
	return prj.kind == 'ConsoleApp' or prj.kind == 'WindowedApp'
end

function androidstudio.jvmargs( wks )
	return table.concat( wks.jvmargs, ' ' )
end

function androidstudio.getBuildType( cfg )
	return string.lower( cfg.buildcfg )
end

function androidstudio.findManifest( prj )
	if prj.kind == 'ConsoleApp' or prj.kind == 'WindowedApp' then
		local project_location = string.format( '%s/%s', prj.location, prj.name )

		for _, fname in ipairs( prj.files ) do
			if path.getname( fname ) == 'AndroidManifest.xml' then
				return path.getrelative( project_location, fname )
			end
		end
	else
		return 'AndroidManifest.xml'
	end
end

function androidstudio.findJavaDirs( prj )
	local project_location = string.format( '%s/%s', prj.location, prj.name )
	local java_dirs        = { }

	if prj.appid then
		local java_dirs_unique_map = { }
		local appid_dir_name       = string.gsub( prj.appid, '[.]', '/' )

		for _, fname in ipairs( prj.files ) do
			local appid_dir_index = string.find( fname, appid_dir_name )

			if appid_dir_index then
				local appid_dir_sub = string.sub( fname, 0, appid_dir_index - 1 )

				java_dirs_unique_map[ appid_dir_sub ] = 0
			end
		end

		for dir, _ in spairs( java_dirs_unique_map ) do
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

		if not res_dir_index then
			res_dir_name = 'res/'
			if string.match( fname, res_dir_name ) then
				res_dir_index = 1
			end
		end

		if res_dir_index then
			local res_dir_sub = string.sub( fname, 0, res_dir_index + string.len( res_dir_name ) - 1 )

			res_dirs_unique_map[ res_dir_sub ] = 0
		end
	end

	for dir, _ in spairs( res_dirs_unique_map ) do
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

		if not asset_dir_index then
			asset_dir_name = 'assets/'
			if string.match( fname, asset_dir_name ) then
				asset_dir_index = 1
			end
		end

		if asset_dir_index then
			local asset_dir_sub = string.sub( fname, 0, asset_dir_index + string.len( asset_dir_name ) - 1 )

			asset_dirs_unique_map[ asset_dir_sub ] = 0
		end
	end

	for dir, _ in spairs( asset_dirs_unique_map ) do
		table.insert( asset_dirs, path.getrelative( project_location, dir ) )
	end

	return asset_dirs
end
