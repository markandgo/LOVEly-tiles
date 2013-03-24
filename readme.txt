Tools for loading and rendering tile maps

atlas.lua
	Creates an atlas of quads for an image. Useful for animation or tile rendering
	
grid.lua
	Generic grid class
	
mapdata.lua
	mapdata.lua is an extenson of the grid class. It converts a string/table/imageData into a useable grid of values.
	
map.lua
	Uses an image,atlas,and mapdata/string/table/imageData to create a map object. A map object is a grid of spritebatch "chunks".
	
isomap.lua
	This lib is a subclass of map. It loads/draws isometric maps. 
	NOTE: 
	+tx is down right,+ty is down left
	tiles have width/height of 1 unit length in isometric coordinate
	setViewport sets the viewport **IN ISOMETRIC WORLD**, e.g. setViewport(0,0,2,2) draws sprite batches found in the 4 unit area
	The draw origin is located at the top corner of tile (1,1)
	