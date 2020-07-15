local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.android_dot_mk = m

--
-- Generate the 'Android.mk' file
--

function m.generate( prj )
	p.indent '    '

	p.w 'LOCAL_PATH := $(call my-dir)'
	p.outln ''
	m.declareDependencies( prj )
	p.w 'include $(CLEAR_VARS)'
	p.w( 'LOCAL_MODULE := %s', prj.name )

	if prj.kind == 'SharedLib' then
		p.w 'LOCAL_ALLOW_UNDEFINED_SYMBOLS := true'
	end

	p.outln ''

	local e = ''
	for cfg in p.project.eachconfig( prj ) do
		local toolset = p.config.toolset( cfg )

		p.push( e..'ifeq ($(PREMAKE_CONFIGURATION)|$(APP_ABI),%s)', cfg.name )

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

		p.pop()

		e = 'else '
	end
	p.w 'endif'
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

function m.declareDependencies( prj )
	local dependencies = { }
	local e = ''

	for cfg in p.project.eachconfig( prj ) do
		local links = p.config.getlinks( cfg, 'dependencies', 'object' )

		if #links > 0 then
			p.push( e..'ifeq ($(PREMAKE_CONFIGURATION)|$(APP_ABI),%s)', cfg.name )

			for _, dependency in ipairs( links ) do
				local buildtargetinfo = p.config.buildtargetinfo( dependency, dependency.kind, 'target' )

				p.w( 'PREMAKE_DEPENDENCY_PATH_%s := %s', dependency.filename, buildtargetinfo.abspath )

				dependencies[ dependency.filename ] = dependency.project
			end

			p.pop()

			e = 'else '
		end
	end

	if #e > 0 then
		p.push 'else'
		p.w '# Set a dummy location for the dependencies. This fixes an issue where gradle is failing to sync while analyzing the'
		p.w '#  ndk-build because the library file is missing, which makes sense since the dependency has not been built yet.'

		for name, dependency in pairs( dependencies ) do
			local ext        = dependency.kind == p.STATICLIB and 'a' or 'so'
			local dummy_path = path.join( androidstudio.MODULE_LOCATION, 'libDummy.'..ext )

			p.w( 'PREMAKE_DEPENDENCY_PATH_%s := %s', dependency.filename, dummy_path )
		end

		p.pop()
		p.w 'endif'
		p.outln ''
	end

	for name, dependency in pairs( dependencies ) do
		p.w( '# Dependency: %s', name )
		p.w 'include $(CLEAR_VARS)'
		p.w( 'LOCAL_MODULE := %s', name )
		p.w( 'LOCAL_SRC_FILES := $(PREMAKE_DEPENDENCY_PATH_%s)', name )

		if dependency.kind == p.STATICLIB then
			p.w 'include $(PREBUILT_STATIC_LIBRARY)'
		else
			p.w 'include $(PREBUILT_SHARED_LIBRARY)'
		end

		p.outln ''
	end
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
