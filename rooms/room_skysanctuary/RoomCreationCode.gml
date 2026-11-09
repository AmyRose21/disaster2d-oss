// SkySanctuary (porte del mod "TD2DR SkySanctuaryZone mod!" de
// CranberryStudios, GameBanana 495859): rework del layout de Hide and
// Seek Act 2 con arte de ruinas flotantes. Mismo setup que el hs2 original.
//Level setup code
scr_play_music(mus_hideandseek2);

global.parallax = [
        [ layer_get_id("Background"), 0.3, 1 ],
        [ layer_get_id("Background2"), 0.2, 1 ],
]

scr_level_split(spr_skysanc_tiles, 90);