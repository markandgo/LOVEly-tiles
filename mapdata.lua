local path= (...):match('^.+%.') or ''
local grid= require (path..'grid')
local md  = grid.new()
md.__index= md

function md.new(data,func)
	local self = grid.new()
	local type = type(data)
	if type == 'userdata' and data:typeOf('ImageData') then
		local colors = {}
		func = func or function(x,y,r,g,b,a) 
			local index   = r..','..g..','..b
			colors[index] = colors[index] or {r= r,g= g,b= b,a= a}
			return colors[index]
		end
		local w,h   = data:getHeight(), data:getWidth()
		for x = 1,w do
			for y = 1,h do
			 grid.set(self,x,y,func(x,y,data:getPixel(x-1,y-1)))
			end
		end
	elseif type == 'string' then
		func = func or function(x,y,v) return v end
		local y = 1
		local x = 0
		for char in data:gmatch('.') do
			if char == '\n' then 
				y = y + 1; x = 0 
			else 
				x = x + 1 
				if char:match('[^%s]') then 
					grid.set(self,x,y,func(x,y,char))
				end
			end
		end
	elseif type == 'table' then
		func = func or function(x,y,v) return v end
		for y,t in pairs(data) do
			for x,v in pairs(t) do
				grid.set(self,x,y,func(x,y,v))
			end
		end
	else 
		error('Invalid map data!')
	end
	return setmetatable(self,md)
end

return md