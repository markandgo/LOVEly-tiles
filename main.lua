local gr= love.graphics
atlas   = require 'atlas'
map     = require 'map'
mapdata = require 'mapdata'


function love:load()
	sheet     = gr.newImage('tile.png')
	sheet:setFilter('linear','nearest')
	
	mapimage  = love.image.newImageData('map.png')
	
	---------------------------------------------------------
	---------------------------------------------------------
	
	-- create atlas of our tiles (quad w = 16, h = 16)
	sheetatlas= atlas.new(32,32,16,16)
	
	
	-- create a map from a string or...
	local mapstring =[[
 @@@ ------------------------------------
@ @@ x q x q x q x q x q x q x q x q x q 
@@ @  x q x q x q x q x q x q x q x q x q
@@@  ------------------------------------

xxx xx x x x x x x x x x x x x x x x x x 
qqq qq q q q q q q q q q q q q q q q q q

qqq qq q q q q q q q q q q q q q q q q q
xxx xx x x x x x x x x x x x x x x x x x
]]
	
	-- create a map from a table!
	local maptable = {
	 {'x','x','x','x','x','x','x','x',},
	 {'@','@','@','@','@','@','@','@',},
	 {'q','q','q','q','q','q','q','q',},
	 {'-','-','-','-','-','-','-','-',},
	}
	
	-- create a mapdata from an image data!
	mapdata1 = mapdata.new(mapimage,function(x,y,r,g,b,a) 
		-- return atlas index for desired tiles
		if r == 255 and g == 251 then return 1 end
		if r == 255 then return {2,1} end
		if g == 255 then return {1,2} end
		if b == 255 then return 4 end
	end)
	
	---------------------------------------------------------
	---------------------------------------------------------
	
	-- mapper callback 
	-- map a quad index in the atlas to a tile (x,y)
	local mapfunc = function(x,y,v) 
		if v == '-' then return 1
		elseif v == '@' then return 2
		elseif v == 'q' then return 3
		elseif v == 'x' then return 4 end
	end
	
	-- mapper callback for mapdata
	local mapfunc2 = function(x,y,v)
		return v
	end
	
	---------------------------------------------------------
	---------------------------------------------------------
	-- create our maps (Note that all parameters after mapfunc are optional)
	map1= map.new(sheet,sheetatlas,mapstring,mapfunc)	
	-- create a map: each tile has quad width = 16, quad height = 16
	-- and horizontal spacing = 32, vertical spacing = 32
	map2= map.new(sheet,sheetatlas,maptable,mapfunc, 0,0,16,16, 32,32)
	map3= map.new(sheet,sheetatlas,mapdata1,mapfunc2, nil,nil,nil,nil, 18,18)
	
	
	-- flip a tile
	map3:setFlip(1,1,true,true)
	-- rotate a tile
	map3:setAngle(2,1,3.14/2)
	-- hide a tile
	map3:setVisible(3,1,false)
		
	---------------------------------------------------------
	---------------------------------------------------------	
		
	x,y     = 0,0
	vx,vy   = 0,0
	velocity= 400
end

function love.keypressed(k)
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

function love.keyreleased(k)
	if k == 'd' or k == 'a' then
		vx = 0
	end
	if k == 'w' or k == 's' then
		vy = 0
	end
end

function love.update(dt)
	dx,dy= vx*dt,vy*dt
	x    =x+dx y=y+dy
end

function love.draw()
	gr.push()
	
		gr.translate(-math.floor(x),-math.floor(y))
		gr.rectangle('line',0,0,800,600)
		
	
		-- only render chunks in this range
		map1:setViewport(x,y,800,600)
		
		-- omit arguments to draw everything
		-- map1:setViewport()
		
		-- draw(x,y,r,sx,sy,ox,oy,kx,ky)
		map1:draw(0,0)
		
		
		-- draw slightly askewed and enlarge
		map2:draw(0,300,3.14/10,2)
		
		-- draw the happy face
		map3:draw(500,300)
	
	gr.pop()
	
	-- minimap showing chunks in view
	gr.push()
	
		gr.translate(600,0)
		gr.scale(0.25)
		gr.rectangle('line',0,0,800,600)
		
		
		map1:draw(0,0)
		map2:draw(0,300,3.14/10,2)
		map3:draw(500,300)
	
	gr.pop()
	gr.rectangle('line',600,0,200,150)
end