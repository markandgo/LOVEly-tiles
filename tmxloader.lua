local path      = (...):match('^.+[%.\\/]') or ''
local grid      = require(path..'grid')
local atlas     = require(path..'atlas')
local mapdata   = require(path..'mapdata')
local map       = require(path..'map')
local isomap    = require(path..'isomap')
local drawlist  = require(path..'drawlist')
local xmlparser = require(path..'ext.xml')
local unb64     = require ('mime').unb64
local deflate   = require(path..'ext.deflate')
local imageCache= setmetatable({},{__mode== 'v'})

-- ==============================================
-- ADDONS/HACK
-- ==============================================

-- hack for offset/opacity/align to bottom left
local function proxyDraw(self,draw,x,y,...)
	x,y           = x or 0,y or 0
	local opacity = self.opacity
	local lg      = love.graphics
	local r,g,b,a
	if opacity then
		r,g,b,a = lg.getColor()
		lg.setColor(r,g,b,a*opacity)
	end
	-- align bottom left
	y = y+(self.th-self.atlas.qHeight)
	
	local offsets = self.atlas.tileoffset
	if offsets then draw(self,  x+offsets.x,y+offsets.y, ...)
	else draw(self,x,y,...) end
	
	if opacity then lg.setColor(r,g,b,a) end
end

local function applyTmxStyleToDraw(map)
	local olddraw = map.draw	
	function map:draw(...)
		proxyDraw(self,olddraw,...)
	end
end

-- new methods
function atlas:getTileOffsets()
	local to = self.atlas.tileoffset
	return to.x,to.y
end

function atlas:setTileOffsets(x,y)
	local to = self.atlas.tileoffset
	to.x,to.y= x,y
end

function atlas:getTilesetProperty(name)
	return self.properties[name]
end

function atlas:setTilesetProperty(name,value)
	self.properties[name] = value
end

function map:getOpacity()
	return self.opacity
end

function map:setOpacity(opacity)
	self.opacity = opacity
end

function map:getLayerProperty(name)
	return self.properties[name]
end

function map:setLayerProperty(name,value)
	self.properties[name] = value
end

function drawlist:getLayerName(name)
	return self.layernames[name]
end

function drawlist:getAtlas(name)
	return self.atlases[name]
end

-- ==============================================
-- XML HANDLER LOGIC
-- ==============================================

-- ----------------------------------------------
-- PREPARE ELEMENT
-- ----------------------------------------------

local prepareElement = {}
local p = prepareElement

p.map = function()
	local element   = {}
	element.tilesets= {}
	element.layers  = {}
	return element
end

p.tileset = function()
	local element= {}
	element.tiles= {}
	return element
end

p.objectgroup = function()
	local element  = {}
	element.objects= {}
	return element
end

-- ----------------------------------------------
-- INSERT ELEMENT TO PARENT
-- ----------------------------------------------

local insertToParent = {}
local i = insertToParent

i.tileset = function(object,parent)
	parent.tilesets = parent.tilesets or {}
	table.insert(parent.tilesets,object)
end

i.tile = function(object,tileset)
	tileset.tiles[object.id] = object
end

i.property = function(object,properties)
	properties[object.name] = object.value
end

i.layer = function(object,map)
	table.insert(map.layers,object)
end

i.objectgroup = function(object,map)
	table.insert(map.layers,object)
end

i.imagelayer = function(object,map)
	table.insert(map.layers,object)
end

i.object = function(object,objectgroup)
	table.insert(objectgroup.objects,object)
end

local function convertPoints(object)
	local newpoints = {}
	for point in object.points:gmatch '(-?%d+)' do
		point = tonumber(point)
		table.insert(newpoints,point)
	end
	object.points = newpoints
end

i.polygon = function(object,parent)
	convertPoints(object)
	parent.polygon = object
end

i.polyline = function(object,parent)
	convertPoints(object)
	parent.polyline = object
end

-- ==============================================
-- XML HANDLER
-- ==============================================

local handler   = {}
handler.__index = handler

handler.starttag = function(self,name,attr)
	local stack   = self.stack
	local element = prepareElement[name] and prepareElement[name]() or {}
	if attr then
		for k,v in pairs(attr) do
			if not element[k] then
				v = tonumber(v) or v
				v = v == 'true' and true or v == 'false' and false or v
				element[k] = v
			end
		end
	end
	stack.len = stack.len + 1 
	table.insert(self.stack,element)
end

handler.endtag = function(self,name,attr)
	local stack   = self.stack
	local element = table.remove(stack,stack.len)
	stack.len     = stack.len - 1
	local parent  = stack[stack.len]
	if insertToParent[name] then 
		insertToParent[name](element,parent) 
	else
		parent[name] = element
	end
