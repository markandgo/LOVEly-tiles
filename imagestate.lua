local gr= love.graphics
local s = {name = 'image source'}

function s:load()
	atlas   = require 'lib.atlas'
	map     = require 'lib.map'
	md      = require 'lib.mapdata'

	sheet = gr.newImage('tile.png')
	sheet:setFilter('linear','nearest')
	
	sheetatlas = atlas.new(32,32,16,16)
		
	local mapsource = love.image.newImageData('map.png')
	
	local mapfunc = function(x,y,r,g,b,a) 
		-- return atlas index for desired tiles
		if r == 255 and g == 251 then return 1 end
		if r == 255 then return {2,1} end
		if g == 255 then return {1,2} end
		if b == 255 then return 4 end
	end
	
	map = map.new(sheet,sheetatlas)	
		
	for x,y, r,g,b,a in md.imageData(mapsource) do
		map:setAtlasIndex(x,y,mapfunc(x,y, r,g,b,a))
	end	
		
		
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function s:keypressed(k)
	if k == ' ' then state = require 'arraystate' state:load() end
	if k == 'd' then
		vx = velocity
	end
	if k == 'a' then
		vx = -velocity
	end
	if k == 'w' then
		vy = -velocity
	end
	if k == 's' then
		vy = velocity
	end
end

function s:keyreleased(k)
	if k == 'd' or k == 'a' then
		vx = 0
	end
	if k == 'w' or k == 's' then
		vy = 0
	end
end

function s:update(dt)
	dx,dy= vx*dt,vy*dt
	x    =x+dx y=y+dy
end

function s:draw()
	gr.push()
	gr.translate(-x,-y)
	gr.rectangle('line',0,0,800,600)
	map:draw()			
	gr.pop()
end

return s