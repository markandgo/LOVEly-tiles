local gr= love.graphics
local s = {name = 'scrolling test'}

function s:load()
	dl    = require 'lib.drawlist'
	
	kirby = gr.newImage('kirby.png')
	foreground = gr.newQuad(6,419,577,216,787,641)
	background = gr.newQuad(3,230,415,171,787,641)
		
	local layer1 = {}	
	layer1.draw = function(self,...) 
		gr.drawq(kirby,background,50,50)
	end
	
	local layer2 = {}
	layer2.draw = function(self,...) 
		gr.drawq(kirby,foreground,0,0) 
	end
	
	scene = dl.new()
	
	scene:insert(layer1,1,1/2)
	scene:insert(layer2,2,0)
	
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function s:keypressed(k)
	if k == ' ' then state = require 'maptest' state:load() end
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
	if k == 'q' then scene:swap(1,2) end
end

function s:update(dt)
	dx,dy= vx*dt,vy*dt
	x    =x+dx y=y+dy
	scene:setTranslation(x,y)
end

function s:draw()
	gr.push()
	gr.translate(100,200) -- center on screen
	gr.translate(-x,-y)
	scene:draw()
	gr.pop()
	love.graphics.print('Press q to swap layer',0,100)
end

return s