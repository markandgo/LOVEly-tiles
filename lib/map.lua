local PREALLOCATE_SB_SIZE = 256

local path  = (...):match('^.+%.') or ''
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
			grid.set(self.tiledata,tox+x,toy+y,tiledata)
		end
	end
	sb:unbind()
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

local map   = {}
map.__index = map

function map.new(image,atlas, tw,th)
	local self   = grid.new()
	
	local qw,qh  = atlas:getqSize()
	tw,th        = tw or qw,th or qh
	
	local qrows  = floor(sqrt(PREALLOCATE_SB_SIZE))
	local qcols  = qrows
	
	self.SBwidth = qcols*tw
	self.SBheight= qrows*th	
	
	self.tiledata= grid.new()
	self.image   = image
	self.gx      = nil
	self.gy      = nil
	self.gx2     = nil
	self.gy2     = nil
	self.quads   = {}
	self.atlas   = atlas
	self.hw      = qw/2
	self.hh      = qh/2
	self.tw      = tw
	self.th      = th
	
	return setmetatable(self,map)
end

function map:setAtlasIndex(tx,ty,index)
	local t = grid.get(self.tiledata,tx,ty)
	
	if not t then
		local rx,ry= self.tw*(tx-1),self.th*(ty-1)
		local gx,gy= getSBrange(rx,ry,self.tw,self.th,self.SBwidth,self.SBheight)
		preallocateSB(self,gx,gy)
		
		t = grid.get(self.tiledata,tx,ty)
	end
	
	if not index then
		t.quad    = nil
		t.index   = nil
		t.sb:setq( t.id, dummyquad, 0,0,0,0)
		return
	end
	
	local quad= getQuad(self,index)
	t.quad    = quad
	t.index   = type(index)== 'table' and ( self.atlas:getColumns()*(index[2]-1)  +  index[1] ) or index
	t.angle   = 0
	t.sx      = 1
	t.sy      = 1
	t.sb:setq( t.id, quad, t.x,t.y)
end

function map:getAtlasIndex(tx,ty)
	local t = grid.get(self.tiledata,tx,ty)
	return t and t.index
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
	grid.get(self.tiledata,tx,ty).property = value
end

function map:getProperty(tx,ty)
	return grid.get(self.tiledata,tx,ty).property
end

function map:setFlip(tx,ty,flipx,flipy)
	local t       = grid.get(self.tiledata,tx,ty)
	local sx,sy   = flipx and -1 or 1,flipy and -1 or 1
	t.sb:setq( t.id,t.quad, t.x+self.hw,t.y+self.hh, t.angle, sx,sy, self.hw,self.hh)
	t.sx = sx
	t.sy = sy
end

function map:getFlip(tx,ty)
	local tiledata = grid.get(self.tiledata,tx,ty)
	return tiledata.sx == -1,tiledata.sy == -1
end

function map:setAngle(tx,ty,angle)
	local t       = grid.get(self.tiledata,tx,ty)
	t.sb:setq( t.id,t.quad, t.x+self.hw,t.y+self.hh, angle, t.sx,t.sy, self.hw,self.hh)
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
	local gx,gy,gx2,gy2 = self.gx,self.gy,self.gx2,self.gy2
	local iterate       = grid.rectangle
	if not gx then iterate = grid.iterate end
	for gx,gy,sb in iterate(self,gx,gy,gx2,gy2,true) do
		lg.draw(sb, ...)
	end
end

return map