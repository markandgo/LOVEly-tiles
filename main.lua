function love.load()
	state = require 'scrollstate'
	state:load()
end

function love.keypressed(k)
	state:keypressed(k)
	if k == 'escape' then love.event.push('quit') end
end

function love.keyreleased(k)
	state:keyreleased(k)
end

function love.mousepressed(x,y,b)
	if state.mousepressed then state:mousepressed(x,y,b) end
end

function love.update(dt)
	state:update(dt)
end

function love.draw()
	state:draw()
	love.graphics.setColor(0,0,0,150)
	love.graphics.rectangle('fill',0,0,300,100)
	love.graphics.setColor(255,255,255)
	love.graphics.print('Press space to switch state',0,0)
	love.graphics.print('Press WASD to move the screen',0,12)
	love.graphics.print(state.name,0,24)
end