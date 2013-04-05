local gr= love.graphics
local s = {name = 'table source'}

function s:load()
	atlas   = require 'lib.atlas'
	map     = require 'lib.map'
	md      = require 'lib.mapdata'


	sheet = gr.newImage('tile.png')
	sheet:setFilter('linear','nearest')
	
	sheetatlas = atlas.new(32,32,16,16)
		
	local mapsource = {
	 {'x','x','x','x','x','x','x','x',},
	 {'@','@','@','@','@','@','@'     },
	 {'q','q','q','q','q','q','q',    },
	 {'-','-','-','-','-','-','-','-',},
	}
	
	map = map.new(sheet,sheetatlas,18,18)	
	
	for x,y,v in md.grid(mapsource) do
		local index
		if v == '-' then index = 1
		elseif v == '@' then index = 2
		elseif v == 'q' then index = 3
		elseif v == 'x' then index = 4 end
		map:setAtlasIndex(x,y,index)
	end
		
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function s:keypressed(k)
	if k == ' ' then state = require 'imagestate' state:load() end
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
	map:draw(0,0,3.14/10,2)			
	gr.pop()
end

return s