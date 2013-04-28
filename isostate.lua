local gr= love.graphics
local s = {name = 'isometric map'}

function s:load()
	atlas   = require 'lib.atlas'
	isomap  = require 'lib.isomap'
	md      = require 'lib.mapdata'

	sheet = gr.newImage('isotile.png')
	sheet:setFilter('linear','nearest')
	
	sheetatlas = atlas.new(640,1024, 64,64)
		
	local mapsource =[[
xxxxx  xxxx   xxxx   xxxxx
  x    x      x        x
  x    xxxx   xxxx     x
  x    x         x     x
  x    xxxx   xxxx     x
]]
	
	map = isomap.new(sheet,sheetatlas,64,32)	
	
	for x,y,v in md.string(mapsource) do
		if v == 'x' then map:setAtlasIndex(x,y,{5,4}) end
	end
	
	map:setFlip(1,1,true,false)
	map:setAngle(5,1,3.14)
	map:setAtlasIndex(3,1)
		
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function s:keypressed(k)
	if k == ' ' then state = require 'scrollstate' state:load() end
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