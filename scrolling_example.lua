local gr= love.graphics
local s = {name = 'scrolling test'}

function s:load()
	dl    = require 'lib.drawlist'
	
	kirby = gr.newImage('kirby.png')
	foreground = gr.newQuad(6,419,577,216,787,641)
	background = gr.newQuad(3,230,415,171,787,641)
		
	--[[######################
	DEFINE LAYER AND DRAW CALLBACK
	--########################]]	
		
	local layer1 = {}	
	layer1.draw = function(self,...) 
		gr.drawq(kirby,background,50,50)
	end
	
	local layer2 = {}
	layer2.draw = function(self,...) 
		gr.drawq(kirby,foreground,0,0) 
	end
	
	--[[######################
	INSERT LAYERS INTO DRAWLIST AND
	SET BACKGROUND TO SCROLL SLOWER THAN FOREGROUND
	--########################]]
	
	scene = dl.new()
	
	scene:insert(layer1,1,1/2)
	scene:insert(layer2,2,1)
	
	scroll_speed = 500
	x,y = 0,0
end

function s:keypressed(k)
	if k == ' ' then state = require 'map_example' state:load() end
end

function s:keyreleased(k)
	if k == 'q' then scene:swap(1,2) end
end

function s:update(dt)
	if love.keyboard.isDown 'a' then
		x = x+dt*scroll_speed
	elseif love.keyboard.isDown 'd' then
		x = x-dt*scroll_speed
	end
	
	if love.keyboard.isDown 's' then
		y = y-dt*scroll_speed
	elseif love.keyboard.isDown 'w' then
		y = y+dt*scroll_speed
	end
	
	scene:setTranslation(x,y)
end

function s:draw()
	gr.push()
		gr.translate(100,200) -- center scene
		scene:draw()
	gr.pop()
	love.graphics.print('Press q to swap layer',0,100)
end

return s