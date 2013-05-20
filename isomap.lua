local PREALLOCATE_SB_SIZE = 256

local path  = (...):match('^.+[%.\\/]') or ''
local grid  = require (path..'grid')
local map   = require (path..'map')

local ceil  = math.ceil
local sqrt  = math.sqrt
local floor = math.floor
local max   = math.max
local lg    = love.graphics
local sbadd = love.graphics.newGeometry and 'addg' or 'addq'
local sbset = love.graphics.newGeometry  and 'setg' or 'setq'

local dummyquad = lg.newQuad(0,0,1,1,1,1)

local getSBrange = function(tx,ty,tx2,ty2,sw,sh)
	local sbx,sby  = ceil(tx/sw),ceil(ty/sh)
	local sbx2,sby2= ceil(tx2/sw),ceil(ty2/sh)
	return sbx,sby,sbx2,sby2
end

local isoToScreen = function(ix,iy,tw,th)
	local x = (ix-1)*tw/2 - (iy-1)*tw/2
	local y = (ix-1)*th/2 + (iy-1)*th/2
	return x,y
end

local setQuad = function(self,t)
	t.sb[sbset](t.sb, t.id,t.quad, t.x+self.hw,t.y+self.hh, t.angle, t.sx,t.sy, self.hw,self.hh)	
end

local preallocateSB = function(self,sbx,sby)	
	local sb   = lg.newSpriteBatch(self.image,PREALLOCATE_SB_SIZE)
	sb:bind()
	grid.set(self,sbx,sby,sb)
	
	local qw,qh       = self.atlas:getqSize()
	local tox,toy     = self.SBwidth*(sbx-1),self.SBheight*(sby-1)
	for y = 1,self.SBheight do
		for x = 1,self.SBwidth do
		
			local rx,ry = isoToScreen(x+tox,y+toy,self.tw,self.th)
			
			local tiledata= {
				quad    = nil,
				index   = nil,
				property= nil,
				sb      = sb,
				id      = sb[sbadd](sb,dummyquad,0,0,0,0),
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
	local self = map.new(image,atlas,tw,th)	
	return setmetatable(self,isomap)
end

function isomap:setAtlasIndex(tx,ty,index, angle,flipx,flipy)
	local t = grid.get(self.tilegrid,tx,ty)
	
	if not t then
		local sbx,sby = getSBrange(tx,ty,tx,ty,self.SBwidth,self.SBheight)
		preallocateSB(self,sbx,sby)
		t = grid.get(self.tilegrid,tx,ty)
	end
	
	if not index then
		t.quad    = nil
		t.index   = nil
		t.angle   = nil
		t.sx      = nil
		t.sy      = nil
		t.property= nil
		t.sb[sbset](t.sb, t.id, dummyquad, 0,0,0,0)
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

return isomap