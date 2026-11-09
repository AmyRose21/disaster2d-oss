//Level setup code
scr_play_music(mus_alphagentemple);

global.parallax = [
	[ layer_get_id("Backgrounds2"), 0.8, 1 ],
	[ layer_get_id("Background"), 0.6, 1 ],
]

scr_level_split(spr_nt_tiles, 100);
scr_level_split(spr_nt_tiles2, 90);
scr_level_split(spr_nt_tiles3, 450);
