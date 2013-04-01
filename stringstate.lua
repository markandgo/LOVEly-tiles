local gr= love.graphics
local s = {name = 'string source'}

function s:load()
	atlas   = require 'lib.atlas'
	map     = require 'lib.map'

	sheet = gr.newImage('tile.png')
	sheet:setFilter('linear','nearest')
	
	sheetatlas = atlas.new(32,32,16,16)
		
	local mapsource =[[
@@@@@  ----   qqqq   xxxxx
  @    -      q        x
  @    ----   qqqq     x
  @    -         q     x
  @    ----   qqqq     x
]]
	
	local mapfunc = function(x,y,v) 
		if v == '-' then return 1
		elseif v == '@' then return 2
		elseif v == 'q' then return 3
		elseif v == 'x' then return 4 end
	end
	
	map = map.new(sheet,sheetatlas,mapsource,mapfunc)	
	
	map:setFlip(1,1,true,false)
	map:setAngle(2,1,3.14/2)
	map:setVisible(3,1,false)
	
	function render()
		map:setViewport(x,y,800,600)		
		map:draw()			
	end	
		
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function s:keypressed(k)
	if k == ' ' then state = require 'tablestate' state:load() end
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
		gr.translate(-math.floor(x),-math.floor(y))
		gr.rectangle('line',0,0,800,600)
		render()	
	gr.pop()
	
	-- minimap showing chunks in view
	gr.push()		
		gr.translate(600,0)
		gr.scale(0.25)
		gr.rectangle('line',0,0,800,600)		
		render()	
	gr.pop()
	gr.rectangle('line',600,0,200,150)
end

return s