local p             = premake
local androidstudio = p.extensions.androidstudio

--
-- Gradle projects are directory-based, which means that two projects cannot share the same location.
-- For that reason, we change the location to one that is unique to that project.
--

p.override( p.project, 'bake', function( base, self )
	if _ACTION == 'android-studio' then
		self.location = path.join( self.location, self.name )
	end

	base( self )
end )

p.override( p.oven, 'bakeConfig', function( base, wks, prj, buildcfg, platform, extraFilters )
	local ctx = base( wks, prj, buildcfg, platform, extraFilters )

	if ctx.project and _ACTION == 'android-studio' then
		ctx.location = path.join( ctx.location, ctx.project.name )
	end

	return ctx
end )
