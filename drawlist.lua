local __settings = {__index = function(t,k) rawset(t,k,{}) return t[k] end,__mode= 'k'}

local t   = setmetatable({},{__call = function(self,...) return self.new(...) end})
t.__call  = function(self,i) return self.layers[i] end
t.__index = t

function t.new()
	local d = {
		layers   = {},
		settings = setmetatable({},__settings),
		x        = 0,
		y        = 0,
	}
	return setmetatable(d,t)
end

function t:setLayerPath(i,path)
	local layer = self.layers[i]
	self.settings[layer].path = path
end

function t:getLayerPath(i)
	local layer = self.layers[i]
	return self.settings[layer].path
end

function t:getLayer(i)
	return self.layers[i]
end

function t:insert(layer,i,xtransfactor,ytransfactor,isDrawable)
	i           = i or #self.layers+1
	xtransfactor= xtransfactor or 1
	ytransfactor= ytransfactor or xtransfactor
	table.insert(self.layers,i,layer)
	local t        = self.settings[layer]
	t.isDrawable   = isDrawable == nil and true or isDrawable
	t.xtransfactor = xtransfactor
	t.ytransfactor = ytransfactor
end

function t:remove(i)
	return table.remove(self.layers,i)
end

function t:removeAll()
	self.layers = {}
end

function t:swap(i,i2)
	assert(self.layers[i] and self.layers[i2],'Cannot swap empty layer(s)!')
	self.layers[i],self.layers[i2] = self.layers[i2],self.layers[i]
end

local directions = {
	down = function(index,layers) layers[index-1],layers[index] = layers[index],layers[index-1] end, 
	up   = function(index,layers) layers[index+1],layers[index] = layers[index],layers[index+1] end, 
	front= function(index,layers) table.insert(layers, table.remove(layers,index) )             end, 
	back = function(index,layers) table.insert(layers, 1, table.remove(layers,index) )          end,  
}

function t:move(i,direction)
	assert(i > 0,'layer index cannot be less than 1')
	assert(directions[direction],'Invalid direction')
	directions[direction](i,self.layers)
end

function t:sort(func)
	table.sort(self.layers,func)
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

function t:getTranslation()
	return self.x,self.y
end

function t:setTransFactors(i,xfactor,yfactor)
	self.settings[self.layers[i]].xtransfactor = xfactor
	self.settings[self.layers[i]].ytransfactor = yfactor or xfactor
end

function t:getTransFactors(i)
	return self.settings[self.layers[i]].xtransfactor, self.settings[self.layers[i]].ytransfactor
end

function t:iterate()
	return ipairs(self.layers)
end

function t:callback(callback_name,...)
	if callback_name == 'draw' then return t.draw(self,...) end
	for i,layer in ipairs(self.layers) do
		if layer[callback_name] then layer[callback_name](layer,...) end
	end
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
			if layer.draw then layer:draw(...) end
		end
		love.graphics.pop()
	end
end

return t