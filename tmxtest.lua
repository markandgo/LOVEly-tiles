local s = {name = 'tmx test'}

function s:load()
	tmxload = require 'lib.tmxloader'
	tmxsave = require 'lib.tmxsaver'
	
	d = tmxload('grass.tmx')
	
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
			d2 = newd 
			isLoading = false
		end
	end	
end

function s:keypressed(k)
	if k == ' ' then state = require 'scrolling' state:load() end
	if k == '1' then
		if d then tmxsave(d,'grass.tmx') end
		if d2 then tmxsave(d2,'top.tmx') end
	end
	if k == '2' then
		d = tmxload 'grass.tmx'
		d2 = nil
	end
	if k == '3' then
		loader = tmxload ('top.tmx','chunk',100)
		local newd,err = loader()
		if not newd and not err then
			isLoading = true
		elseif err then
			error(err)
		else
			d2 = newd
			isLoading = false
		end
	end
end

function s:draw()
	fx,fy = math.floor(x or 0),math.floor(y or 0)
	if d then d:draw(fx+400,fy) end
	if d2 then d2:draw(fx+400,fy) end
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