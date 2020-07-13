local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.build_dot_gradle = m

--
-- Generate the global 'build.gradle' file
--

function m.generateWorkspace( wks )
	p.indent '    '

	m.push 'buildscript'
	m.push 'repositories'
	p.w 'jcenter()'
	p.w 'google()'
	m.pop '' -- repositories
	m.push 'dependencies'
	p.w( 'classpath \'com.android.tools.build:gradle:%s\'', wks.gradleversion )
	m.pop '' -- dependencies
	m.pop '' -- buildscript
	m.push 'allprojects'
	m.push 'repositories'
	p.w 'jcenter()'
	p.w 'google()'
	m.pop '' -- repositories
	m.pop '' -- allprojects
end

--
-- Generate the 'build.gradle' file for each project
--

function m.generateProject( prj )
	p.indent '    '

	if androidstudio.isApp( prj ) then
		p.w 'apply plugin: \'com.android.application\''
	else
		p.w 'apply plugin: \'com.android.library\''
	end
	p.outln ''

	m.push 'android'
	p.w( 'compileSdkVersion %s', prj.maxsdkversion )
	m.defaultConfig( prj )

	m.push 'externalNativeBuild'
	m.push 'ndkBuild'
	p.w 'path \'Android.mk\''
	p.w( 'buildStagingDirectory \'%s\'', p.project.getfirstconfig( prj ).buildtarget.directory )
	m.pop '' -- ndkBuild
	m.pop '' -- externalNativeBuild

	m.buildTypes( prj )
	m.sourceSets( prj )
	m.pop '' -- android

	m.ndkBuildTasks( prj )
	m.dependencies( prj )
end

--
-- Utility functions
--

function m.push( name )
	p.push( '%s {', name )
end

function m.pop( _ )
	p.pop( '}' )
end

function m.defaultConfig( prj )
	m.push 'defaultConfig'

	if androidstudio.isApp( prj ) then
		p.w( 'applicationId \'%s\'', prj.appid )
	end

	p.w( 'minSdkVersion %s', prj.minsdkversion )
	p.w( 'targetSdkVersion %s', prj.maxsdkversion )
	p.w 'versionCode 1'
	p.w 'versionName \'1.0\''

	if #prj.androidabis > 0 then
		m.push 'ndk'
		p.w( 'abiFilters \'%s\'', table.concat( prj.androidabis, '\', \'' ) )
		m.pop ''
	end

	m.pop '' -- defaultConfig
end

function m.buildTypes( prj )
	local optimize_minifyEnabled   = { Size = 'true' }
	local optimize_shrinkResources = { Size = 'true' }
	local symbols_debuggable       = { On   = 'true' }

	m.push 'buildTypes'

	for cfg in p.project.eachconfig( prj ) do
		local build_type = string.lower( cfg.buildcfg )

		m.push( '\''..build_type..'\'' )
		p.w( 'minifyEnabled %s',   optimize_minifyEnabled[ cfg.optimize ]   or 'false' )
		p.w( 'shrinkResources %s', optimize_shrinkResources[ cfg.optimize ] or 'false' )
		p.w( 'debuggable %s',      symbols_debuggable[ cfg.symbols ]        or 'false' )
		m.pop '' -- @build_type
	end

	m.pop '' -- buildTypes
end

function m.sourceSets( prj )
	m.push 'sourceSets'
	m.push 'main'

	p.w( 'manifest.srcFile \'%s\'', p.project.getrelative( prj, prj.androidmanifest ) )

	if #prj.javadirs > 0 then
		p.w( 'java.srcDirs %s', table.implode( p.project.getrelative( prj, prj.javadirs ), '\'', '\'', ', ' ) )
	end
	if #prj.resdirs > 0 then
		p.w( 'res.srcDirs %s', table.implode( p.project.getrelative( prj, prj.resdirs ), '\'', '\'', ', ' ) )
	end
	if #prj.assetdirs > 0 then
		p.w( 'assets.srcDirs %s', table.implode( p.project.getrelative( prj, prj.assetdirs ), '\'', '\'', ', ' ) )
	end

	-- Disable automatic ndkBuild tasks
	p.w 'jni.srcDirs = []'

	m.pop '' -- main
	m.pop '' -- sourceSets
end

function m.ndkBuildTasks( prj )
	p.push 'android.buildTypes.all { buildType ->'
	p.w 'String ndkBuildTaskName = \'ndkBuild_\' + buildType.name'
	p.w 'Task ndkBuildTask = tasks.findByPath( ndkBuildTaskName )'
	p.push 'if( ndkBuildTask == null ) {'

	local cfg           = p.project.getfirstconfig( prj )
	local ndk_build_ext = os.ishost( 'windows' ) and '.cmd' or ''

	p.push 'ndkBuildTask = tasks.create( name: ndkBuildTaskName ) {'
	p.push 'doLast {'

	p.push 'exec {'
	p.w( 'commandLine "${android.ndkDirectory}/ndk-build'..ndk_build_ext..'", \'APP_PLATFORM=android-'..prj.minsdkversion..'\', \'APP_BUILD_SCRIPT=Android.mk\', \'PREMAKE_CONFIGURATION=Debug\'' )
	p.pop '}'

	p.push 'exec {'
	if os.ishost( 'windows' ) then
		p.w( 'commandLine \'cmd.exe\', \'/k\', "move /Y \\"${project.projectDir}\\\\obj\\\\local\\\\arm64-v8a\\\\%s\\" \\"${project.projectDir}/%s\\""', cfg.buildtarget.name, p.project.getrelative( prj, cfg.buildtarget.abspath ) )
	else
		p.w( 'commandLine "mv \\"${project.projectDir}/obj/local/arm64-v8a/%s\\" \\"%s\\""', cfg.buildtarget.name, cfg.buildtarget.abspath )
	end
	p.pop '}'

	p.pop '}'
	p.pop '}'

	p.push 'tasks.withType( JavaCompile ) { javaCompileTask ->'
	p.w 'String javaCompileTaskName = javaCompileTask.name'
	p.push 'if( javaCompileTaskName.toLowerCase().startsWith( \'compile\' + buildType.name ) ) {'
	p.w 'javaCompileTask.dependsOn ndkBuildTask'
	p.pop '}'
	p.pop '}'

	p.pop '}'
	p.pop '}'
end

function m.dependencies( prj )
	local project_links = { }

	for _, link in ipairs( prj.links ) do
		local link_prj = p.workspace.findproject( prj.workspace, link )

		if link_prj then
			table.insert( project_links, link_prj )
		end
	end

	if #project_links > 0 then
		m.push 'dependencies'

		for i = 1, #project_links do
			p.w( 'implementation project( \':%s\' )', project_links[ i ].name )
		end

		m.pop ''
	end
end
