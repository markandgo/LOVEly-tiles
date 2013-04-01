local gr= love.graphics
local s = {name = 'array source'}

function s:load()
	atlas   = require 'lib.atlas'
	map     = require 'lib.map'

	sheet = gr.newImage('tile.png')
	sheet:setFilter('linear','nearest')
	
	sheetatlas = atlas.new(32,32,16,16)
		
	local mapsource = {width = 4,height = 4,
	'-','q','@','x',
	'-','q','@','x',
	'-','q','@','x',
	'-','q','@','x',
	}
	
	local mapfunc = function(x,y,v) 
		if v == '-' then return 1
		elseif v == '@' then return 2
		elseif v == 'q' then return 3
		elseif v == 'x' then return 4 end
	end
	
	map = map.new(sheet,sheetatlas,mapsource,mapfunc)	
	
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function s:keypressed(k)
	if k == ' ' then state = require 'isostate' state:load() end
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
		map:draw()			
	gr.pop()
end

return s