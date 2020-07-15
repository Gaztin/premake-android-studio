local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.android_manifest_dot_xml = m

--
-- Generate the 'AndroidManifest.xml' file for library projects
--

function m.generate( prj )
	p.w '<?xml version="1.0" encoding="utf-8"?>'
	p.push '<manifest xmlns:android="http://schemas.android.com/apk/res/android"'
	p.w( 'package="%s"', prj.appid )
	p.w 'android:versionCode="1"'
	p.w 'android:versionName="1.0" >'
	p.outln ''
	p.push( '<uses-sdk' )
	p.w( 'android:minSdkVersion="%s"', prj.minsdkversion )
	p.w( 'android:maxSdkVersion="%s"', prj.maxsdkversion )
	p.w( 'android:targetSdkVersion="%s" />', prj.maxsdkversion )
	p.pop()
	p.outln ''
	p.w '<application />'
	p.outln ''
	p.pop '</manifest>'
end
