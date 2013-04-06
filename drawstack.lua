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
	xtransfactor= xtransfactor or 0
	ytransfactor= ytransfactor or xtransfactor
	table.insert(self.layers,i,layer)
	local t        = self.settings[layer]
	t.isDrawable   = isDrawable == nil and true or isDrawable
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

function t:swap(i,i2)
	assert(self.layers[i] and self.layers[i2],'Cannot swap empty layer(s)!')
	self.layers[i],self.layers[i2] = self.layers[i2],self.layers[i]
end

function t:move(i,direction)
	assert(i > 0,'layer index cannot be less than 1')
	local oi
	if direction == 'down' then
		oi = -1
	elseif direction == 'up' then
		oi = 1
	else 
		error('invalid direction value')
	end
	local layer     = self.layers[i]
	local otherlayer= self.layers[i+oi]
	assert(layer and otherlayer,'Cannot move layer out of sequence')
	self.layers[i] = otherlayer; self.layers[i+oi]=layer
end

function t:merge(i,direction)
	assert(i > 0,'layer index cannot be less than 1')
	local oi
	if direction == 'down' then
		oi = -1
	elseif direction == 'up' then
		oi = 1
	else 
		error('invalid direction value')
	end
	local layer     = self.layers[i]
	local otherlayer= self.layers[i+oi]
	if direction == 'up' then
		for j = #layer,1,-1 do
			table.insert(otherlayer,1,layer[j])
		end
	else
		for j = 1,#layer do
			table.insert(otherlayer,layer[j])
		end
	end
	table.remove(self.layers,i)
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