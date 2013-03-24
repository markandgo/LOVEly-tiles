local DEFAULT_CHUNK_SIZE = 256

local path  = (...):match('^.+%.') or ''
local grid  = require (path..'grid')
local md    = require (path..'mapdata')
local map   = require (path..'map')

local ceil  = math.ceil
local floor = math.floor
local lg    = love.graphics

local getSBrange = function(x,y,w,h,sw,sh)
	local gx,gy  = floor(x/sw)+1,floor(y/sh)+1
	local gx2,gy2= ceil((x+w)/sw),ceil((y+h)/sh)
	return gx,gy,gx2,gy2
end

local newSB = function(image,chunksize)
	local sb = lg.newSpriteBatch(image,chunksize)
	sb:bind()
	return sb 
end

local isoToScreen = function(ix,iy,qw,qh)
	local x = (ix-1)*qw/2 - (iy-1)*qw/2
	local y = (ix-1)*qh/2 + (iy-1)*qh/2
	return x,y
end

-- child class of map class (shared methods)
local isomap   = setmetatable({},map)
isomap.__index = isomap

function isomap.new(image,atlas,data,mapfunc, ox,oy,qw,qh, chunksize)
	local self   = grid.new()
	
	local qw2,qh2= atlas:getqSize()
	qw,qh        = qw or qw2,qh or qh2
	local iw,ih  = atlas:getImageSize()
	ox,oy        = ox or 0,oy or 0
	
	self.tiledata= grid.new()
	self.image   = image
	self.qw      = qw
	self.qh      = qh
	self.SBwidth = nil
	self.SBheight= nil
	self.gx      = nil
	self.gy      = nil
	self.gx2     = nil
	self.gy2     = nil

	chunksize    = chunksize or DEFAULT_CHUNK_SIZE
	assert(chunksize > 0,'Spritebatch chunk must be greater than 0!')
	local rows   = math.ceil(math.sqrt(chunksize))
	local cols   = rows
	chunksize    = rows*cols
	self.SBwidth = cols
	self.SBheight= rows
	
	local quads     = {}
	local drawlevel = {}
	
	-- tile length in isometric world = 1
	-- +x direction: move down right
	-- +y direction: move down left
	local iterate = md.iterateData
	if data.grid then iterate = md.iterate end
	
	for x,y, a,b,c,d in iterate(data) do
		local index = mapfunc(x,y, a,b,c,d)
		if index then
			local qx,qy = atlas:getqViewport(index)
			local qi    = qx..','..qy
			quads[qi]   = quads[qi] or lg.newQuad(qx+ox,qy+oy,qw,qh,iw,ih)
			local quad  = quads[qi]
			-- real
			local rx,ry= isoToScreen(x,y,qw,qh)
			local gx,gy= getSBrange(x-1,y-1,1,1,self.SBwidth,self.SBheight)
			
			local sb   = grid.get(self,gx,gy) or newSB(image,chunksize)
			grid.set(self,gx,gy,sb)
			
			local level        = x+y
			drawlevel[level]   = drawlevel[level] or {level= level}
			drawlevel[level][x]= y
			
			local ox,oy= isoToScreen( (gx-1)*self.SBwidth,(gy-1)*self.SBheight, qw,qh)
			ox,oy      = -ox,-oy
			
			local tiledata= {
				visible= true,
				quad   = quad,
				sb     = sb,
				id     = nil,
				
				x      = rx,
				y      = ry,
				ox     = ox,
				oy     = oy,
				angle  = 0,
				sx     = 1,   sy= 1,
				cx     = qw/2,cy= qh/2,
				}
				
			grid.set(self.tiledata,x,y,tiledata)
		end
	end
	
	local draworder = {}
	for level,t in pairs(drawlevel) do
		table.insert(draworder,t)
	end
	table.sort(draworder,function(a,b) return a.level < b.level end)
	for level,t in ipairs(draworder) do
		t.level = nil
		for x,y in pairs(t) do
			local td = grid.get(self.tiledata,x,y)
			td.id    = td.sb:addq(td.quad,td.x+td.ox,td.y+td.oy)
		end
	end
	
	for x,y,sb in grid.iterate(self) do
		sb:unbind()
	end
	
	return setmetatable(self,isomap)
end

function isomap:draw(x,y,r, sx,sy, ox,oy, kx,ky)
	local gx,gy,gx2,gy2= self.gx,self.gy,self.gx2,self.gy2
	local iterator     = grid.iterate
	ox,oy = ox or 0,oy or 0
	if gx then iterator= grid.rectangle end
	for gx,gy,sb in iterator(self,gx,gy,gx2,gy2,true) do
		local ox2,oy2 = isoToScreen((gx-1)*self.SBwidth,(gy-1)*self.SBheight,self.qw,self.qh)
		lg.draw(sb, x,y,r, sx,sy, ox-ox2+self.qw/2,oy-oy2, kx,ky)
	end
end

return isomap