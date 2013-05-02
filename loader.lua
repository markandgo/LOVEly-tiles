local path     = (...):match('^.+[%.\\/]') or ''
local grid     = require (path..'grid')
local atlas    = require (path..'atlas')
local map      = require (path..'map')
local isomap   = require (path..'isomap')
local drawlist = require (path..'drawlist')
local serialize= require (path..'ext.serialize')

local DEFAULT_ATLAS_EXTENSION = '.atlas'
local DEFAULT_MAP_EXTENSION   = '.map'

local cachedImages = setmetatable({},{__mode = 'v'})

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

local copyProperty = function(p)
	local ptype = type(p)
	if ptype ~= 'table' then return p end
	
	local copy = {}
	for i,v in pairs(t) do
		local itype = type(i)
		local vtype = type(v)
		if itype ~= 'table' and vtype ~= 'table' then
			copy[i] = v
		end
	end
	return copy
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
			t.properties:set(x,y,copyProperty(t.property))
		end
	end
	
	return serialize.save(t,path)
end

function l.loadAtlas(path)
	path = stripExcessSlash(path)
	
	local t         = serialize.load(path)
	if not t then return _,'No file was found for the specified path' end
	
	local atlas     = atlas.new(t.iWidth,t.iHeight,t.qWidth,t.qHeight,t.aWidth,t.aHeight,t.ox,t.oy,t.xs,t.ys)
	local coords    = {}
	for x,y,v in grid.iterate(t.properties) do
		coords[1],coords[2] = x,y
		atlas:setProperty(coords,v)
	end
	return atlas
end

function l.saveMap(map,path)
	if not map.imagepath then return 'Must specify a relative image path (map.imagepath)!' end
	
	path              = stripExcessSlash(path)
	local class       = getmetatable(map)
	local dir,name,ext= getPathComponents(path)
	
	if not love.filesystem.exists( removeUpDirectory(dir..map.imagepath) ) then return 'File does not exist for image path!' end
	
	local t = {
		tw       = map.tw,
		th       = map.th,
		imagepath= map.imagepath,
		atlaspath= map.atlaspath or name..DEFAULT_ATLAS_EXTENSION,
		tilegrid = grid.new(),
		type     = class == isomap and 'isometric' or 'orthogonal'
	}
	
	local grid = map.tilegrid
	for x,y,v in grid:iterate() do
		local index = v.index
		if index then
			local no_flip_meta = v.sx == 1 and v.sy == 1
			local no_angle_meta= v.angle == 0
			if no_angle_meta and no_flip_meta and not v.property then
				grid.set(t.tilegrid,x,y,index)
			else
				local p   = {
					index   = nil,
					sx      = nil,
					sy      = nil,
					angle   = nil,
					property= nil,
				}
				p.index   = index
				if not no_flip_meta then
					p.sx,p.sy = v.sx,v.sy
				end
				if not no_angle_meta then
					p.angle = v.angle
				end
				p.property = copyProperty(v.property)
				grid.set(t.tilegrid,x,y,p)
			end
		end
	end
	
	local _,err = serialize.save(t,path)
	if err then return false,err end
	
	local fullatlaspath = removeUpDirectory(dir..t.atlaspath)
	return l.saveAtlas(map.atlas,fullatlaspath)
end

function l.loadMap(path)
	path              = stripExcessSlash(path)
	local dir,name,ext= getPathComponents(path)
	local t           = serialize.load(path)
	
	if not t then return _,'No file was found for the specified path' end
	
	local atlaspath   = removeUpDirectory( dir..t.atlaspath )
	local imagepath   = removeUpDirectory( dir..t.imagepath )
	local image       = cachedImages[imagepath] or love.graphics.newImage( imagepath )
	
	cachedImages[imagepath] = image
	
	local atlas      = l.loadAtlas(atlaspath)
	local maptype    = t.type
	local mapNew     = maptype== 'orthogonal' and map.new or isomap.new
	local mapobject  = mapNew(image,atlas,t.tw,t.th)
	
	mapobject:setAtlasPath(t.atlaspath)
	mapobject:setImagePath(t.imagepath)
	
	local maptilegrid= mapobject.tilegrid
	
	for x,y,v in grid.iterate(t.tilegrid) do
		local isIndex = type(v) == 'number'
		if isIndex then
			mapobject:setAtlasIndex(x,y,v)
		else
			mapobject:setAtlasIndex(x,y,v.index)
			local mv   = maptilegrid(x,y)
			mv.sx,mv.sy= v.sx or 1,v.sy or 1
			mv.angle   = v.angle or 0
			mapobject:setAngle(x,y,v.angle)
		end
	end
	return mapobject
end

function l.saveDrawList(drawlist,path)
	path              = stripExcessSlash(path)
	local dir,name,ext= getPathComponents(path)
	
	local t      = {layers= {}}
	t.x,t.y      = drawlist:getTranslation()
	local layers = t.layers
	
	for i,layer in pairs(drawlist.layers) do
		local settings = drawlist.settings[layer]
		local class    = getmetatable(layer)
		if class == map or class == isomap then
			local mapname  = settings.path or name..'_layer_'..i..DEFAULT_MAP_EXTENSION
			layers[i] = {
				isDrawable  = settings.isDrawable,
				xtransfactor= settings.xtransfactor,
				ytransfactor= settings.ytransfactor,
				path        = mapname,
			}
			local mappath = removeUpDirectory(dir..mapname)
			l.saveMap(layer,mappath)
		end
	end
	return serialize.save(t,path)
end

function l.loadDrawList(path)
	path              = stripExcessSlash(path)
	local dir,name,ext= getPathComponents(path)
	
	local t           = serialize.load(path)
	if not t then return _,'No file was found for the specified path' end
	
	local dl = drawlist.new()
	dl:setTranslation(t.x,t.y)
	
	for i,layer in ipairs(t.layers) do
		local mappath = removeUpDirectory(dir..layer.path)
		local map     = l.loadMap(mappath)
		dl:insert(map,i,layer.xtransfactor,layer.ytransfactor,layer.isDrawable)
	end
	return dl
end

return l