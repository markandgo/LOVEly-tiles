local PREALLOCATE_SB_SIZE = 256

local path  = (...):match('^.+[%.\\/]') or ''
local grid  = require (path..'grid')
local map   = require (path..'map')

local ceil  = math.ceil
local sqrt  = math.sqrt
local floor = math.floor
local max   = math.max
local lg    = love.graphics

local dummyquad = lg.newQuad(0,0,1,1,1,1)

local getSBrange = function(x,y,w,h,sw,sh)
	local gx,gy  = floor(x/sw)+1,floor(y/sh)+1
	local gx2,gy2= ceil((x+w)/sw),ceil((y+h)/sh)
	return gx,gy,gx2,gy2
end

local isoToScreen = function(ix,iy,tw,th)
	local x = (ix-1)*tw/2 - (iy-1)*tw/2
	local y = (ix-1)*th/2 + (iy-1)*th/2
	return x,y
end

local setQuad = function(self,t)
	t.sb:setq( t.id,t.quad, t.x+self.hw,t.y+self.hh, t.angle, t.sx,t.sy, self.hw,self.hh)	
end

local preallocateSB = function(self,gx,gy)	
	self.sbrows= max(self.sbcols,gx)
	self.sbcols= max(self.sbrows,gy)
	
	local sb   = lg.newSpriteBatch(self.image,PREALLOCATE_SB_SIZE)
	sb:bind()
	grid.set(self,gx,gy,sb)
	
	local qw,qh       = self.atlas:getqSize()
	local tox,toy     = self.SBwidth*(gx-1),self.SBheight*(gy-1)
	for y = 1,self.SBheight do
		for x = 1,self.SBwidth do
		
			local rx,ry = isoToScreen(x+tox,y+toy,self.tw,self.th)
			
			local tiledata= {
				quad    = nil,
				index   = nil,
				property= nil,
				sb      = sb,
				id      = sb:addq(dummyquad,0,0,0,0),
				x       = rx,
				y       = ry,
				angle   = 0,
				sx      = 1,
				sy      = 1,
			}
			grid.set(self.tilegrid,tox+x,toy+y,tiledata)
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

local isomap   = setmetatable({},{__call = function(self,...) return self.new(...) end,__index = map})
isomap.__index = isomap

function isomap.new(image,atlas, tw,th)
	local self   = grid.new()
	
	local qw,qh  = atlas:getqSize()
	tw,th        = tw or qw,th or tw or qh
	
	local qrows  = floor(sqrt(PREALLOCATE_SB_SIZE))
	local qcols  = qrows
	
	self.SBwidth = qcols
	self.SBheight= qrows
	
	self.tilegrid = grid.new()
	self.image    = image
	self.imagepath= nil
	self.atlaspath= nil
	self.gx       = nil
	self.gy       = nil
	self.gx2      = nil
	self.gy2      = nil
	self.sbrows   = 0
	self.sbcols   = 0
	self.quads    = setmetatable({},{__mode = 'kv'})
	self.atlas    = atlas
	self.hw       = qw/2
	self.hh       = qh/2
	self.tw       = tw
	self.th       = th
	
	return setmetatable(self,isomap)
end

function isomap:setAtlasIndex(tx,ty,index, angle,flipx,flipy)
	local t = grid.get(self.tilegrid,tx,ty)
	
	if not t then
		local gx,gy = getSBrange(tx-1,ty-1,1,1,self.SBwidth,self.SBheight)
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

function isomap:draw(x,y,r, sx,sy, ox,oy, kx,ky)
	local gx,gy,gx2,gy2= self.gx,self.gy,self.gx2,self.gy2
	ox,oy              = ox or 0,oy or 0
	if not gx then gx,gy,gx2,gy2 = 1,1,self.sbcols,self.sbrows end
	for gx,gy,sb in grid.rectangle(self,gx,gy,gx2,gy2,true) do
		lg.draw(sb, x,y,r, sx,sy, ox+self.tw/2,oy, kx,ky)
	end
end

return isomap