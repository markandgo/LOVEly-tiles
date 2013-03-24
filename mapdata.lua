local path= (...):match('^.+%.') or ''
local grid= require (path..'grid')
local md  = grid.new()
md.__index= md

function md.new(data,func)
	local self = grid.new()
	if type == 'userdata' and data:typeOf('ImageData') then
		local colors = {}
		func = func or function(x,y,r,g,b,a) 
			local index   = r..','..g..','..b
			colors[index] = colors[index] or {r= r,g= g,b= b,a= a}
			return colors[index]
		end
	else
		func = func or function(x,y,v) return v end
	end
	for x,y, a,b,c,d in md.iterateData(data) do
		grid.set(self,x,y,func(x,y,a,b,c,d))
	end
	return setmetatable(self,md)
end

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

function md.stringMap(string)
	return coroutine.wrap(function()
		local y = 1
		local x = 0
		for char in string:gmatch('.') do
			if char == '\n' then 
				y = y + 1; x = 0 
			else 
				x = x + 1 
				if char:match('[^%s]') then 
					coroutine.yield(x,y,char)
				end
			end
		end	
	end)
end

function md.iterateData(data)
	local type = type(data)
	if type == 'userdata' and data:typeOf('ImageData') then
		return md.imageData(data)
	elseif type == 'string' then
		return md.stringMap(data)
	elseif type == 'table' then
		return coroutine.wrap(function()
			for y,t in pairs(data) do
				for x,v in pairs(t) do
					coroutine.yield(x,y,v)
				end
			end
		end)
	else 
		error('Invalid map data!')
	end
end

return md