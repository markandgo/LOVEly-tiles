local gr= love.graphics
local s = {name = 'isometric map'}

function s:load()
	atlas   = require 'lib.atlas'
	isomap  = require 'lib.isomap'
	md      = require 'lib.mapdata'

	sheet = gr.newImage('isotile.png')
	sheet:setFilter('linear','nearest')
	
	--[[######################
	TEXTURE ATLAS
	--########################]]
	
	sheetatlas = atlas.new(sheet:getWidth(),sheet:getHeight(), 64,64)
		
	local mapsource =[[
xxxxx  xxxx   xxxx   xxxxx
  x    x      x        x
  x    xxxx   xxxx     x
  x    x         x     x
  x    xxxx   xxxx     x
]]
	
	--[[######################
	FILL MAP WITH STRING SOURCE
	--########################]]
	
	map = isomap.new(sheet,sheetatlas,64,32)	
	
	for x,y,v in md.string(mapsource) do
		if v == 'x' then map:setTile(x,y,{5,4}) end
	end
	
	--[[######################
	FLIP/ROTATE/HIDE TILES
	--########################]]
	
	map:setFlip(1,1,true,false)
	map:setAngle(5,1,3.14)
	map:setTile(3,1)
	
	--[[######################
	SET VIEWING RANGE: 100 X 100 TILES
	--########################]]
	
	map:setViewRange(1,1,100,100)
		
	scroll_speed = 500
	x,y = 0,0
end

function s:keypressed(k)
	if k == ' ' then state = require 'tmx_example' state:load() end
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
end

function s:draw()
	gr.push()
		gr.translate(x,y)
		gr.rectangle('line',0,0,800,600)
		map:draw()			
	gr.pop()
end

return s