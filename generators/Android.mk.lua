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

	p.w( 'include $(CLEAR_VARS)' )
	p.outln( '' )

	p.w( 'LOCAL_MODULE := %s', prj.name )
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
		m.localLdLibs( cfg )
		m.localLdFlags( cfg, toolset )

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

function m.localSrcFiles( cfg )
	local local_src_files = { }

	for _, fpath in ipairs( cfg.files ) do
		if( path.iscppfile( fpath ) or path.iscfile( fpath ) ) then
			table.insert( local_src_files, fpath )
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
			p.w( '%s \\', cfg.includedirs[ i ] )
		end
		p.w( '%s', cfg.includedirs[ #cfg.includedirs ] )

		p.pop()
	end
end

function m.localCFlags( cfg, toolset )
	local flags = toolset.getcflags( cfg )

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
	local flags = toolset.getcxxflags( cfg )

	if( #flags > 0 ) then
		p.push( 'LOCAL_CPPFLAGS := \\' )

		for i = 1, ( #flags - 1 ) do
			p.w( '%s \\', flags[ i ] )
		end
		p.w( '%s', flags[ #flags ] )
		
		p.pop()
	end
end

function m.localLdLibs( cfg )
	local links = p.config.getlinks( cfg, 'system', 'name' )

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
