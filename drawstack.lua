local t   = {}
t.__index = t

function t.new()
	local drawstack = {
		layers      = {},
		__isDrawable= setmetatable({},{__mode= 'k'}),
	}
	return setmetatable(drawstack,t)
end

function t:add(layer,i,isDrawable)
	i           = i or #self.layers+1
	layer       = layer or {}
	isDrawable  = isDrawable or true
	table.insert(self.layers,i,layer)
	self.__isDrawable[layer] = isDrawable
end

function t:addObj(obj,i,pos)
	i   = i or #self.layers
	pos = pos or #self.layers[i]+1
	table.insert(self.layers[i],pos,obj)
end

function t:remove(i)
	table.remove(self.layers,i)
end

function t:removeAll()
	self.layers = {}
end

function t.copy(i)
	i        = i
	local new= {}
	for i,obj in ipairs(self.layers[i]) do
		new[i] = obj
	end
	table.insert(self.layers,i+1,new)
end

function t:swap(i,i2)
	self.layers[i],self.layers[i2] = self.layers[i2],self.layers[i]
end

function t:move(i,direction)
	assert(i > 0,'layer index cannot be less than 1')
	if direction == 'down' then
		direction = -1
	elseif direction == 'up' then
		direction = 1
	else 
		error('invalid direction value')
	end
	local layer     = self.layers[i]
	local otherlayer= self.layers[i+direction]
	if otherlayer then self.layers[i] = otherlayer; self.layers[i+direction]=layer end
end

function t:merge(i,direction)
	assert(i > 0,'layer index cannot be less than 1')
	if direction == 'down' then
		direction = -1
	elseif direction == 'up' then
		direction = 1
	else 
		error('invalid direction value')
	end
	local layer     = self.layers[i]
	local otherlayer= self.layers[i+direction]
	if otherlayer then 
		for j,obj in ipairs(layer) do
			if direction == 'up' then
				table.insert(otherlayer,obj)
			elseif direction == 'down' then
				table.insert(otherlayer,obj)
			end
		end
		table.remove(self.layers,i)
	end
end

function t:sort(func)
	table.sort(self.layers,func)
end

function t:sortObj(i,func)
	table.sort(self.layers[i],func)
end

function t:totalLayers()
	return #self.layers
end

function t:setDrawable(i,bool)
	if bool == nil then error('expected true or false for drawable') end
	self.__isDrawable[self.layers[i]] = bool
end

function t:isDrawable(i)
	return self.__isDrawable[self.layers[i]].isDrawable
end

function t:draw(...)
	local isDrawable = self.__isDrawable
	for i,layer in ipairs(self.layers) do
		if isDrawable[layer] then
			for j,obj in ipairs(layer) do
				obj:draw(...)
			end
		end
	end
end

return t