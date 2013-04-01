local __setings = {__index = function(t,k) rawset(t,k,{}) return t[k] end,__mode= 'k'}

local t   = {}
t.__index = t

function t.new()
	local drawstack = {
		layers   = {},
		settings = setmetatable({},__setings),
		x        = 0,
		y        = 0,
	}
	return setmetatable(drawstack,t)
end

function t:add(layer,i,xtransfactor,ytransfactor,isDrawable)
	i           = i or #self.layers+1
	layer       = layer or {}
	isDrawable  = isDrawable or true
	xtransfactor= xtransfactor or 0
	ytransfactor= ytransfactor or xtransfactor
	table.insert(self.layers,i,layer)
	local t        = self.settings[layer]
	t.isDrawable   = isDrawable
	t.xtransfactor = xtransfactor
	t.ytransfactor = ytransfactor
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

function t:copy(i)
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
	self.settings[self.layers[i]].isDrawable = bool
end

function t:isDrawable(i)
	return self.settings[self.layers[i]].isDrawable
end

function t:translate(dx,dy)
	self.x,self.y = self.x+dx,self.y+dy
end

function t:setTranslation(x,y)
	self.x,self.y = x,y
end

function t:setTransFactors(i,xfactor,yfactor)
	self.settings[self.layers[i]].xtransfactor = xfactor
	self.settings[self.layers[i]].ytransfactor = yfactor or xfactor
end

function t:draw(...)
	local set   = self.settings
	for i,layer in ipairs(self.layers) do
		love.graphics.push()
		local xfactor = self.settings[layer].xtransfactor
		local yfactor = self.settings[layer].ytransfactor
		local dx,dy   = xfactor*self.x, yfactor*self.y
		love.graphics.translate(dx,dy)
		if set[layer].isDrawable then
			for j,obj in ipairs(layer) do
				obj:draw(...)
			end
		end
		love.graphics.pop()
	end
end

return t