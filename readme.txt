Tools for loading and rendering tile maps

atlas.lua
	Creates an atlas of quads for an image. Useful for animation or tile rendering
	
grid.lua
	Generic grid class
	
mapdata.lua
	mapdata.lua is an extenson of the grid class. It converts a string/table/image into a useable grid of values.
	
map.lua
	Uses an image,atlas,and mapdata to create a map object. A map object is a grid of spritebatch "chunks".