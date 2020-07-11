local p = premake

p.api.register {
	name   = 'appid',
	scope  = 'project',
	kind   = 'string',
	tokens = true,
}

p.api.register {
	name  = 'androidabis',
	scope = 'project',
	kind  = 'list:string',
}

p.api.register {
	name  = 'assetdirs',
	scope = 'project',
	kind  = 'list:directory',
}

p.api.register {
	name  = 'javadirs',
	scope = 'project',
	kind  = 'list:directory',
}

p.api.register {
	name  = 'resdirs',
	scope = 'project',
	kind  = 'list:directory',
}

p.api.register {
	name  = 'androidmanifest',
	scope = 'project',
	kind  = 'file',
}

p.api.register {
	name    = 'gradleversion',
	scope   = 'workspace',
	kind    = 'string',
	tokens  = true,
}

p.api.register {
	name  = 'jvmargs',
	scope = 'workspace',
	kind  = 'list:string',
}

p.api.register {
	name   = 'minsdkversion',
	scope  = 'project',
	kind   = 'string',
	tokens = true,
}

p.api.register {
	name   = 'maxsdkversion',
	scope  = 'project',
	kind   = 'string',
	tokens = true,
}
