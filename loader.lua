local path     = (...):match('^.+[%.\\/]') or ''
local grid     = require (path..'grid')
local atlas    = require (path..'atlas')
local map      = require (path..'map')
local isomap   = require (path..'isomap')
local mapdata  = require (path..'mapdata')
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
	if not t then return nil,'No file was found for the specified path' end
	
	local atlas     = atlas.new(t.iWidth,t.iHeight,t.qWidth,t.qHeight,t.aWidth,t.aHeight,t.ox,t.oy,t.xs,t.ys)
	local coords    = {}
	for x,y,v in grid.iterate(t.properties) do
		coords[1],coords[2] = x,y
		atlas:setProperty(coords,v)
	end
	return atlas
end

function l.saveMap(map,path)
	if not map.imagename then return 'Must specify a relative image path (map.imagename)!' end
	
	path              = stripExcessSlash(path)
	local class       = getmetatable(map)
	local dir,name,ext= getPathComponents(path)
	
	if not love.filesystem.exists( removeUpDirectory(dir..map.imagename) ) then return 'File does not exist for image path!' end
	
	local t = {
		tw       = map.tw,
		th       = map.th,
		imagename= map.imagename,
		atlasname= map.atlasname or name..DEFAULT_ATLAS_EXTENSION,
		maparray = map:export(1),
		type     = class == isomap and 'isometric' or 'orthogonal'
	}
	
	local grid  = map.tilegrid
	local array = t.maparray
	for x,y,v in grid:iterate() do
		local index = v.index
		if index then
			local flip_meta = v.sx ~= 1 or v.sy ~= 1
			local angle_meta= v.angle ~= 0
			if angle_meta or flip_meta then
				local p   = {
					index   = nil,
					sx      = nil,
					sy      = nil,
					angle   = nil,
					property= nil,
				}
				p.index   = index
				if flip_meta then
					p.sx,p.sy = v.sx,v.sy
				end
				if angle_meta then
					p.angle = v.angle
				end
				p.property= copyProperty(v.property)
				local i   = (y-1)*array.width+x
				array[i]  = p
			end
		end
	end
	
	local _,err = serialize.save(t,path)
	if err then return false,err end
	
	local fullatlasname = removeUpDirectory(dir..t.atlasname)
	return l.saveAtlas(map.atlas,fullatlasname)
end

function l.loadMap(path)
	path              = stripExcessSlash(path)
	local dir,name,ext= getPathComponents(path)
	local t           = serialize.load(path)
	
	if not t then return nil,'No file was found for the specified path' end
	
	local atlasname   = removeUpDirectory( dir..t.atlasname )
	local imagename   = removeUpDirectory( dir..t.imagename )
	local image       = cachedImages[imagename] or love.graphics.newImage( imagename )
	
	cachedImages[imagename] = image
	
	local atlas      = l.loadAtlas(atlasname)
	local maptype    = t.type
	local mapNew     = maptype== 'orthogonal' and map.new or isomap.new
	local mapobject  = mapNew(image,atlas,t.tw,t.th)
	local maparray   = t.maparray
	local maptilegrid= mapobject.tilegrid
	
	mapobject:setAtlasName(t.atlasname)
	mapobject:setImageName(t.imagename)
	mapobject:setViewRange(1,1,maparray.width,maparray.height)
	
	for x,y,v in mapdata.array(maparray,maparray.width,maparray.height) do
		local isIndex = type(v) == 'number'
		if isIndex then
			if v > 0 then mapobject:setAtlasIndex(x,y,v) end
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
		local mapname  = layer.layername or name..'_layer_'..i..DEFAULT_MAP_EXTENSION
		layers[i] = {
			isDrawable  = settings.isDrawable,
			xtransfactor= settings.xtransfactor,
			ytransfactor= settings.ytransfactor,
			path        = mapname,
			isDummy     = nil,
		}
		local class    = getmetatable(layer)
		if class == map or class == isomap then
			local mappath = removeUpDirectory(dir..mapname)
			l.saveMap(layer,mappath)
		else
			layers[i].isDummy = true
		end
	end
	return serialize.save(t,path)
end

function l.loadDrawList(path)
	path              = stripExcessSlash(path)
	local dir,name,ext= getPathComponents(path)
	
	local t           = serialize.load(path)
	if not t then return nil,'No file was found for the specified path' end
	
	local dl = drawlist.new()
	dl:setTranslation(t.x,t.y)
	
	for i,layer in ipairs(t.layers) do
		local newlayer
		if layer.isDummy then
			newlayer = {}
			newlayer.layername = layer.path
		else
			local mappath = removeUpDirectory(dir..layer.path)
			newlayer      = l.loadMap(mappath)
			newlayer:setLayerName(layer.path)
		end
		dl:insert(newlayer,i,layer.xtransfactor,layer.ytransfactor,layer.isDrawable)
	end
	return dl
end

return l