local path     = (...):match('^.+[%.\\/]') or ''
local grid     = require (path..'grid')
local atlas    = require (path..'atlas')
local map      = require (path..'map')
local isomap   = require (path..'isomap')
local serialize= require (path..'ext.serialize')

local atlasextension = '.atlas'

local cachedImages = setmetatable({},{__mode = 'v'})
local cachedAtlases= setmetatable({},{__mode = 'kv'})

local function getPathComponents(path)
	local dir,name,ext = path:match('^(.-)([^\\/]-)%.?([^\\/%.]*)$')
	if #name == 0 then name = ext; ext = '' end
	return dir,name,ext
end

local function removeUpDirectory(path)
	while path:find('%.%.[\\/]+') do
		path = path:gsub('[^\\/]*[\\/]*%.%.[\\/]+','')
	end
	return path
end

local stripExcessSlash = function(path)
	return path:gsub('[\\/]+','/'):match('^/?(.*)')
end

-- ====================================
-- MODULE
-- ====================================

local l = {}

function l.saveAtlas(atlas,path)
	local t = {
		iWidth    = atlas.iWidth,
		iHeight   = atlas.iHeight,
		qWidth    = atlas.qWidth,
		qHeight   = atlas.qHeight,
		aWidth    = atlas.aWidth,
		aHeight   = atlas.aHeight,
		ox        = atlas.ox,
		oy        = atlas.oy,
		xs        = atlas.xs,
		ys        = atlas.ys,
		properties= grid.new(),
	}
	for x,y,v in grid.iterate(atlas) do
		if v.property then
			t.properties:set(x,y,v.property)
		end
	end
	
	serialize.save(t,path)
end

function l.loadAtlas(path)
	path = stripExcessSlash(path)
	if cachedAtlases[path] then return cachedAtlases[path] end
	local t         = serialize.load(path)
	local atlas     = atlas.new(t.iWidth,t.iHeight,t.qWidth,t.qHeight,t.aWidth,t.aHeight,t.ox,t.oy,t.xs,t.ys)
	local coords    = {}
	for x,y,v in grid.iterate(t.properties) do
		coords[1],coords[2] = x,y
		atlas:setProperty(coords,v)
	end
	cachedAtlases[path] = atlas
	return atlas
end

function l.saveMap(map,path)
	assert(map.imagepath,'Must specify a relative image path (map.imagepath)!')
	
	path              = stripExcessSlash(path)
	local class       = getmetatable(map)
	local dir,name,ext= getPathComponents(path)
	
	assert(love.filesystem.exists( removeUpDirectory(dir..map.imagepath) ) ,'File does not exist for image path!')
	
	local atlasfile   = name..atlasextension
	local t = {
		tw       = map.tw,
		th       = map.th,
		imagepath= map.imagepath,
		atlaspath= map.atlaspath or atlasfile,
		tilegrid = grid.new(),
		type     = class == isomap and 'isometric' or 'orthogonal'
	}
	local grid = map.tilegrid
	for x,y,v in grid:iterate() do
		local index = v.index
		if index then
			local p   = {}
			p.index   = index
			p.sx,p.sy = v.sx,v.sy
			p.angle   = v.angle
			p.property= v.property
			grid.set(t.tilegrid,x,y,p)
		end
	end
	serialize.save(t,path)
	l.saveAtlas(map.atlas,dir..atlasfile)
end

function l.loadMap(path)
	path              = stripExcessSlash(path)
	local dir,name,ext= getPathComponents(path)
	local t           = serialize.load(path)
	local atlaspath   = removeUpDirectory( dir..t.atlaspath )
	local imagepath   = removeUpDirectory( dir..t.imagepath )
	local image       = cachedImages[imagepath] or love.graphics.newImage( imagepath )
	
	cachedImages[imagepath] = image
	
	local atlas       = l.loadAtlas(atlaspath)
	local maptype     = t.type
	local mapobject,mvtilegrid
	local map = maptype == 'orthogonal' and map or isomap
	
	mapobject = map.new(image,atlas,t.tw,t.th)
	mvtilegrid= mapobject.tilegrid
	for x,y,v in grid.iterate(t.tilegrid) do
		mapobject:setAtlasIndex(x,y,v.index)
		local mv   = mvtilegrid(x,y)
		mv.sx,mv.sy= v.sx,v.sy
		mv.angle   = v.angle
		mapobject:setAngle(x,y,v.angle)
	end
	return mapobject
end

return l