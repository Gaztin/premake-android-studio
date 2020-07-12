local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.android_manifest_dot_xml = m

--
-- Generate the 'AndroidManifest.xml' file for library projects
--

function m.generate( prj )
	p.w '<?xml version="1.0" encoding="utf-8"?>'
	p.push '<manifest'
	p.w 'xmlns:android="http://schemas.android.com/apk/res/android"'
	p.w( 'package="%s"', prj.appid )
	p.w 'android:versionCode="1"'
	p.w 'android:versionName="1.0">'
	p.outln ''
	p.w( '<uses-sdk android:minSdkVersion="%s" android:maxSdkVersion="%s" android:targetSdkVersion="%s" />', prj.minsdkversion, prj.maxsdkversion, prj.maxsdkversion )
	p.outln ''
	p.w '<application/>'
	p.outln ''
	p.pop '</manifest>'
end
