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

	m.premakeConfigClass( prj )

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
	m.ndkBuildTasks( prj )
	m.pop '' -- android
	
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

function m.premakeConfigClass( prj )
	p.push 'class PremakeConfig {'
	p.w 'public String targetDir'
	p.w 'public String targetName'
	p.w 'public String extraArgs'
	p.pop '}'
	p.outln ''
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

	m.push 'ndk'
	p.w( 'abiFilters \'%s\'', table.concat( prj.platforms, '\', \'' ) )
	m.pop ''

	m.pop '' -- defaultConfig
end

function m.buildTypes( prj )
	local buildcfg_seen = { }

	m.push 'buildTypes'

	for cfg in p.project.eachconfig( prj ) do
		if not buildcfg_seen[ cfg.buildcfg ] then
			local build_type = string.lower( cfg.buildcfg )

			local shrink_resources = androidstudio.isApp( prj ) and p.config.isOptimizedBuild( cfg )
			local minify_enabled   = p.config.isOptimizedBuild( cfg )
			local debuggable       = p.config.isDebugBuild( cfg )

			m.push( '\''..build_type..'\'' )
			p.w( 'shrinkResources %s', iif( shrink_resources, 'true', 'false' ) )
			p.w( 'minifyEnabled %s', iif( minify_enabled, 'true', 'false' ) )
			p.w( 'debuggable %s', iif( debuggable, 'true', 'false' ) )
			m.pop '' -- @build_type

			buildcfg_seen[ cfg.buildcfg ] = true
		end
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
	p.push 'buildTypes.all { buildType ->'
	p.w 'String ndkBuildTaskName = \'ndkBuild_\' + buildType.name'
	p.w 'Task ndkBuildTask = tasks.findByPath( ndkBuildTaskName )'
	p.push 'if( ndkBuildTask == null ) {'

	p.w 'HashMap abiConfigs = new HashMap<String, PremakeConfig>()'
	p.w 'String buildConfig'
	p.push 'switch( buildType.name ) {'

	local abi_configs = { }

	for cfg in p.project.eachconfig( prj ) do
		abi_configs[ cfg.buildcfg ] = abi_configs[ cfg.buildcfg ] or { }
		table.insert( abi_configs[ cfg.buildcfg ], cfg )
	end

	for buildcfg, cfglist in pairs( abi_configs ) do
		p.push( 'case \'%s\':', buildcfg:lower() )

		p.w( 'buildConfig = \'%s\'', buildcfg )

		for _, cfg in ipairs( cfglist ) do
			local relative_targetdir = p.project.getrelative( prj, cfg.buildtarget.directory )
			local extra_args         = { }

			if cfg.flags.MultiProcessorCompile then
				table.insert( extra_args, '-j' )
			end

			p.w( 'abiConfigs.put( \'%s\', new PremakeConfig() )', cfg.platform )
			p.w( 'abiConfigs[ \'%s\' ].targetDir = \'%s\'', cfg.platform, relative_targetdir )
			p.w( 'abiConfigs[ \'%s\' ].targetName = \'%s\'', cfg.platform, cfg.buildtarget.name )
			p.w( 'abiConfigs[ \'%s\' ].extraArgs = \'%s\'', cfg.platform, table.concat( extra_args, ' ' ) )
		end

		p.w 'break'
		p.pop()
	end

	p.pop '}'

	local ndk_build_ext = os.ishost( 'windows' ) and '.cmd' or ''

	p.push 'ndkBuildTask = tasks.create( name: ndkBuildTaskName ) {'
	p.push 'doLast {'

	for _, abi in ipairs( prj.platforms ) do
		local app_stl     = iif( prj.staticruntime == p.ON, 'c++_static', 'c++_shared' )
		local target_dir  = '${abiConfigs[\''..abi..'\'].targetDir}'
		local target_name = '${abiConfigs[\''..abi..'\'].targetName}'
		local extra_args  = '${abiConfigs[\''..abi..'\'].extraArgs}'

		p.w( 'exec { commandLine "${android.ndkDirectory}/ndk-build'..ndk_build_ext..'", "NDK_PROJECT_PATH=${project.projectDir}", \'APP_PLATFORM=android-'..prj.minsdkversion..'\', \'APP_BUILD_SCRIPT=Android.mk\', \'APP_ABI='..abi..'\', "PREMAKE_CONFIGURATION=${buildConfig}", "'..extra_args..'"'..iif( prj.kind ~= p.STATICLIB, ', "APP_STL='..app_stl..'"', '' )..' }' )

		if os.ishost( 'windows' ) then
			p.w( 'exec { commandLine \'cmd.exe\', \'/C\', "if not exist \\"${project.projectDir}/'..target_dir..'\\" md \\"${project.projectDir}/'..target_dir..'\\"", ">NUL" }' )
			p.w( 'exec { commandLine \'cmd.exe\', \'/C\', "move /Y \\"${project.projectDir}/obj/local/'..abi..'\\\\'..target_name..'\\" \\"${project.projectDir}/'..target_dir..'/'..target_name..'\\"", ">NUL" }' )
		else
			p.w( 'exec { commandLine "mkdir -p \\"${project.projectDir}/'..target_dir..'\\" }' )
			p.w( 'exec { commandLine "mv \\"${project.projectDir}/obj/local/'..abi..'/'..target_dir..'/'..target_name..'\\" \\"${project.projectDir}/'..target_dir..'/'..target_name..'\\"" }' )
		end
	end

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
