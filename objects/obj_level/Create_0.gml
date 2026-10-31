global.timeSeconds = 0;
global.timeMinutes = 0;
global.ringFrame = 0;
state = 0;
showSurvivors = false;
survivorTimer = 0;
timeFrame = 0;
clockAngle = 0;
bloodFade = 0;
hideFade = 0;

titleCard = 0;
cardX = 480;
cardY = -270;
depth = -1000;
instance_create_depth(0, 0, 0, obj_playerui);

drawPing = function(char, exeCharacter, ping, revival, name, index)
{       
        var hchar = char - 1;
        // v2.5 (fix HUD TAB): mismo remapeo que obj_level/Draw_64.gml para el
        // icono hit/demon. Sin esto Sally Canon/Vanilla caian en los frames
        // 8/9 de spr_playerhealth_hit/demon (placeholders transparentes) y su
        // icono de golpe/demonizacion quedaba invisible en el marcador TAB.
        if(char == CHARACTER_SALLY_CANON)
                hchar = CHARACTER_SALLY - 1;
        else if(char == CHARACTER_VANILLA)
                hchar = CHARACTER_CREAM - 1;
        
        if(char == CHARACTER_EXE)
        {
                hchar = -1;
                char += CHARACTER_SALLY;
                char += exeCharacter;
        }
        else if(char == CHARACTER_AMY_CANON)
                char = 10; // Amy Canon: frame 10 de spr_tab_entry
        else if(char == CHARACTER_SONIC)
                char = 11; // Sonic: frame 11 de spr_tab_entry
        // v2.2 (barras nuevas): Metal/Amelia/Blaze -> frames 12/13/14 de
        // spr_tab_entry (filas extraidas del data.win de TTB). Sin esto el
        // `char--` del final los mandaria a 10/11/12 (colision con AmyCanon/Sonic).
        else if(char == CHARACTER_METAL)
                char = 12; // Metal: frame 12
        else if(char == CHARACTER_AMELIA)
                char = 13; // Amelia: frame 13
        else if(char == CHARACTER_BLAZE)
                char = 14; // Blaze: frame 14
        else
                char--;
        
        draw_sprite(spr_tab_entry, char, 480/2, 44 + index * 30);
        
        if(hchar > -1)
        {
                if(revival >= 2)
                        draw_sprite(spr_playerhealth_demon, hchar, 480/2-113 + 1, 43 + index * 30 + 28);
                else if(revival >= 1)
                        draw_sprite(spr_playerhealth_hit, hchar, 480/2-113 + 1, 43 + index * 30 + 28);
        }
        
        var clr = #0fff39;
        if(ping <= 0)
        {
                ping = string_copy("...", 0, (current_time / 500) % 4);
                clr = #ff0001;
        }
        else
        {
                if(ping >= 80 && ping < 160)
                        clr = #ffc400;
                else if(ping >= 160)
                        clr = #ff0001;
                        
                ping = $"{ping}ms";
        }
        
        scr_text_spr(127+59, 44+11 + index * 30, name, c_white);
        scr_text_spr(127+183, 44+11 + index * 30, $"{ping}", clr);
}