end

handler.text = function(self,text)
	self.stack[self.stack.len][1] = text
end

local function newHandler()
	local h    = {root = {},stack = {len = 1}}
	h.stack[1] = h.root
	
	return setmetatable(h,handler)
end

-- ==============================================
-- PATH FUNCTIONS
-- ==============================================

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
	return path:gsub('[\\/]+','/')
end

-- ==============================================
-- HELPER LOAD FUNCTIONS
-- ==============================================
local function byteToNumber(str)
	local num = 0
	local len = #str
	for i = 1,len do
		num = num + string.byte(str,i) * 256^(i-1)
	end
	return num
end

local streamData = function(tmxmap,layer)
	local data  = layer.data
	local str   = data.encoding == 'base64' and unb64(data[1]) or data[1]
	local bytes = {len = 0}
	
	local byteconsume = function(code) 
		bytes.len       = bytes.len+1
		bytes[bytes.len]= string.char(code)
	end
	local handler = { input = str, output = byteconsume, disable_crc = true }
	
	if data.compression == 'gzip' then
		deflate.gunzip( handler )
		str = table.concat(bytes)
	elseif data.compression == 'zlib' then
		deflate.inflate_zlib( handler )
		str = table.concat(bytes)
	end
	
	return coroutine.wrap(function()
		local divbits = 2^29
		local pattern = data.encoding == 'base64' and '(....)' or '(%d+)'
		local count   = 0
		local w,h     = layer.width or tmxmap.width,layer.height or tmxmap.height
		
		
		for num in str:gmatch(pattern) do
			count = count + 1
			
			if data.encoding == 'base64' then 
				num = byteToNumber(num)
			else 
				num = tonumber(num) 
			end
			
			-- bit 32: xflip
			-- bit 31: yflip
			-- bit 30: antidiagonal flip
			
			local gid         = num % divbits
			local flips       = math.floor(num / 2^29)
			local xflip       = math.floor(flips / 4) == 1
			local yflip       = math.floor( (flips % 4) / 2) == 1
			local diagflip    = flips % 2

--[[
-\- diag flip first!
flipx flipy diagflip --> flipx flipy angle -- or --> flipx flipy angle
1     0     1            0     0      90             1     1     -90     
1     1     1            1     0      90             0     1     -90
0     1     1            1     1      90             0     0     -90
0     0     1            0     1      90             1     0     -90
--]]
			
			local angle = 0
			if diagflip == 1 then
				angle      = math.pi/2
				xflip,yflip= yflip,not xflip
			end
			if xflip and yflip then angle = angle+math.pi; xflip,yflip = false,false end
			
			local y = math.ceil(count/w)
			local x = count - (y-1)*w
			
			coroutine.yield(gid,x,y,angle,xflip,yflip)
		end
	end)
end

local function buildImage(tmxmap,parent)
	local imagetable= parent.image
	local imagepath = stripExcessSlash(  removeUpDirectory(tmxmap.path..imagetable.source)  )
	local image     = imageCache[imagepath] or love.graphics.newImage(imagepath)
	imageCache[path]= image
	parent.image    = image
	parent.imagepath= imagetable.source
	parent.trans    = imagetable.trans
	parent.__element= 'imagelayer'
end

local function mergeExternalTSX(tmxmap,tileset)
	local h        = newHandler()
	local tsxparser= xmlparser(h)
	local path     = stripExcessSlash( removeUpDirectory(tmxmap.path..tileset.source) )
	local str      = love.filesystem.read(path)
	tsxparser:parse(str)
	local tsxtable = h.root.tilesets[1]
	
	for i,v in pairs(tsxtable) do
		tileset[i] = v
	end
end

local function buildAtlasesAndImages(tmxmap)
	local tilesets = tmxmap.tilesets
	for _,tileset in ipairs(tilesets) do
		if tileset.source then 
			mergeExternalTSX(tmxmap,tileset)
		end
	
		local offset    = tileset.margin or 0
		local space     = tileset.spacing or 0
		buildImage(tmxmap,tileset) 
		local iw,ih     = tileset.image:getWidth(),tileset.image:getHeight()
		local tw,th     = tileset.tilewidth,tileset.tileheight
		local atlasW    = math.floor( (iw-offset*2+space)/(tw+space) ) * (tw+space) - space
		local atlasH    = math.floor( (ih-offset*2+space)/(th+space) ) * (th+space) - space
		local atlas     = atlas.new(iw,ih,tw,th,atlasW,atlasH,offset,offset,space,space)
		atlas.properties= tileset.properties
		-- hack for tileoffset
		atlas.tileoffset= tileset.tileoffset
		tileset.atlas   = atlas
		
		
		for i,tile in pairs(tileset.tiles) do
			if tile.properties then
				local properties = {}
				for key,value in pairs(tile.properties) do
					properties[key] = value
				end
				atlas:setProperty(tile.id+1,properties)
			end
		end		
	end
