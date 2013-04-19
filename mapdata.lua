local wrap  = coroutine.wrap
local yield = coroutine.yield

local path  = (...):match('^.+[%.\\/]') or ''
local grid  = require (path..'grid')
local md    = {}

function md.imageData(imageData)
	local w,h      = imageData:getHeight(), imageData:getWidth()
	local x,y,x2,y2= 0,0,w-1,h-1
	local xi,yi    = x-1,y
	return function()
		while true do
			xi = xi+1
			if xi > x2 then yi = yi + 1; xi = x end
			if yi > y2 then return end
			return xi+1,yi+1,imageData:getPixel(xi,yi)
		end
	end
end

function md.string(string)
	return wrap(function()
		local y = 1
		local x = 0
		for char in string:gmatch('.') do
			if char == '\n' then 
				y = y + 1; x = 0 
			else 
				x = x + 1 
				if char:match('[^%s]') then 
					yield(x,y,char)
				end
			end
		end	
	end)
end

function md.array(array,w,h)
	return wrap(function()
		local x,y = 0,1
		w,h       = w or array.width,h or array.height
		for i,v in ipairs(array) do
			x = x+1
			if x > w then x = 1; y = y+1 end
			yield(x,y,v)
		end
	end)
end

function md.grid(grid)
	return wrap(function()
		for y,t in pairs(grid) do
			for x,v in pairs(t) do
				yield(x,y,v)
			end
		end
	end)
end

return md