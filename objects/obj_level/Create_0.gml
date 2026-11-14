global.timeSeconds = 0;
global.timeMinutes = 0;
global.ringFrame = 0;
global.lmsActive = false;

// v3/v4 (D.I.B.) — estado de ronda de JINNA (se resetea en cada arranque):
//  * jinnaTelePower: frames restantes de la ventana de poder del tele-
//    transporte (3 s: hitbox del golpe basico +25% en los clientes de
//    las victimas; la abre SERVER_JINNA_PORTAL_STATE).
//  * v18: MEJORAS ACUMULATIVAS del portal trampa — un flag por ESPECIAL
//    atrapada (Vanilla / Amy Canon / Sally Canon / Amelia). Ya no hay un
//    tier unico: cada una suma "+" sobre los valores base del kit y las
//    bonos se apilan (Amy Canon vale doble; Rouge y la generica no suman).
//    Lo alimenta SERVER_JINNA_TRAP_HIT en TODOS los clientes.
global.jinnaTelePower = 0;
global.jinnaCaughtAmy = false;
global.jinnaCaughtSally = false;
global.jinnaCaughtVanilla = false;
global.jinnaCaughtAmelia = false;
state = 0;
showSurvivors = false;
survivorTimer = 0;
timeFrame = 0;
clockAngle = 0;
bloodFade = 0;
hideFade = 0;

titleCard = 0;

// v1 OPTIONS MORE: media movible del tiempo de frame (PERFORMANCE on)
perfAvg = 0;
cardX = 480;
cardY = -270;
depth = -1000;
instance_create_depth(0, 0, 0, obj_playerui);

// [v1.2 IN-GAME CHAT] HUD de chat SOLO para supervivientes: el EXE no ve
// ni usa el chat en partida (por ahora). exeId ya viene asignado de la
// votacion (antes del charselect), asi que aqui ya se sabe si el local es
// el EXE; por si cambiara a mitad de ronda, obj_game_chat/Step tambien se
// autodestruye como blindaje (ver objects/obj_game_chat).
if(obj_netclient.exeId != obj_netclient.nid)
        instance_create_depth(0, 0, -1200, obj_game_chat);

drawPing = function(char, exeCharacter, ping, revival, name, index)
{       
        var hchar = char - 1;
        // fix v5.1: los resolvedores scr_hud_* piden el PERSONAJE, no el
        // frame de spr_tab_entry. Antes se les pasaba `char` DESPUES del
        // remapeo (Tails pedia el frame -1 de la tira hit y todos los
        // iconos de golpe/demon salian desplazados una fila).
        var _hudch = char;
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
                // v3 (D.I.B.): Jinna (6.a killer, EXE_JINNA=5) TAMBIEN usa
                // la fila 15 (la X misteriosa de Metal Amy): sin este caso la
                // formula la mandaba a la 11 (la fila de Sonic) y salia con
                // cara ajena en el marcador TAB. Killer exclusiva = fila
                // misteriosa, mismo criterio que Metal Amy.
                if(exeCharacter == EXE_JINNA)
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
        // v4.4: Rouge -> fila de Knuckles (frame 1): spr_tab_entry no
        // tiene fila propia para ella y el char-- la mandaria a la de
        // Fleetway (13). El icono hit/demon del marcador cae en el
        // frame de Knuckles de las tiras (mismo criterio que Fleetway
        // con Amy).
        else if(char == CHARACTER_ROUGE)
                char = 1;
        else
                char--;
        
        draw_sprite(spr_tab_entry, char, 480/2, 44 + index * 30);
        
        if(hchar > -1)
        {
                // [Suite v5.1] tiras por resolvedor (propias o común), con el
                // PERSONAJE original (_hudch). Solo se dibuja si fue golpeado
                // (revival >= 1) o demonizado (>= 2), como siempre: un jugador
                // vivo y sin golpes NO lleva icono aqui.
                if(revival >= 1)
                {
                        var _tabPair = revival >= 2 ? scr_hud_demon(_hudch) : scr_hud_hit(_hudch);
                        draw_sprite(_tabPair[0], _tabPair[1], 480/2-113 + 1, 43 + index * 30 + 28);
                }
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