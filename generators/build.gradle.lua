local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.build_dot_gradle = m

--
-- Generate the global 'build.gradle' file
--

function m.generateWorkspace( wks )
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
	p.indent( '    ' )

	if( androidstudio.isApp( prj ) ) then
		p.w( 'apply plugin: \'com.android.application\'' )
	else
		p.w( 'apply plugin: \'com.android.library\'' )
	end

	m.push( 'android' )
	p.w( 'compileSdkVersion %s', androidstudio.maxSdkVersion( prj ) )
	m.defaultConfig( prj )

	m.push( 'externalNativeBuild' )
	m.push( 'ndkBuild' )
	p.w( 'path \'Android.mk\'' )
	m.pop() -- ndkBuild
	m.pop() -- externalNativeBuild

	m.buildTypes( prj )
	m.sourceSets( prj )
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

	if( androidstudio.isApp( prj ) ) then
		p.w( 'applicationId \'%s\'', prj.appid )
	end

	p.w( 'minSdkVersion %s', androidstudio.minSdkVersion( prj ) )
	p.w( 'targetSdkVersion %s', androidstudio.maxSdkVersion( prj ) )
	p.w( 'versionCode 1' )
	p.w( 'versionName \'1.0\'' )

	m.pop() -- defaultConfig
end

function m.buildTypes( prj )
	local optimize_minifyEnabled   = { Size = 'true' }
	local optimize_shrinkResources = { Size = 'true' }
	local symbols_debuggable       = { On   = 'true' }

	m.push( 'buildTypes' )

	for cfg in p.project.eachconfig( prj ) do
		local build_type = androidstudio.getBuildType( cfg )

		m.push( build_type )
		p.w( 'minifyEnabled %s',   optimize_minifyEnabled[ cfg.optimize ]   or 'false' )
		p.w( 'shrinkResources %s', optimize_shrinkResources[ cfg.optimize ] or 'false' )
		p.w( 'debuggable %s',      symbols_debuggable[ cfg.symbols ]        or 'false' )

		m.cFlags( cfg )

		m.pop() -- @build_type
	end

	m.pop() -- buildTypes
end

function m.sourceSets( prj )
	local manifest_file = androidstudio.findManifest( prj )
	local java_dirs     = androidstudio.findJavaDirs( prj )
	local res_dirs      = androidstudio.findResourceDirs( prj )
	local asset_dirs    = androidstudio.findAssetDirs( prj )

	m.push( 'sourceSets' )
	m.push( 'main' )

	if( manifest_file ) then
		p.w( 'manifest.srcFile \'%s\'', manifest_file )
	end

	if( #java_dirs > 0 ) then
		p.w( 'java.srcDirs \'%s\'', table.concat( java_dirs, '\', \'' ) )
	end

	if( #res_dirs > 0 ) then
		p.w( 'res.srcDirs \'%s\'', table.concat( res_dirs, '\', \'' ) )
	end

	if( #asset_dirs > 0 ) then
		p.w( 'assets.srcDirs \'%s\'', table.concat( asset_dirs, '\', \'' ) )
	end

	m.pop() -- main
	m.pop() -- sourceSets
end

function m.cFlags( cfg )
	if( cfg.buildoptions and #cfg.buildoptions > 0 ) then
		m.push( 'externalNativeBuild' )
		m.push( 'ndkBuild' )

		p.w( 'cFlags \'-DPREMAKE_CONFIGURATION=%s\'', cfg.buildcfg )

		m.pop() -- ndkBuild
		m.pop() -- externalNativeBuild
	end
end
