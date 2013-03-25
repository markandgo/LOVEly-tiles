local t = {layers = {},__isDrawable = setmetatable({},{__mode = 'k'})}

function t.add(layer,i,isDrawable)
	layer       = layer or {}
	isDrawable  = isDrawable or true
	table.insert(t.layers,i or #t.layers+1,layer)
	t.__isDrawable[layer] = isDrawable
end

function t.addObj(obj,i,pos)
	i = i or #t.layers
	table.insert(t.layers[i],pos or #t.layers[i]+1,obj)
end

function t.remove(i)
	table.remove(t.layers,i)
end

function t.removeAll()
	t.layers = {}
end

function t.move(i,direction)
	assert(i > 0,'layer index cannot be less than 1')
	if direction == 'down' then
		direction = -1
	elseif direction == 'up' then
		direction = 1
	else 
		error('invalid direction value')
	end
	local layer     = t.layers[i]
	local otherlayer= t.layers[i+direction]
	if otherlayer then t.layers[i] = otherlayer; t.layers[i+direction]=layer end
end

function t.merge(i,direction)
	assert(i > 0,'layer index cannot be less than 1')
	if direction == 'down' then
		direction = -1
	elseif direction == 'up' then
		direction = 1
	else 
		error('invalid direction value')
	end
	local layer     = t.layers[i]
	local otherlayer= t.layers[i+direction]
	if otherlayer then 
		local j   = 1
		local obj = layer[j]
		while obj do
			if direction == 'up' then
				table.insert(otherlayer,obj)
			elseif direction == 'down' then
				table.insert(otherlayer,obj)
			end
			j 	= j + 1
			obj = layer[j]
		end
		table.remove(t.layers,i)
	end
end

function t.sortLayers(func)
	table.sort(t.layers,func)
end

function t.sortObj(i,func)
	table.sort(t.layers[i],func)
end

function t.setDrawable(i,bool)
	if bool == nil then error('expected true or false for drawable') end
	t.__isDrawable[t.layers[i]] = bool
end

function t.isDrawable(i)
	return t.__isDrawable[t.layers[i]].isDrawable
end

function t.draw(...)
	local layer     = t.layers[1]
	local isDrawable= t.__isDrawable
	local i         = 1
	while layer do
		if isDrawable[layer] then
			local obj= layer[1]
			local j  = 1
			while obj do
				obj:draw(...)
				j 	= j + 1
				obj = layer[j]
			end
		end
		i 		= i + 1
		layer = t.layers[i]
	end
end

return t