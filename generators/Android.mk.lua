local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.android_dot_mk = m

--
-- Generate the 'Android.mk' file
--

function m.generate( prj )
	local configs = { }
	for cfg in p.project.eachconfig( prj ) do
		table.insert( configs, cfg )
	end

	p.indent( '    ' )

	p.w( 'LOCAL_PATH := $(call my-dir)' )
	p.outln( '' )

	if( androidstudio.isApp( prj ) ) then
		m.includeDependencies( prj )
	end

	p.w( 'include $(CLEAR_VARS)' )
	p.outln( '' )

	p.w( 'LOCAL_MODULE := %s', prj.name )

	if( prj.kind == 'SharedLib' ) then
		p.w( 'LOCAL_ALLOW_UNDEFINED_SYMBOLS := true' )
	end

	p.outln( '' )

	for i = 1, #configs do
		local cfg     = configs[ i ]
		local toolset = p.config.toolset( cfg )

		p.push( 'ifeq ($(PREMAKE_CONFIGURATION),%s)', cfg.buildcfg )

		m.localModuleFilename( cfg )
		m.localSrcFiles( cfg )
		m.localCppFeatures( cfg )
		m.localCIncludes( cfg )
		m.localCFlags( cfg, toolset )
		m.localCppFlags( cfg, toolset )
		m.localLdLibs( cfg, toolset )
		m.localLdFlags( cfg, toolset )

		if( androidstudio.isApp( prj ) ) then
			m.localLibraries( cfg )
		end

		if( i == #configs ) then
			p.pop( 'endif' )
		else
			p.pop()
			p.out( 'else ' )
		end
	end
	p.outln( '' )

	if( prj.kind == 'StaticLib' ) then
		p.w( 'include $(BUILD_STATIC_LIBRARY)' )
	else
		p.w( 'include $(BUILD_SHARED_LIBRARY)' )
	end
	p.outln( '' )
end

--
-- Utility functions
--

function m.getrelative( prj, dest )
	return path.getrelative( prj.location .. '/' .. prj.name, dest )
end

function m.includeDependencies( prj )
	for i = 1, #prj.links do
		local link_prj = p.workspace.findproject( prj.workspace, prj.links[ i ] )
		if( link_prj ) then
			p.w( 'include %s/%s/Android.mk', m.getrelative( prj, link_prj.location ), link_prj.name )
		end
	end
end

function m.localSrcFiles( cfg )
	local local_src_files = { }

	for _, fpath in ipairs( cfg.files ) do
		if( path.iscppfile( fpath ) or path.iscfile( fpath ) ) then
			table.insert( local_src_files, m.getrelative( cfg.project, fpath ) )
		end
	end

	if( #local_src_files > 0 ) then
		p.push( 'LOCAL_SRC_FILES := \\' )

		for i = 1, ( #local_src_files - 1 ) do
			p.w( '%s \\', local_src_files[ i ] )
		end
		p.w( '%s', local_src_files[ #local_src_files ] )

		p.pop()
	end
end

function m.localModuleFilename( cfg )
	p.w( 'LOCAL_MODULE_FILENAME := %s%s', cfg.buildtarget.prefix, cfg.buildtarget.basename )
end

function m.localCppFeatures( cfg )
	local cpp_features = { }

	if( cfg.rtti == 'On' ) then
		table.insert( cpp_features, 'rtti' )
	end

	if( cfg.exceptionhandling == 'On' ) then
		table.insert( cpp_features, 'exceptions' )
	end

	if( #cpp_features > 0 ) then
		p.w( 'LOCAL_CPP_FEATURES := %s', table.concat( cpp_features, ' ' ) )
	end
end

function m.localCIncludes( cfg )
	if( #cfg.includedirs > 0 ) then
		p.push( 'LOCAL_C_INCLUDES := \\' )

		for i = 1, ( #cfg.includedirs - 1 ) do
			p.w( '%s \\', m.getrelative( cfg.project, cfg.includedirs[ i ] ) )
		end
		p.w( '%s', m.getrelative( cfg.project, cfg.includedirs[ #cfg.includedirs ] ) )

		p.pop()
	end
end

function m.localCFlags( cfg, toolset )
	local flags   = toolset.getcflags( cfg )
	local defines = toolset.getdefines( cfg.defines )

	for _, def in ipairs( defines ) do
		table.insert( flags, def )
	end

	if( #flags > 0 ) then
		p.push( 'LOCAL_CFLAGS := \\' )

		for i = 1, ( #flags - 1 ) do
			p.w( '%s \\', flags[ i ] )
		end
		p.w( '%s', flags[ #flags ] )

		p.pop()
	end
end

function m.localCppFlags( cfg, toolset )
	local flags   = toolset.getcxxflags( cfg )
	local defines = toolset.getdefines( cfg.defines )

	for _, def in ipairs( defines ) do
		table.insert( flags, def )
	end

	if( #flags > 0 ) then
		p.push( 'LOCAL_CPPFLAGS := \\' )

		for i = 1, ( #flags - 1 ) do
			p.w( '%s \\', flags[ i ] )
		end
		p.w( '%s', flags[ #flags ] )
		
		p.pop()
	end
end

function m.localLdLibs( cfg, toolset )
	local links = toolset.getlinks( cfg, true )

	if( #links > 0 ) then
		p.push( 'LOCAL_LDLIBS := \\' )

		for i = 1, ( #links - 1 ) do
			p.w( '%s \\', links[ i ] )
		end
		p.w( '%s', links[ #links ] )
		
		p.pop()
	end
end

function m.localLdFlags( cfg, toolset )
	local flags = toolset.getldflags( cfg )

	if( #flags > 0 ) then
		p.push( 'LOCAL_LDFLAGS := \\' )

		for i = 1, ( #flags - 1 ) do
			p.w( '%s \\', flags[ i ] )
		end
		p.w( '%s', flags[ #flags ] )
		
		p.pop()
	end
end

function m.localLibraries( cfg )
	local shared_projects = { }
	local static_projects = { }

	for _, link in ipairs( cfg.links ) do
		local link_prj = p.workspace.findproject( cfg.workspace, link )

		if( link_prj ) then
			if( link_prj.kind == 'StaticLib' ) then
				table.insert( static_projects, link_prj )
			elseif( link_prj.kind == 'SharedLib' ) then
				table.insert( shared_projects, link_prj )
			end
		end
	end

	if( #shared_projects > 0 ) then
		p.push( 'LOCAL_SHARED_LIBRARIES := \\' )

		for i = 1, ( #shared_projects - 1 ) do
			p.w( '%s \\', shared_projects[ i ].name )
		end

		p.w( '%s', shared_projects[ #shared_projects ].name )
		p.pop()
	end

	if( #static_projects > 0 ) then
		p.push( 'LOCAL_STATIC_LIBRARIES := \\' )

		for i = 1, ( #static_projects - 1 ) do
			p.w( '%s \\', static_projects[ i ].name )
		end

		p.w( '%s', static_projects[ #static_projects ].name )
		p.pop()
	end
end
