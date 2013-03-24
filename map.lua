local DEFAULT_CHUNK_SIZE = 256

local path  = (...):match('^.+%.') or ''
local grid  = require (path..'grid')
local md    = require (path..'mapdata')

local ceil  = math.ceil
local floor = math.floor
local lg    = love.graphics
local ipairs= ipairs

local getSBrange = function(x,y,w,h,sw,sh)
	local gx,gy  = floor(x/sw)+1,floor(y/sh)+1
	local gx2,gy2= ceil((x+w)/sw),ceil((y+h)/sh)
	return gx,gy,gx2,gy2
end

local map   = {}
map.__index = map

function map.new(image,atlas,data,mapfunc,tw,th,chunksize)
	local self   = grid.new()

	local qw,qh  = atlas:getqSize()
	tw,th        = tw or qw,th or qh
	
	self.tiledata= grid.new()
	self.image   = image
	self.SBwidth = nil
	self.SBheight= nil
	self.gx      = nil
	self.gy      = nil
	self.gx2     = nil
	self.gy2     = nil

	chunksize    = chunksize or DEFAULT_CHUNK_SIZE
	assert(chunksize > 0,'Spritebatch chunk must be greater than 0!')
	local qrows  = math.ceil(math.sqrt(chunksize))
	local qcols  = qrows
	self.SBwidth = qcols*tw
	self.SBheight= qrows*th
	local quads  = {}

	local mapdata = data.grid and data or md.new(data)
	for x,y,v in mapdata:iterate() do
		local index = mapfunc(x,y,v)
		if index then
			local qx,qy = atlas:getqViewport(index)
			local qi    = qx..','..qy
			quads[qi]   = quads[qi] or lg.newQuad(qx,qy,qw,qh,atlas:getImageSize())
			local quad  = quads[qi]
			-- real
			local rx,ry= tw*(x-1),th*(y-1)
			local gx,gy= getSBrange(rx,ry,tw,th,self.SBwidth,self.SBheight)
			
			local sb   = grid.get(self,gx,gy) or lg.newSpriteBatch(image,qrows*qcols)
			grid.set(self,gx,gy,sb)
			
			local ox,oy= -(gx-1)*self.SBwidth,-(gy-1)*self.SBheight
			local id   = sb:addq(quad,rx+ox,ry+oy)
			
			local tiledata= {
				visible= true,
				quad   = quad,
				sb     = sb,
				id     = id,
				
				x      = rx,
				y      = ry,
				ox     = ox,
				oy     = oy,
				angle  = 0,
				sx     = 1,   sy= 1,
				cx     = tw/2,cy= th/2,
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

function map:setVisible(tx,ty,bool)
	local t = grid.get(self.tiledata,tx,ty)
	t.sb:setq(t.id,t.quad, t.x+t.ox+t.cx,t.y+t.oy+t.cy, t.angle, bool and t.sx or 0,bool and t.sy or 0, t.cx,t.cy)
	t.visible = bool
end

function map:isVisible(tx,ty)
	return grid.get(self.tiledata,tx,ty).visible
end

function map:setFlip(tx,ty,flipx,flipy)
	local t       = grid.get(self.tiledata,tx,ty)
	local vcoeff  = t.visible and 1 or 0
	local sx,sy   = flipx and -1 or 1,flipy and -1 or 1
	t.sb:setq( t.id,t.quad, t.x+t.ox+t.cx,t.y+t.oy+t.cy, t.angle, vcoeff*sx,vcoeff*sy, t.cx,t.cy)
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
	t.sb:setq( t.id,t.quad, t.x+t.ox+t.cx,t.y+t.oy+t.cy, angle, vcoeff*t.sx,vcoeff*t.sy, t.cx,t.cy)
	t.angle = angle
end

function map:getAngle(tx,ty)
	return grid.get(self.tiledata,tx,ty).angle
end

function map:setViewport(x,y,w,h)
	if not x then self.gx,self.gy,self.gx2,self.gy2 = nil end
	self.gx,self.gy,self.gx2,self.gy2 = getSBrange(x,y,w,h,self.SBwidth,self.SBheight)
end

function map:draw(x,y,r, sx,sy, ox,oy, kx,ky)
	local gx,gy,gx2,gy2= self.gx,self.gy,self.gx2,self.gy2
	local iterator     = grid.iterate
	ox,oy = ox or 0,oy or 0
	if gx then iterator= grid.rectangle end
	for gx,gy,sb in iterator(self,gx,gy,gx2,gy2,true) do
		lg.draw(sb, x,y,r, sx,sy, (1-gx)*self.SBwidth+ox,(1-gy)*self.SBheight+oy, kx,ky)
	end
end

return map