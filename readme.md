# LOVEly Tiles

This repository contains a collection of classes to assist in loading and rendering tile maps.

## Table of Contents ###################################################

[grid](#grid)  
[atlas](#atlas)  
[mapdata](#mapdata)  
[map](#map)  
[isomap](#isomap)  
[drawstack](#drawstack)  

## grid ###################################################
[top](#table-of-contents)

The grid class stores a matrix of values.

---------------------------------------------------------------------------------------------------
**grid.new()**

Returns a new grid object.

---------------------------------------------------------------------------------------------------
**grid:set(x,y,v)**

Sets a value for the given grid coordinates. The coordinates must be integers.

---------------------------------------------------------------------------------------------------
**grid:get(x,y)**

Returns the value associated with the given coordinates.

---------------------------------------------------------------------------------------------------
**grid:clear(x,y,v)**

Clears the grid of all values.

---------------------------------------------------------------------------------------------------
**grid:rectangle(x,y,x2,y2[,skipNil])**

Returns an iterator. The iterator function iterates over all coordinates in the rectangle and returns **x,y,v**. If **skipNil** is **true**, then the iterator will skip all nil values.

---------------------------------------------------------------------------------------------------
**grid:iterate()**

Returns an iterator. The iterator function iterates through all non-nil values in the grid and returns **x,y,v**.

---------------------------------------------------------------------------------------------------
**grid:map(func)**

Iterates through all coordinates and call **func** to set new values such that **newv = func(x,y,v)**.

## atlas ###################################################
[top](#table-of-contents)

The atlas class creates an object that contains an atlas of quads.

---------------------------------------------------------------------------------------------------
**atlas.new(imageW,imageH,quadW,quadH[,atlasW,atlasH,ox,oy,xspacing,yspacing])**

Returns a new atlas object. The atlas object is a grid of quads, indexed by their row and column number. The row index increases from top to bottom, and the column index increases from left to right. The **atlasW** `quadW` and **atlasH** `quadH` parameters are the dimensions of your sheet containing the sprites or tiles. **ox** `0` and **oy** `0` are the origin offsets for your sheet from the top left corner of the image. **xspacing** `0` and **yspacing** `0` specifies the spacing between the quads.

---------------------------------------------------------------------------------------------------
**atlas:getRows()**

Returns the number of rows in the atlas.

---------------------------------------------------------------------------------------------------
**atlas:getColumns()**

Returns the number of columns in the atlas.

---------------------------------------------------------------------------------------------------
**atlas:geImageSize()**

Returns the width and height of the image (not the atlas).

---------------------------------------------------------------------------------------------------
**atlas:getqSize()**

Returns the width and height of each quad.

---------------------------------------------------------------------------------------------------
**atlas:getqViewport(index)**

Returns the viewport **x,y,w,h** of a specific quad. The **index** can be a number or a table that contains the column index as the first element and the row index as the second element. For the numerical **index**, quads are counted by columns from the first row to the last row.

---------------------------------------------------------------------------------------------------
**atlas:draw(image,index[,...])**

Draws a quad with the specified image and index. **...** are standard drawing parameters in LOVE.

## mapdata ###################################################
[top](#table-of-contents)
	
Mapdata is a subclass of the grid. It converts a map data into a useful mapdata object.

---------------------------------------------------------------------------------------------------
**mapdata.new(data[,func])**

Returns a new mapdata object. The first argument is a map data to be converted. It can be a string, array, grid, or imagedata. If the data is an array, The table field "width" and "height" must contain the dimensions of the map. If the data is a grid, the values must be indexed by rows then by columns such that **v = grid[row][column]**.

The second argument is an optional callback function for mapping values. It iterates through all values in data and call **func** to set mapdata values such that **v = func(x,y,...)**. **...** is dependent on the type of data. Note that the origin is located on the top left corner of tile (1,1).

**Callback arguments**:

For **imagedata**, the mapdata coordinates and pixel colors are passed as arguments. If no callback is given, a table is returned containing the colors such that **{r=r,g=g,b=b,a=a} = func(x,y,r,g,b,a)** (same colors return the same tables). 

For **string**, the mapdata coordinates and non-space characters and are passed as arguments. If no callback is given, **char** is returned such that **char = func(x,y,char)**. 

For **grid**/**array**, the mapdata coordinates and grid/array values are passed as arguments. If no callback is given, **v** is returned such that **v = func(x,y,v)**.

---------------------------------------------------------------------------------------------------
**mapdata.imageData(imagedata)**

Returns an iterator which iterates through all pixels. The returned values for each iteration are **x,y,r,g,b,a**. Note that top left pixel starts at (**1,1**).

---------------------------------------------------------------------------------------------------
**mapdata.string(string)**

Returns an iterator which iterates through all non-space characters. The returned values for each iteration are **x,y,char**.

---------------------------------------------------------------------------------------------------
**mapdata.array(array,width,height)**

Returns an iterator which iterates through all values in the array. The returned values for each iteration are **x,y,v**. The **width** and **height** parameters accept the dimensions of the map.

---------------------------------------------------------------------------------------------------
**mapdata.grid(grid)**

Returns an iterator which iterates through all values in the grid. The returned values for each iteration are **x,y,v**. The grid is row ordered such that **v = grid[y][x]**.

---------------------------------------------------------------------------------------------------
**mapdata.iterateData(data)**

Autodetects the data type and returns one of the above iterators.

## map ###################################################
[top](#table-of-contents)

The map class is used to create a drawable map object.

---------------------------------------------------------------------------------------------------
**map.new(image,atlas[, tw,th])**

Returns an empty map object. A map object is a collection of sprite batches. The tilewidth `quadwidth` and tileheight `quadheight` parameters are optional.

---------------------------------------------------------------------------------------------------
**map:setAtlasIndex(tx,ty[,index])**

Assign an atlas index to a tile. The index parameter accepts a table or number like an atlas. If no index is given, the tile will not be drawn. Assigning an index will reset the angle and flip status.

---------------------------------------------------------------------------------------------------
**map:getAtlasIndex(tx,ty)**

Get the atlas index of a tile. Returns a number or nil if nothing is assigned.

---------------------------------------------------------------------------------------------------
**map:setProperty(tx,ty,v)**

Assigns a custom value to the tile coordinates. This is similar to **grid:set**. Could be useful for tagging additional information of a tile.

---------------------------------------------------------------------------------------------------
**map:getProperty(tx,ty)**

Returns the custom value assigned to the tile coordinates. This is similar to **grid:get**

---------------------------------------------------------------------------------------------------
**map:setImage(image)**

Sets an image for the tile textures.

---------------------------------------------------------------------------------------------------
**map:getImage()**

Returns the image in use by the map.

---------------------------------------------------------------------------------------------------
**map:setFlip(tx,ty,flipx,flipy)**

Sets the flip status of a tile. **flipx** must be true to flip horizontally and likewise for **flipy** to flip vertically.

---------------------------------------------------------------------------------------------------
**map:getFlip(tx,ty)**

Returns the flip status of a tile. Two values are returned; the first value is true if the tile is flipped horizontally and likewise for the second value for a vertical flip.

---------------------------------------------------------------------------------------------------
**map:setAngle(tx,ty,angle)**

Sets the angle in radians of a tile. All tiles have a starting angle of 0.

---------------------------------------------------------------------------------------------------
**map:getAngle(tx,ty)**

Returns the angle of a tile.

---------------------------------------------------------------------------------------------------
**map:setViewport(x,y,w,h)**

Sets the rectangular viewport. All sprite batches found in viewing range are drawn. The parameters are relative to the origin, which is located at the top left corner of tile (1,1). Note that graphical transformations are not applied.

---------------------------------------------------------------------------------------------------
**map:draw(x,y,r,sx,sy,ox,oy,kx,ky)**

Draws the map. The parameters are like the ones in love.graphics.draw. The draw origin is by default located at the top left corner of tile (1,1).

## isomap ###################################################
[top](#table-of-contents)

The isomap class is a subclass of the map class. In the isometric coordinate system, the positive x axis points down right, and the positive y axis points down left. When setting the viewport, take note that the numbers correspond with the isometric coordinate system; the width/height of tiles have unit lengths of 1. Also, the draw origin is located at the top vertex of the first tile (1,1) diamond.

## drawstack ###################################################
[top](#table-of-contents)

The drawstack class is for managing layers so you can draw things in a certain order. 

---------------------------------------------------------------------------------------------------
**drawstack.new()**

Returns a new drawstack object for managing layers.

---------------------------------------------------------------------------------------------------
**drawstack:add(layer,index[,xtransfactor,ytransfactor,isDrawable])**

Insert a layer at the given index. Index must start at 1 and must be sequenced so that 1,2,3,... . If no layer is specified, one will be created automatically. If no index is specified, the layer is inserted at the top of the stack. Works similar to **table.insert**. **xtransfactor** `0` and **ytransfactor** `0` affects how much translation is done with **drawstack:translation** such that **translation = transfactor * delta**. **isDrawable** `true` accepts a boolean; true if the layer is visible.

---------------------------------------------------------------------------------------------------
**drawstack:addObj(obj[,index,position])**

Add a table to to the drawstack at the given layer index and position in the layer. All tables must have a draw method ( **obj:draw** ). If no index is given, The object is inserted into the last layer. If no position is given, add the table to the last position in the layer. 

---------------------------------------------------------------------------------------------------
**drawstack:remove(index)**

Remove a layer at the given index.

---------------------------------------------------------------------------------------------------
**drawstack:removeAll()**

Remove all layers.

---------------------------------------------------------------------------------------------------
**drawstack:copy(index)**

Copy a layer and insert it to index+1.

---------------------------------------------------------------------------------------------------
**drawstack:swap(index,index2)**

Swap two given layer indices.

---------------------------------------------------------------------------------------------------
**drawstack:move(index,direction)**

Move a layer up or down. **direction** accepts the string "up" or "down".

---------------------------------------------------------------------------------------------------
**drawstack:merge(index,direction)**

Merge a layer up or down.

---------------------------------------------------------------------------------------------------
**drawstack:sort(func)**

Sort the layers with the given callback **func** like **table.sort**.

---------------------------------------------------------------------------------------------------
**drawstack:sortObj(index,func)**

Sort the objects for the given layer.

---------------------------------------------------------------------------------------------------
**drawstack:totalLayers()**

Returns the total amount of layers in the drawstack.

---------------------------------------------------------------------------------------------------
**drawstack:setDrawable(index,bool)**

Sets true for the layer to be drawable.

---------------------------------------------------------------------------------------------------
**drawstack:isDrawable(index)**

Returns true if the layer is drawable.

---------------------------------------------------------------------------------------------------
**drawstack:translate(dx,dy)**

Translates the drawstack and apply the translation factors per layer.

---------------------------------------------------------------------------------------------------
**drawstack:setTranslation(x,y)**

Sets the absolute translation.

---------------------------------------------------------------------------------------------------
**drawstack:setTransFactors(index,xfactor,yfactor)**

Sets the x and y translation factors for the given layer.

---------------------------------------------------------------------------------------------------
**drawstack:draw(...)**

Draw all layers and pass additional arguments to each object such that **object:draw(...)**.