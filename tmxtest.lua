local s = {name = 'tmx test'}

function s:load()
	tmxload = require 'lib.tmxloader'
	tmxsave = require 'lib.tmxsaver'
	
	d = tmxload('maptest.tmx')
	
	speed = 500	
end

function s:update(dt)
	if love.keyboard.isDown 'a' then
		x = (x or 0)+dt*speed
	elseif love.keyboard.isDown 'd' then
		x = (x or 0)-dt*speed
	end
	if love.keyboard.isDown 's' then
		y = (y or 0)-dt*speed
	elseif love.keyboard.isDown 'w' then
		y = (y or 0)+dt*speed
	end
	if isLoading then
		local newd,err = loader()
		if not newd and not err then
			isLoading = true
		elseif err then
			error(err)
		else
			d = newd 
			isLoading = false
		end
	end	
end

function s:keypressed(k)
	if k == ' ' then state = require 'scrolling' state:load() end
	if k == '1' then
		tmxsave(d,'saved.tmx')
	end
	if k == '2' then
		d = tmxload 'maptest.tmx'
	end
	if k == '3' then
		loader = tmxload ('maptest.tmx','chunk',100)
		local newd,err = loader()
		if not newd and not err then
			isLoading = true
		elseif err then
			error(err)
		else
			d = newd
			isLoading = false
		end
	end
end

function s:draw()
	fx,fy = math.floor(x or 0),math.floor(y or 0)
	d:draw(fx+400,fy)
	love.graphics.setColor(100,100,100)
	love.graphics.rectangle('fill',0,500,200,100)
	love.graphics.setColor(255,255,255)
	love.graphics.print('Press 1 to save to saved.tmx\
Press 2 to reload entire map\
Press 3 to reload map slowly\
Open saved.tmx and compare!\
'..'loading: '..tostring(isLoading),0,500)
end

return s