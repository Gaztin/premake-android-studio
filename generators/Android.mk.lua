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

	p.indent '    '

	p.w 'LOCAL_PATH := $(call my-dir)'
	p.outln ''

	if androidstudio.isApp( prj ) then
		m.includeDependencies( prj )
	end
	p.outln ''

	p.w 'include $(CLEAR_VARS)'
	p.w( 'LOCAL_MODULE := %s', prj.name )

	if prj.kind == 'SharedLib' then
		p.w 'LOCAL_ALLOW_UNDEFINED_SYMBOLS := true'
	end

	p.outln ''

	for i = 1, #configs do
		local cfg     = configs[ i ]
		local toolset = p.config.toolset( cfg )

		p.push( '%sifeq ($(PREMAKE_CONFIGURATION),%s)', i > 1 and 'else ' or '', cfg.buildcfg )

		m.localModuleFilename( cfg )
		m.localSrcFiles( cfg )
		m.localCppFeatures( cfg )
		m.localCIncludes( cfg )
		m.localCFlags( cfg, toolset )
		m.localCppFlags( cfg, toolset )
		m.localLdLibs( cfg, toolset )
		m.localLdFlags( cfg, toolset )

		if androidstudio.isApp( prj ) then
			m.localLibraries( cfg )
		end

		if i == #configs then
			p.pop 'endif'
		else
			p.pop()
		end
	end
	p.outln ''

	if prj.kind == 'StaticLib' then
		p.w 'include $(BUILD_STATIC_LIBRARY)'
	else
		p.w 'include $(BUILD_SHARED_LIBRARY)'
	end
	p.outln ''
end

--
-- Utility functions
--

function m.includeDependencies( prj )
	for i = 1, #prj.links do
		local link_prj = p.workspace.findproject( prj.workspace, prj.links[ i ] )

		if link_prj then
			local relative_location = p.project.getrelative( prj, link_prj.location )
			local android_mk        = path.join( relative_location, 'Android.mk' )

			p.w( 'include %s', android_mk )
		end
	end
end

function m.localSrcFiles( cfg )
	local local_src_files = { }

	for _, fpath in ipairs( cfg.files ) do
		if path.iscppfile( fpath ) or path.iscfile( fpath ) then
			local relative_path = p.project.getrelative( cfg.project, fpath )

			table.insert( local_src_files, relative_path )
		end
	end

	if #local_src_files > 0 then
		p.w( 'LOCAL_SRC_FILES := %s', table.concat( local_src_files, ' ' ) )
	end
end

function m.localModuleFilename( cfg )
	p.w( 'LOCAL_MODULE_FILENAME := %s%s', cfg.buildtarget.prefix, cfg.buildtarget.basename )
end

function m.localCppFeatures( cfg )
	local cpp_features = { }

	if cfg.rtti == 'On' then
		table.insert( cpp_features, 'rtti' )
	end

	if cfg.exceptionhandling == 'On' then
		table.insert( cpp_features, 'exceptions' )
	end

	if #cpp_features > 0 then
		p.w( 'LOCAL_CPP_FEATURES := %s', table.concat( cpp_features, ' ' ) )
	end
end

function m.localCIncludes( cfg )
	if #cfg.includedirs > 0 then
		local relative_includedirs = p.project.getrelative( cfg.project, cfg.includedirs )

		p.w( 'LOCAL_C_INCLUDES := %s', table.concat( relative_includedirs, ' ' ) )
	end
end

function m.localCFlags( cfg, toolset )
	local flags   = toolset.getcflags( cfg )
	local defines = toolset.getdefines( cfg.defines )

	if #flags > 0 then
		p.w( 'LOCAL_CFLAGS := %s %s', table.concat( flags, ' ' ), table.concat( defines, ' ' ) )
	end
end

function m.localCppFlags( cfg, toolset )
	local flags   = toolset.getcxxflags( cfg )
	local defines = toolset.getdefines( cfg.defines )

	if #flags > 0 then
		p.w( 'LOCAL_CPPFLAGS := %s %s', table.concat( flags, ' ' ), table.concat( defines, ' ' ) )
	end
end

function m.localLdLibs( cfg, toolset )
	local links = toolset.getlinks( cfg, true )

	if #links > 0 then
		p.w( 'LOCAL_LDLIBS := %s', table.concat( links, ' ' ) )
	end
end

function m.localLdFlags( cfg, toolset )
	local flags = toolset.getldflags( cfg )

	if #flags > 0 then
		p.w( 'LOCAL_LDFLAGS := %s', table.concat( flags, ' ' ) )
	end
end

function m.localLibraries( cfg )
	local static_libs = { }
	local shared_libs = { }

	for _, dependency in ipairs( p.config.getlinks( cfg, 'dependencies', 'object' ) ) do
		if dependency.kind == p.STATICLIB then
			table.insert( static_libs, dependency.filename )
		elseif dependency.kind == p.SHAREDLIB then
			table.insert( shared_libs, dependency.filename )
		end
	end

	if #static_libs > 0 then
		-- TODO: LOCAL_WHOLE_STATIC_LIBRARIES
		p.w( 'LOCAL_STATIC_LIBRARIES := %s', table.concat( static_libs, ' ' ) )
	end

	if #shared_libs > 0 then
		p.w( 'LOCAL_SHARED_LIBRARIES := %s', table.concat( shared_libs, ' ' ) )
	end
end