end

local function storeAtlasesByName(tmxmap,dl)
	dl.atlases = {}
	for i,tileset in pairs(tmxmap.tilesets) do
		dl.atlases[tileset.name] = tileset.atlas
	end
end

local function getTilesetAndMap(gid,tmxmap,layer)
	local tilesets = tmxmap.tilesets
	local mapnew   = tmxmap.orientation == 'orthogonal' and map.new or tmxmap.orientation == 'isometric' and isomap.new
	local chosen
	for _,tileset in ipairs(tilesets) do
		if gid >= tileset.firstgid then
			chosen = tileset
		end
	end
	local tileset = chosen
	local map     = mapnew(tileset.image,tileset.atlas,tmxmap.tilewidth,tmxmap.tileheight)
	applyTmxStyleToDraw(map)
	map.imagepath = tileset.imagepath
	map.properties= layer.properties
	map.opacity   = layer.opacity
	map:setViewRange(1,1,tmxmap.width,tmxmap.height)
	map:setAtlasPath(tileset.name..'.atlas')
	return tileset,map
end

local function storeLayersByName(tmxmap,dl)
	dl.layernames = {}
	for i,layer in pairs(tmxmap.layers) do
		dl.layernames[layer.name] = layer
	end
end

local tmxToTable = function(filename)
	local h        = newHandler()
	local tmxparser= xmlparser(h)
	local hasFile  = love.filesystem.isFile(filename)
	if not hasFile then return nil,'TMX map not found: '..filename end
	local str      = love.filesystem.read(filename)
	tmxparser:parse(str)
	local tmxmap   = h.root.map
	
	local dir      = getPathComponents(filename)
	tmxmap.path    = dir
	
	return tmxmap
end

-- ==============================================
-- TMX LOADER
-- ==============================================
local DEFAULT_CHUNK_SIZE = 1000

local worker = function(filename,mode,chunkSize)
	local tmxmap,err = tmxToTable(filename)
	if err then return nil,err end
	
	local dl = drawlist.new()
	if mode == 'chunk' then coroutine.yield(dl) end
	dl.properties = tmxmap.properties
	
	buildAtlasesAndImages(tmxmap)
	storeAtlasesByName(tmxmap,dl)
	
	local chunkSize  = chunkSize or DEFAULT_CHUNK_SIZE
	local chunkCount = 0
	
	for i,layer in ipairs(tmxmap.layers) do
		local isTileLayer = layer.data
		if isTileLayer then
			local tileset,map,firstgid
			for gid,x,y,angle,flipx,flipy in streamData(tmxmap,layer) do
				if gid ~= 0 then
					if not (tileset and map) then
						tileset,map = getTilesetAndMap(gid,tmxmap,layer)
						firstgid    = tileset.firstgid
						
						dl:insert(map,nil,1,1,layer.visible ~= 0) 
						dl:setLayerPath(dl:totalLayers(),layer.name..'.map')
					end
					local index = gid-firstgid+1
					map:setAtlasIndex(x,y,index,angle,flipx,flipy)
				end
				chunkCount = chunkCount + 1
				if mode == 'chunk' and chunkCount == chunkSize then 
					chunkCount = 0
					coroutine.yield() 
				end
			end
		else
			function layer:draw() end
			if layer.image then buildImage(tmxmap,layer) else layer.__element = 'objectgroup' end
			dl:insert(layer)
			chunkCount = chunkCount + 1
		end
		
		if mode == 'chunk' and chunkCount == chunkSize then 
			chunkCount = 0
			coroutine.yield() 
		end
	end
	storeLayersByName(tmxmap,dl)
	
	if mode == 'all' then return dl end
end

return function(filename,mode,chunkSize)
	mode = mode or 'all'
	assert(mode == 'all' or mode == 'chunk', 'Invalid mode as 2nd argument')
	if mode == 'chunk' then
		local co = coroutine.create(worker)
		local ok,drawlist,err = coroutine.resume(co,filename,mode,chunkSize)
		err = not ok and drawlist or err
		if err then return nil,err end
		
		local resume,status = coroutine.resume,coroutine.status
		local loader = function()
			local ok,err   = resume(co)
			local finished = status(co) == 'dead'
			return finished,err
		end
		return drawlist,loader
	else
		return worker(filename,mode)
	end
end