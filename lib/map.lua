local DEFAULT_CHUNK_SIZE = 256

local path  = (...):match('^.+%.') or ''
local grid  = require (path..'grid')
local md    = require (path..'mapdata')

local ceil  = math.ceil
local sqrt  = math.sqrt
local floor = math.floor
local lg    = love.graphics

local getSBrange = function(x,y,w,h,sw,sh)
	local gx,gy  = floor(x/sw)+1,floor(y/sh)+1
	local gx2,gy2= ceil((x+w)/sw),ceil((y+h)/sh)
	return gx,gy,gx2,gy2
end

local getQuad = function(self,index)
	local atlas   = self.atlas
	local qx,qy   = atlas:getqViewport(index)
	local qi      = qx..','..qy
	local quad    = self.quads[qi] or lg.newQuad(qx+self.ox,qy+self.oy,self.qw,self.qh,atlas:getImageSize())
	self.quads[qi]= quad   
	return quad
end

local map   = {}
map.__index = map

function map.new(image,atlas,data,mapfunc, ox,oy,qw,qh, tw,th, chunksize)
	local self   = grid.new()
	
	local qw2,qh2= atlas:getqSize()
	qw,qh        = qw or qw2,qh or qh2
	local iw,ih  = atlas:getImageSize()
	tw,th        = tw or qw,th or qh
	ox,oy        = ox or 0,oy or 0
	
	self.tiledata= grid.new()
	self.image   = image
	self.SBwidth = nil
	self.SBheight= nil
	self.gx      = nil
	self.gy      = nil
	self.gx2     = nil
	self.gy2     = nil
	self.quads   = {}
	self.ox      = ox
	self.oy      = oy
	self.qw      = qw
	self.qh      = qh
	self.atlas   = atlas

	chunksize    = chunksize or DEFAULT_CHUNK_SIZE
	local qrows  = ceil(sqrt(chunksize))
	local qcols  = qrows
	chunksize    = qrows*qcols
	self.SBwidth = qcols*tw
	self.SBheight= qrows*th
	
	local iterate = md.iterateData
	if data.grid then iterate = md.iterate end
	
	for x,y, a,b,c,d in iterate(data) do
		local index = mapfunc(x,y,a,b,c,d)
		if index then
			local quad = getQuad(self,index)
			-- real
			local rx,ry= tw*(x-1),th*(y-1)
			local gx,gy= getSBrange(rx,ry,tw,th,self.SBwidth,self.SBheight)
			
			local sb   = grid.get(self,gx,gy) or lg.newSpriteBatch(image,chunksize)
			grid.set(self,gx,gy,sb)			
			local id   = sb:addq(quad,rx,ry)
			
			local tiledata= {
				index   = type(index)== 'table' and ( atlas:getColumns()*(index[2]-1)  +  index[1] ) or index,
				property= nil,
				visible = true,
				quad    = quad,
				sb      = sb,
				id      = id,
				
				x       = rx,
				y       = ry,
				angle   = 0,
				sx      = 1,   sy = 1,
				cx      = qw/2,cy = qh/2,
				}
			
			grid.set(self.tiledata,x,y,tiledata)
		end
	end
	return setmetatable(self,map)
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

function map:getAtlasIndex(tx,ty)
	return grid.get(self.tiledata,tx,ty).index
end

function map:setAtlasIndex(tx,ty,index)
	local quad    = getQuad(self,index)
	local t       = grid.get(self.tiledata,tx,ty)
	t.quad        = quad
	t.index       = type(index)== 'table' and ( self.atlas:getColumns()*(index[2]-1)  +  index[1] ) or index
	local vcoeff  = t.visible and 1 or 0
	t.sb:setq( t.id, quad, t.x+t.cx,t.y+t.cy, t.angle, vcoeff*t.sx,vcoeff*t.sy, t.cx,t.cy)
end

function map:setProperty(tx,ty,value)
	grid.get(self.tiledata,tx,ty).property = value
end

function map:getProperty(tx,ty)
	return grid.get(self.tiledata,tx,ty).property
end

function map:setVisible(tx,ty,bool)
	local t = grid.get(self.tiledata,tx,ty)
	t.sb:setq(t.id,t.quad, t.x+t.cx,t.y+t.cy, t.angle, bool and t.sx or 0,bool and t.sy or 0, t.cx,t.cy)
	t.visible = bool
end

function map:isVisible(tx,ty)
	return grid.get(self.tiledata,tx,ty).visible
end

function map:setFlip(tx,ty,flipx,flipy)
	local t       = grid.get(self.tiledata,tx,ty)
	local vcoeff  = t.visible and 1 or 0
	local sx,sy   = flipx and -1 or 1,flipy and -1 or 1
	t.sb:setq( t.id,t.quad, t.x+t.cx,t.y+t.cy, t.angle, vcoeff*sx,vcoeff*sy, t.cx,t.cy)
	t.sx = sx
	t.sy = sy
end

function map:getFlip(tx,ty)
	local tiledata = grid.get(self.tiledata,tx,ty)
	return tiledata.sx == -1,tiledata.sy == -1
end

function map:setAngle(tx,ty,angle)
	local t       = grid.get(self.tiledata,tx,ty)
	local vcoeff  = t.visible and 1 or 0
	t.sb:setq( t.id,t.quad, t.x+t.cx,t.y+t.cy, angle, vcoeff*t.sx,vcoeff*t.sy, t.cx,t.cy)
	t.angle = angle
end

function map:getAngle(tx,ty)
	return grid.get(self.tiledata,tx,ty).angle
end

function map:setViewport(x,y,w,h)
	if not x then self.gx,self.gy,self.gx2,self.gy2 = nil end
	self.gx,self.gy,self.gx2,self.gy2 = getSBrange(x,y,w,h,self.SBwidth,self.SBheight)
end

function map:draw(...)
	local gx,gy,gx2,gy2= self.gx,self.gy,self.gx2,self.gy2
	local iterator     = grid.iterate
	if gx then iterator= grid.rectangle end
	for gx,gy,sb in iterator(self,gx,gy,gx2,gy2,true) do
		lg.draw(sb, ...)
	end
end

return map