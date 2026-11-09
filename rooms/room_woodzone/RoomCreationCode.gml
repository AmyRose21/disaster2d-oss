// Wood Zone (porte del mod "Wood zone in td2dr!! MAP MOD!" de DeklynTDH,
// GameJolt 865011): rework del layout de "..." con arte de madera.
// Mismo setup que el room_dotdotdot original (parallax + level split).
global.parallax = [
        [ layer_get_id("Background"),  0.4, 0.2 ],
];

scr_level_split(spr_wood_tiles1, -50);
scr_level_split(spr_wood_tiles, 50);