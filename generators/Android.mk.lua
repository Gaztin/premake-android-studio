local p             = premake
local androidstudio = p.extensions.androidstudio
local m             = { }

androidstudio.android_dot_mk = m

--
-- Generate the 'Android.mk' file
--

function m.generate( prj )
	p.w( 'LOCAL_PATH := $(call my-dir)' )
	p.w( 'include $(CLEAR_VARS)' )
	p.w( 'LOCAL_MODULE := %s', prj.name )

	m.localSrcFiles( prj )

	if( prj.kind == 'StaticLib' ) then
		p.w( 'include $(BUILD_STATIC_LIBRARY)' )
	else
		p.w( 'include $(BUILD_SHARED_LIBRARY)' )
	end
end

--
-- Utility functions
--

function m.localSrcFiles( prj )
	local local_src_files = { }

	p.tree.traverse( p.project.getsourcetree( prj ), {
		onleaf = function( node, depth )
			if( path.iscppfile( node.extension ) or path.iscfile( node.extension ) ) then
				table.insert( local_src_files, node.abspath )
			end
		end
	} )

	if( #local_src_files > 0 ) then
		p.w( 'LOCAL_SRC_FILES := %s', table.concat( local_src_files, ' \\\n\t' ) )
	end
end
