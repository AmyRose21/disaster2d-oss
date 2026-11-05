global.timeSeconds = 0;
global.timeMinutes = 0;
global.ringFrame = 0;
global.lmsActive = false;
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
        // [Suite v5.1] hit/demon por resolvedor (tiras propias de Sally
        // Canon/Vanilla o la común): sin remapeos a mano.
        if(char == CHARACTER_EXE)
        {
                hchar = -1;
                char += CHARACTER_SALLY;
                char += exeCharacter;
                // v4.10: Metal Amy (5.a killer, EXE_METALAMY=4) tiene fila
                // PROPIA en spr_tab_entry (frame 15, cara de spr_lobby_exeicon6).
                // Antes la formula la mandaba al frame 10 — que es la fila de
                // Amy (superviviente) — y en el marcador TAB la asesina salia
                // con la cara equivocada.
                if(exeCharacter == EXE_METALAMY)
                        char = 15;
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
        // v2.14.2: Fleetway Amy -> fila de Amy (frame 3): spr_tab_entry aun no
        // tiene fila propia (15 frames, 0..14) y el char-- la mandaria a la de
        // Amelia (13). El icono hit/demon del marcador si sale con su arte
        // nuevo: hchar = 14-1 = 13 cae justo en su frame dedicado de las tiras.
        else if(char == CHARACTER_FLEETWAY_AMY)
                char = 3;
        else
                char--;
        
        draw_sprite(spr_tab_entry, char, 480/2, 44 + index * 30);
        
        if(hchar > -1)
        {
                // [Suite v5.1] tiras por resolvedor (propias o común)
                var _tabPair = revival >= 2 ? scr_hud_demon(char) : scr_hud_hit(char);
                draw_sprite(_tabPair[0], _tabPair[1], 480/2-113 + 1, 43 + index * 30 + 28);
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