local DEFAULT_CHUNK_SIZE = 256

local path  = (...):match('^.+%.') or ''
local grid  = require (path..'grid')
local md    = require (path..'mapdata')

local ceil = math.ceil
local floor= math.floor
local max  = math.max
local lg   = love.graphics
local pairs= pairs

local getSBrange = function(x,y,w,h,sw,sh)
	local gx,gy  = floor(x/sw)+1,floor(y/sh)+1
	local gx2,gy2= ceil((x+w)/sw),ceil((y+h)/sh)
	return gx,gy,gx2,gy2
end

local map   = {}
map.__index = map

function map.new(image,atlas,data,mapfunc,tw,th,chunksize)
	local self   = grid.new()
	
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
	local qw,qh  = atlas:getqSize()
	tw,th        = tw or qw,th or qh
	local qrows  = math.ceil(math.sqrt(chunksize))
	local qcols  = qrows
	self.SBwidth = qcols*qw
	self.SBheight= qrows*qh
	local quads  = {}
	
	local mapdata = data.grid and data or md.new(data)
	for x,y,v in mapdata:iterate() do
		local index = mapfunc(x,y,v)
		if index then
			local qx,qy   = atlas:getqViewport(index)
			quads[v]      = quads[v] or lg.newQuad(qx,qy,qw,qh,atlas:getImageSize())
			local quad    = quads[v]
			local tiledata= {}
			grid.set(self.tiledata,x,y,tiledata)
			-- real
			local rx,ry        = tw*(x-1),th*(y-1)
			local gx,gy,gx2,gy2= getSBrange(rx,ry,tw,th,self.SBwidth,self.SBheight)
			for gx,gy,sb in grid.rectangle(self,gx,gy,gx2,gy2) do
				local ox,oy= -(gx-1)*self.SBwidth,-(gy-1)*self.SBheight
				sb         = sb or lg.newSpriteBatch(image,qrows*qcols)
				grid.set(self,gx,gy,sb)
				local id   = sb:addq(quad,rx+ox,ry+oy)
				table.insert(tiledata,{quad = quad,sb = sb,id = id,x = rx,y = ry,ox = ox,oy = oy,visible = true})
			end
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
	local tiledata = grid.get(self.tiledata,tx,ty)
	for i,t in pairs(tiledata) do
		t.sb:setq(t.id,t.quad,t.x+t.ox,t.y+t.oy,0,bool and 1 or 0)
		t.visible = bool
	end
end

function map:isVisible(tx,ty)
	return grid.get(self.tiledata,tx,ty)[1].visible
end

function map:setViewport(x,y,w,h)
	if not x then self.gx,self.gy,self.gx2,self.gy2 = nil end
	self.gx,self.gy,self.gx2,self.gy2 = getSBrange(x,y,w,h,self.SBwidth,self.SBheight)
end

function map:draw(x,y,r, sx,sy, ox,oy, kx,ky)
	local gx,gy,gx2,gy2= self.gx,self.gy,self.gx2,self.gy2
	local iterator     = grid.iterate
	if gx then iterator= grid.rectangle end
	for gx,gy,sb in iterator(self,gx,gy,gx2,gy2,true) do
		lg.draw(sb, x,y,r, sx,sy, (1-gx)*self.SBwidth,(1-gy)*self.SBheight, kx,ky)
	end
end

return map