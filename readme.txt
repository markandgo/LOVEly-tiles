Tools for loading and rendering tile maps. See the demo branch for example.

atlas.lua
	Creates an atlas of quads for an image. Useful for animation or tile rendering
	
grid.lua
	Generic grid class
	
mapdata.lua
	mapdata.lua is an extenson of the grid class. It converts a string/table/imageData into a useable grid of values.
	
map.lua
	Uses an image and atlas to create a map object. A map object is a grid of spritebatch "chunks". One can add or remove tiles from the map using setAtlasIndex.
	
isomap.lua
	This lib is a subclass of map. It loads/draws isometric maps. 
	NOTE: 
	The grid x axis direction is down right,and y axis direction is down left
	tiles have width/height of 1 unit length in isometric coordinates
	setViewport sets the viewport **IN ISOMETRIC COORDINATES**, e.g. setViewport(0,0,2,2) draws sprite batches found in the 4 unit area
	The draw origin is located at the top corner of the isometric grid at (1,1).
	
drawstack.lua
	A generic draw stack class. It can do layer manipulation and parallax effects.