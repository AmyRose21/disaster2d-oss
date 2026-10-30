/// @description Insert description here
// You can write your code in this editor
//image_xscale = mouse_x - x
//image_yscale = mouse_y - y

timer += 1
if timer % cspeed == 0 {
	for (var i = 0; i < amount; i += 1) {
		randomize()
		randomitem = types[random(array_length(types))]
		sizing = random_range(size[0],size[1])
		hitspark(x+random_range(0,image_xscale),y+random_range(0,image_yscale),sizing,sizing,randomitem)
	}
	i = 0
}