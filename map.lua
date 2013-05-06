local PREALLOCATE_SB_SIZE = 256

local path  = (...):match('^.+[%.\\/]') or ''
local grid  = require (path..'grid')

local ceil  = math.ceil
local sqrt  = math.sqrt
local floor = math.floor
local lg    = love.graphics

local dummyquad = lg.newQuad(0,0,1,1,1,1)

local getSBrange = function(x,y,w,h,sw,sh)
	local gx,gy  = floor(x/sw)+1,floor(y/sh)+1
	local gx2,gy2= ceil((x+w)/sw),ceil((y+h)/sh)
	return gx,gy,gx2,gy2
end

local preallocateSB = function(self,gx,gy)
	local sb = lg.newSpriteBatch(self.image,PREALLOCATE_SB_SIZE)
	sb:bind()
	grid.set(self,gx,gy,sb)
	local ox,oy       = (gx-1)*self.SBwidth,(gy-1)*self.SBheight
	local qrows,qcols = self.SBwidth/self.tw, self.SBheight/self.th
	local tox,toy     = qcols*(gx-1),qrows*(gy-1)
	for y = 1,qrows do
		for x = 1,qcols do
			local tiledata= {
				quad    = nil,
				index   = nil,
				property= nil,
				sb      = sb,
				id      = sb:addq(dummyquad,0,0,0,0),
				x       = self.tw*(x-1) + ox,
				y       = self.th*(y-1) + oy,
				angle   = 0,
				sx      = 1,
				sy      = 1,
			}
			grid.set(self.tilegrid,tox+x,toy+y,tiledata)
		end
	end
	sb:unbind()
end

local setQuad = function(self,t)
	t.sb:setq( t.id,t.quad, t.x+self.hw,t.y+self.hh, t.angle, t.sx,t.sy, self.hw,self.hh)	
end

local getQuad = function(self,index)
	local atlas   = self.atlas
	local qx,qy   = atlas:getqViewport(index)
	local qi      = qx..','..qy
	local qw,qh   = atlas:getqSize()
	local quad    = self.quads[qi] or lg.newQuad(qx,qy,qw,qh,atlas:getImageSize())
	self.quads[qi]= quad   
	return quad
end

local map   = setmetatable({},{__call = function(self,...) return self.new(...) end})
map.__index = map
map.__call  = function(self,tx,ty) return map.getAtlasIndex(self,tx,ty) end

function map.new(image,atlas, tw,th)
	local self   = grid.new()
	
	local qw,qh  = atlas:getqSize()
	tw,th        = tw or qw,th or tw or qh
	
	local qrows  = floor(sqrt(PREALLOCATE_SB_SIZE))
	local qcols  = qrows
	
	self.SBwidth = qcols*tw
	self.SBheight= qrows*th	
	
	self.tilegrid = grid.new()
	self.image    = image
	self.imagepath= nil
	self.atlaspath= nil
	self.gx       = nil
	self.gy       = nil
	self.gx2      = nil
	self.gy2      = nil
	self.quads    = setmetatable({},{__mode = 'kv'})
	self.atlas    = atlas
	self.hw       = qw/2
	self.hh       = qh/2
	self.tw       = tw
	self.th       = th
	
	return setmetatable(self,map)
end

function map:export()
	local mapwidth,mapheight = 0,0
	local maparray = {}
	for x,y,v in self.tilegrid:iterate() do
		if v.index then
			mapwidth = math.max(mapwidth,x)
			mapheight= math.max(mapheight,y)
		end
	end
	for y = 1,mapheight do
		local ioffset = (y-1)*mapwidth
		for x = 1,mapwidth do
			local t    = grid.get(self.tilegrid,x,y)
			local i    = x+ioffset
			local index= t and t.index or 0
			maparray[i]= index
		end
	end
	maparray.width,maparray.height = mapwidth,mapheight
	return maparray
end

function map:setAtlasIndex(tx,ty,index,  angle,flipx,flipy)
	local t = grid.get(self.tilegrid,tx,ty)
	
	if not t then
		local rx,ry= self.tw*(tx-1),self.th*(ty-1)
		local gx,gy= getSBrange(rx,ry,self.tw,self.th,self.SBwidth,self.SBheight)
		preallocateSB(self,gx,gy)
		
		t = grid.get(self.tilegrid,tx,ty)
	end
	
	if not index then
		t.quad    = nil
		t.index   = nil
		t.angle   = nil
		t.sx      = nil
		t.sy      = nil
		t.property= nil
		t.sb:setq( t.id, dummyquad, 0,0,0,0)
		return
	end
	
	
	local quad= getQuad(self,index)
	t.quad    = quad
	t.index   = type(index)== 'table' and ( self.atlas:getColumns()*(index[2]-1)  +  index[1] ) or index	
	t.angle   = angle or 0
	t.sx      = flipx and -1 or 1
	t.sy      = flipy and -1 or 1
	
	setQuad(self,t)
end

function map:getAtlasIndex(tx,ty)
	local t = grid.get(self.tilegrid,tx,ty)
	return t and t.index
end

function map:getAtlas()
	return self.atlas
end

function map:setAtlasPath(atlaspath)
	self.atlaspath = atlaspath
end

function map:getAtlasPath()
	return self.atlaspath
end

function map:getTileSize()
	return self.tw,self.th
end

function map:setImagePath(imagepath)
	self.imagepath = imagepath
end

function map:getImagePath()
	return self.imagepath
end

function map:setImage(image)
	self.image = image
	for x,y,sb in grid.iterate(self) do
		sb:setImage(image)
	end
end

function map:getImage()
	return self.image
end

function map:setProperty(tx,ty,value)
	grid.get(self.tilegrid,tx,ty).property = value
end

function map:getProperty(tx,ty)
	local tiledata = grid.get(self.tilegrid,tx,ty)
	return tiledata and tiledata.property
end

function map:setFlip(tx,ty,flipx,flipy)
	local t    = grid.get(self.tilegrid,tx,ty)
	local sx,sy= flipx and -1 or 1,flipy and -1 or 1
	t.sx       = sx
	t.sy       = sy
	setQuad(self,t)
end

function map:getFlip(tx,ty)
	local tiledata = grid.get(self.tilegrid,tx,ty)
	if tiledata then return tiledata.sx == -1,tiledata.sy == -1 end
end

function map:setAngle(tx,ty,angle)
	local t = grid.get(self.tilegrid,tx,ty)
	t.angle = angle
	setQuad(self,t)
end

function map:getAngle(tx,ty)
	local tiledata = grid.get(self.tilegrid,tx,ty)
	return tiledata and tiledata.angle
end

function map:setViewport(x,y,w,h)
	if not x then self.gx,self.gy,self.gx2,self.gy2 = nil end
	self.gx,self.gy,self.gx2,self.gy2 = getSBrange(x,y,w,h,self.SBwidth,self.SBheight)
end

function map:draw(...)
	local gx,gy,gx2,gy2 = self.gx,self.gy,self.gx2,self.gy2
	local iterate       = grid.rectangle
	if not gx then iterate = grid.iterate end
	for gx,gy,sb in iterate(self,gx,gy,gx2,gy2,true) do
		lg.draw(sb, ...)
	end
end

return map