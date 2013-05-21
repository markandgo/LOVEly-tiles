local gr= love.graphics
local s = {name = 'map loading/editing'}

function s:load()
	atlas   = require 'lib.atlas'
	map     = require 'lib.map'
	mapdata = require 'lib.mapdata'

	sheet = gr.newImage('tile.png')
	sheet:setFilter('linear','nearest')
	
	--[[######################
	TEXTURE ATLAS
	--########################]]
	
	sheetatlas = atlas.new(32,32,16,16)
		
	local mapsource =[[
@@@@@  ----   qqqq   xxxxx
  @    -      q        x
  @    ----   qqqq     x
  @    -         q     x
  @    ----   qqqq     x
]]
	
	--[[######################
	FILL MAP WITH STRING SOURCE
	--########################]]
		
	map = map.new(sheet,sheetatlas)
	
	for x,y,v in mapdata.string(mapsource) do
		local index
		if v == '-' then index = 1
		elseif v == '@' then index = 2
		elseif v == 'q' then index = 3
		elseif v == 'x' then index = 4 end
		map:setAtlasIndex(x,y,index)
	end
	
	--[[######################
	SET VIEWING RANGE: 100 X 100 TILES
	--########################]]
	
	map:setViewRange(1,1,100,100)
	
	--[[######################
	FLIP/ROTATE/HIDE TILES
	--########################]]
	
	map:setFlip(1,1,true,false)
	map:setAngle(2,1,3.14/2)
	map:setAtlasIndex(3,1)
	
	scroll_speed = 500
	x,y = 0,0
end

function s:keypressed(k)
	if k == ' ' then state = require 'isometric_example' state:load() end
end

function s:mousepressed(mx,my,b)
	--[[######################
	MAP EDITING
	--########################]]

	local x,y = mx-x,my-y
	
	if b == 'l' then
		index = map:getAtlasIndex(math.ceil(x/16),math.ceil(y/16))
		local nexti = index and index+1 <= 4 and index+1 or 1
		map:setAtlasIndex(math.ceil(x/16),math.ceil(y/16),nexti)
	end
	
	if b == 'r' then map:setAtlasIndex(math.ceil(x/16),math.ceil(y/16)) end
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
	local x,y = math.floor(x),math.floor(y)

	gr.push()
		gr.translate(x,y)
		gr.rectangle('line',0,0,800,600)		
		map:draw()	
	gr.pop()
	
	gr.print('Right mouse click to erase a tile',0,576)
	gr.print('Left mouse click to add/change a tile',0,588)
end

return s