//Level setup code — porte 1:1 de Sonic MAX roomEmeraldHill1 (11264x1024)
scr_play_music(mus_kindandfair);

global.parallax = [
        [ layer_get_id("Background"), 0.9, 1, 0 ],
        [ layer_get_id("Background2"), 0.5, 1, 128 ],
]

scr_level_split(spr_smax_eh_tiles, 100, true, 16);
