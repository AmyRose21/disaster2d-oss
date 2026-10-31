with(obj_netclient)
{
        audio_stop_all();
        global.ringId = 0;
        global.player = noone;
        global.character = -1;
        global.exeCharacter = -1;
        global.playerControls = true;
        ds_map_destroy(players);
        players = ds_map_create();
        exeId = -1;
        
        // Slots de personajes: se dimensionan solos
        // (ver scr_characters / scr_avchars_reset)
        avCharacters = scr_avchars_reset();
        
        state = STATE_LOBBY;
        room_goto(room_lobby);
}