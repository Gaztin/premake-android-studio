local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.build_dot_gradle = m

--
-- Generate the global 'build.gradle' file
--

function m.generateWorkspace( wks )
	p.utf8()
	p.indent( '    ' )

	m.push( 'buildscript' )
	m.push( 'repositories' )
	p.w( 'jcenter()' )
	p.w( 'google()' )
	m.pop() -- repositories
	m.push( 'dependencies' )
	p.w( 'classpath \'com.android.tools.build:gradle:%s\'', androidstudio.gradleVersion( wks ) )
	m.pop() -- dependencies
	m.pop() -- buildscript
	m.push( 'allprojects' )
	m.push( 'repositories' )
	p.w( 'jcenter()' )
	p.w( 'google()' )
	m.pop() -- repositories
	m.pop() -- allprojects
end

--
-- Generate the 'build.gradle' file for each project
--

function m.generateProject( prj )
	p.utf8()
	p.indent( '    ' )

	p.w( 'apply plugin: \'com.android.application\'' )
	m.push( 'android' )
	p.w( 'compileSdkVersion %s', androidstudio.maxSdkVersion( prj ) )
	m.defaultConfig( prj )
	m.externalNativeBuild( prj )
	m.buildTypes( prj )
	m.pop() -- android
end

--
-- Utility functions
--

function m.push( name )
	p.push( name .. ' {' )
end

function m.pop()
	p.pop( '}' )
end

function m.defaultConfig( prj )
	m.push( 'defaultConfig' )
	p.w( 'minSdkVersion %s', androidstudio.minSdkVersion( prj ) )
	p.w( 'targetSdkVersion %s', androidstudio.maxSdkVersion( prj ) )
	p.w( 'versionCode 1' )
	p.w( 'versionName \'1.0\'' )
	m.pop() -- defaultConfig
end

function m.externalNativeBuild( prj )
	m.push( 'externalNativeBuild' )
	m.push( 'ndkBuild' )
--	p.w( 'path \'jni/Android.mk\'' )
	p.w( 'path \'Android.mk\'' )
	m.pop() -- ndkBuild
	m.pop() -- externalNativeBuild
end

function m.buildTypes( prj )
	local optimize_minifyEnabled   = { Size = 'true' }
	local optimize_shrinkResources = { Size = 'true' }
	local symbols_debuggable       = { On   = 'true' }

	m.push( 'buildTypes' )

	for cfg in p.project.eachconfig( prj ) do
		m.push( cfg.buildcfg )
		p.w( 'minifyEnabled %s',   optimize_minifyEnabled[ cfg.optimize ]   or 'false' )
		p.w( 'shrinkResources %s', optimize_shrinkResources[ cfg.optimize ] or 'false' )
		p.w( 'debuggable %s',      symbols_debuggable[ cfg.symbols ]        or 'false' )
		m.cFlags( cfg )
		m.pop() -- cfg.buildcfg
	end

	m.pop() -- buildTypes
end

function m.cFlags( cfg )
	if( cfg.buildoptions and #cfg.buildoptions > 0 ) then
		m.push( 'externalNativeBuild' )
		m.push( 'ndkBuild' )
		
		-- Encapsulate all buildoptions inside quotation marks
		for i = 1, #cfg.buildoptions do
			cfg.buildoptions[ i ] = string.gsub( cfg.buildoptions[ i ], '^' .. cfg.buildoptions[ i ] .. '$',
				function( str )
					return ( '\'' .. str .. '\'' )
				end
			)
		end

		p.w( 'cFlags %s', table.concat( cfg.buildoptions, ', ' ) )
		m.pop() -- ndkBuild
		m.pop() -- externalNativeBuild
	end
end
