local s = {name = 'tmx test'}

function s:load()
	tmxload = require 'lib.tmxloader'
	tmxsave = require 'lib.tmxsaver'
	
	--[[######################
	LOAD MAP
	--########################]]
	
	drawlist = tmxload 'grass.tmx'
	
	scroll_speed = 500
	x,y = 0,0
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
	
	--[[######################
	FUNCTION FILLS IN SECOND DRAWLIST
	RETURNS TRUE WHEN FINISHED
	--########################]]
	
	if isLoading then
		if loader() then isLoading = false end
	end
end

function s:keypressed(k)
	if k == ' ' then state = require 'scrolling_example' state:load() end
	
	if k == '1' then
		if drawlist then tmxsave(drawlist,'grass.tmx') end
		if drawlist2 then tmxsave(drawlist2,'top.tmx') end
	end
	
	if k == '2' then
		drawlist = tmxload 'grass.tmx'
		drawlist2 = nil
	end
	
	--[[######################
	LOAD SECOND MAP (SLOWLY)
	--########################]]
	
	if k == '3' then
		drawlist2,loader = tmxload ('top.tmx','chunk',100)
		isLoading = true
	end
end

function s:draw()
	local x,y = math.floor(x),math.floor(y)
	
	--[[######################
	DRAW MAPS
	--########################]]
	
	if drawlist then drawlist:draw(x+400,y) end
	if drawlist2 then drawlist2:draw(x+400,y) end
	
	love.graphics.setColor(100,100,100)
	love.graphics.rectangle('fill',0,500,200,100)
	love.graphics.setColor(255,255,255)
	love.graphics.print('Press 1 to save\
Press 2 to reload default\
Press 3 to load top layers\
Open saved files and compare!\
'..'loading: '..tostring(isLoading),0,500)
end

return s