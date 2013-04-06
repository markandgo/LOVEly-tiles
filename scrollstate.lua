local gr= love.graphics
local s = {name = 'scrolling'}

function s:load()
	ds    = require 'lib.drawstack'
	
	kirby = gr.newImage('kirby.png')
	foreground = gr.newQuad(6,419,577,216,787,641)
	background = gr.newQuad(3,230,415,171,787,641)
		
	bg = {draw = function(self,...) 
		gr.drawq(kirby,self.quad,50,50) -- center on foreground
	end,quad = background}
	
	fg = {draw = function(self,...) 
		gr.drawq(kirby,self.quad,0,0) 
	end,quad = foreground}
	
	scene = ds.new()
	
	scene:add(nil,1,1/2)
	scene:add(nil,2)
	
	scene:addObj(bg,1)
	scene:addObj(fg,2)
	
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function s:keypressed(k)
	if k == ' ' then state = require 'stringstate' state:load() end
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
	scene:setTranslation(x,y)
end

function s:draw()
	gr.push()
	gr.translate(100,200) -- center on screen
	gr.translate(-x,-y)
	scene:draw()
	gr.pop()
end

return s