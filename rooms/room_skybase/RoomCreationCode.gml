//Level setup code
scr_play_music(mus_skybase);

global.parallax = [
	[ layer_get_id("Background3"), 0.7, 1 ],
	[ layer_get_id("Background2"), 0.5, 1 ],
	[ layer_get_id("Background1"), 0.3, 1 ],
]

scr_level_split(spr_skybase_tiles, 110);
