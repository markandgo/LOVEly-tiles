local getIndex = function(self,the_layer)
	for i,layer in ipairs(self.layers) do
		if layer == the_layer then return i end
	end
end

local t   = setmetatable({},{__call = function(self,...) return self.new(...) end})
t.__call  = function(self,name) return self:getLayer(name) end
t.__index = t

function t.new()
	local d = {
		layers    = {},
		settings  = {},
		x         = 0,
		y         = 0,
		
		properties= {},
		atlases   = {},
	}
	return setmetatable(d,t)
end

function t:getLayer(name)
	return self.settings[name] and self.settings[name].layer
end

function t:insert(name,layer,xtranscale,ytranscale,isDrawable)
	xtranscale= xtranscale or 1
	ytranscale= ytranscale or xtranscale
	table.insert(self.layers,layer)
	local t             = self.settings[name] or {}
	self.settings[name] = t
	self.settings[layer]= t
	t.isDrawable        = isDrawable== nil and true or isDrawable
	t.xtranscale        = xtranscale
	t.ytranscale        = ytranscale
	t.layer             = layer
end

function t:remove(name)
	local the_layer = self:getLayer(name)
	for i,layer in ipairs(self.layers) do
		if layer == the_layer then table.remove(self.layers,i) break end
	end
	self.settings[name]      = nil
	self.settings[the_layer] = nil
	return the_layer
end

function t:clear()
	self.layers   = {}
	self.settings = {}
	self.x,self.y = 0,0
end

function t:swap(name1,name2)
	local layer1 = self:getLayer(name1)
	local layer2 = self:getLayer(name2)
	local i1,i2
	for i,layer in ipairs(self.layers) do
		if layer == layer1 then i1 = i end
		if layer == layer2 then i2 = i end
		if i1 and i2 then 
			break
		end
	end
	self.layers[i1],self.layers[i2] = layer2,layer1
end

local directions = {
	down = function(layers,index) 
		if index < 1 then return end 
		layers[index-1],layers[index] = layers[index],layers[index-1]
	end, 
	up   = function(layers,index) 
		if index == #layers then return end
		layers[index+1],layers[index] = layers[index],layers[index+1]
	end, 
	top    = function(layers,index) table.insert(layers,    table.remove(layers,index) ) end, 
	bottom = function(layers,index) table.insert(layers, 1, table.remove(layers,index) ) end,  
}

function t:move(name,direction)
	assert(directions[direction],'Invalid direction')
	local index = getIndex(self:getLayer(name))
	directions[direction](self.layers,index)
end

function t:sort(func)
	table.sort(self.layers,func)
end

function t:setDrawable(name,bool)
	if bool == nil then error('expected true or false for drawable') end
	self.settings[name].isDrawable = bool
end

function t:isDrawable(name)
	return self.settings[name].isDrawable
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

function t:setTranslationScale(name,xscale,yscale)
	self.settings[name].xtranscale = xscale
	self.settings[name].ytranscale = yscale or xscale
end

function t:getTranslationScale(name)
	return self.settings[name].xtranscale, self.settings[name].ytranscale
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
		local xscale = self.settings[layer].xtranscale
		local yscale = self.settings[layer].ytranscale
		local dx,dy  = xscale*self.x, yscale*self.y
		love.graphics.translate(dx,dy)
		if set[layer].isDrawable then
			if layer.draw then layer:draw(...) end
		end
		love.graphics.pop()
	end
end

-- ####################################
-- TMX RELATED FUNCTIONS
-- ####################################

function t:getAtlas(name)
	return self.atlases[name]
end

function t:getMapProperties()
	return self.properties
end

return t