var player_exists = instance_exists(global.player);

switch(room)
{
        case room_notperfect:
        case room_act9:
        case room_youcantrun:
        case room_nastyparadise:
        case room_ravinemist:
        case room_volcanovalley:
        case room_greenhill:
        case room_angelisland:
        case room_fartzone:
        case room_weedzone:
                break;
                
        default:
                // v1 OPTIONS MORE: SCREEN OVERLAYS off = sin viñeta ambiental
                if(obj_config.optOverlays)
                        draw_sprite_ext(spr_screenoverlay, 0, 0, 0, 1, 1, 0, c_white, 0.7);
                break;
                
}

// v2.13 («Sol y Luna» — ECLIPSE): velo de CEGUERA del bando EXE tras
// pisar una trampa de Amelia. Fundido de entrada/salida de ~0,5 s
// sobre los AMELIA_ECLIPSE_TIME frames (envelope triangulo: sube en
// 30 frames, baja en 30). Dibujado ANTES de los GUI para que el HUD
// del jugador (reloj/escondite/sangre) quede por ENCIMA del velo.
// Solo en el cliente de la victima — que es quien tiene el timer
// activo. Los supervivientes ya no se dibujan en su cliente
// (obj_player_puppet/Draw_0 y Draw_64): «todos se esfumaron».
if(global.eclipseTimer > 0 && instance_exists(global.player))
{
        // v17 (NEGAGEN): el velo ya no es exclusivo del bando EXE — la
        // trampa de una Amelia NEGA también CIEGA a los supervivientes
        // (excepto Amy Canon): el timer solo lo tiene la víctima, sea del
        // bando que sea, así que el lado sobra (para el superviviente
        // cegado, quien «se esfuma» es el bando EXE: ver el Draw_0/64
        // del puppet).
        var _eclT = global.eclipseTimer;
        var _eclF = min(1, min(_eclT, AMELIA_ECLIPSE_TIME - _eclT) / 30);
        
        draw_set_alpha(0.72 * _eclF);
        draw_set_color(make_color_rgb(12, 8, 24));
        draw_rectangle(0, 0, 480, 270, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
}

draw_sprite_ext(spr_hidegui, 0, 0, 0, 1, 1, 0, c_white, hideFade);
draw_sprite_ext(spr_attackgui, 0, 0, 0, 1, 1, 0, c_white, bloodFade);

if(bloodFade > 0)
        bloodFade -= 0.02;
        
if(player_exists && global.player.isHiding)
{
        if(hideFade < 1)
                hideFade += 0.02;
}
else
{
        if(hideFade > 0)
                hideFade -= 0.02;
}
if(global.showHud && titleCard > 4)
{       
        // v10: mala conexion corre a x=104 (el borde izquierdo lo ocupa
        // ahora la columna del equipo). FIX v12.1: al moverla a x=104 en la
        // v10 se cayo el chequeo ORIGINAL de udp_timeout y el icono salia
        // SIEMPRE (incluso con ping perfecto en local). Restaurado: SOLO
        // si no llega ningun paquete UDP en >2 s (udp_timeout < 60*3, el
        // contador baja desde 60*5 y se resetea con cada paquete recibido).
        if(obj_netclient.udp_timeout < 60 * 3)
                draw_sprite(spr_badconnection, floor(current_time/200) % 6, 104, 0);
        
        draw_sprite(spr_clock, 0, 211, 0);
        clockAngle = lerp(clockAngle, (-45 * timeFrame), 0.2);
        draw_sprite_ext(spr_clockhand, 0, 212, 11.5, 1, 1, clockAngle, c_white, 1);

        // v98b (duelo final — tiempo INFINITO): con el anillo retirado
        // (global.ringOff) el server ya no manda TIME_SYNC, la aguja se
        // congela sola y los contadores se reemplazan por el INFINITO:
        // el "8" del contador girado 90 grados (sus dos bucles quedan
        // lado a lado — misma placa negra y mismo glifo brillante del
        // HUD, cero sprites nuevos). OJO con la rotacion: el +90 de GM
        // gira ANTIHORARIO en pantalla, asi que el contenido queda
        // ARRIBA-DERECHA del punto de dibujo (x' en [px, px+14], y' en
        // [py-10, py]). El draw (238, 15) centra el glifo en (244.5,
        // 10.5) — el centro del bloque de numeros "M:SS" que reemplaza
        // (verificado con render PIL contra el bloque "4:37" real:
        // delta +0.5 / 0 px; el (252, 6) del primer intento quedaba a
        // +14/-6 y cortado por arriba).
        if(global.ringOff)
        {
                draw_sprite_ext(spr_counter, 8, 238, 15, 1, 1, 90, c_white, 1);
        }
        else
        {
                draw_sprite(spr_counter, 10, 233, 4);
                scr_counter_draw(global.timeMinutes, 224, 4);
                scr_counter_draw_m(global.timeSeconds, 244, 4, 2);
        }
        
        if(!showSurvivors)
        {
                if(state == 1 && (current_time / 30) % 20 < 10) // Escape!!!
                {
                        if(global.character == CHARACTER_EXE || (instance_exists(global.player) && global.player.revivalTimes >= 2))
                                draw_sprite(spr_status, 1, 480/2, 32);
                        else
                                draw_sprite(spr_status, 0, 480/2, 32);
                }
        }
        
        // v12 (ALIADOS DE ABAJO HACIA ARRIBA): la columna del borde
        // izquierdo apila los retratos 26x26 desde ABAJO — la fila PROPIA
        // vive ahora en la banda inferior 242-268 (el puesto de la vieja
        // barra verde grande, ya eliminada por pedido: UNA sola barra
        // representa tu vida, la barrita de tu retrato con "+NN") y los
        // ALIADOS suben desde justo ENCIMA de ella (el 1o pegado a tu fila,
        // el 2o mas arriba...). Cada uno con SU barra de vida AL LADO del
        // retrato (hudAllyBar: roja con funda granate y su "+NN" dentro).
        // Con 10+ filas el paso se comprime para no salir por arriba. Los
        // iconos de habilidad siguen en el rincon superior derecho
        // (obj_playerui) y el ping/fps junto al reloj.
        var _colX = 2;
        var _selfBot = 268; // fila propia: retrato y 242-268 (puesto de la vieja barra verde grande)
        var _nRows = ds_map_size(obj_netclient.players) - (ds_map_exists(obj_netclient.players, obj_netclient.exeId) ? 1 : 0);
        var _rowPitch = (_nRows <= 9) ? 26 : floor(214 / (_nRows - 1));
        
        //self icon
        if(obj_netclient.exeId != obj_netclient.nid)
        {               
                // [Suite TD2D v5.1] iconos del HUD por resolvedor: tiras propias
                // (Sally Canon / Vanilla = COPIAS independientes de las de
                // Sally/Cream) o la común con el bloque del personaje.
                var _hudChar = global.character;
                
                if(player_exists)
                {
                        if(global.player.revivalTimes < 2)
                        {
                                var sprIndex = round((1.0 - (global.player.hp / scr_player_maxhp(global.character))) * 5); // v13: max por personaje (Rouge 125 / Metal 150)
                                
                                if(global.player.hp <= 0)
                                {
                                        if(global.player.revivalTimes == 0)
                                                sprIndex = 5;
                                        else
                                                sprIndex = 6;
                                }
                                
                                var _hudPair = global.player.redRingTimer > 0 ? scr_hud_strip_red(_hudChar) : scr_hud_strip(_hudChar);
                                draw_sprite(_hudPair[0], _hudPair[1] + sprIndex, _colX, _selfBot);
                                if(global.player.revivalTimes >= 1 && global.player.hp > 0)
                                {
                                        var _hudHit = scr_hud_hit(_hudChar);
                                        draw_sprite(_hudHit[0], _hudHit[1], _colX, _selfBot);
                                }
                                
                                if(global.player.isDead)
                                {
                                        if(global.player.revivalTimes == 0 && global.player.deadTimer < 31)
                                                scr_number_spr(_colX + 12, _selfBot - 4, string(global.player.deadTimer), global.player.deadColor);
                                }
                                else if(global.player.shards > 0)
                                        scr_number_spr(_colX + 12, _selfBot - 4, string(global.player.shards), #27ff23);           
                                
                                // v12: TU barra de vida propia, al lado de tu retrato como los
                                // demas. Es LA UNICA barra que representa tu vida (la barra
                                // verde grande fue eliminada por pedido: no deben salir 2);
                                // tu fila vive en la banda 242-268, su viejo puesto.
                                hudAllyBar(_colX, _selfBot - 26, global.player.hp, scr_player_maxhp(global.character)); // v13: max por personaje
                        }
                        else
                        {
                                // v11 (NEGAGEN): el retrato del SUBDITO NEGATIVO
                                // usa la TIRA NEGA propia (spr_playerhealth_nega:
                                // inversion de la tira comun con contorno intacto —
                                // canon spr_playerhealth_negademon2) con SU frame de
                                // vida REAL. Asi el nega ve su vida REAL (60/100...)
                                // en el HUD y NO pasa por el retrato demon del esbirro.
                                if(variable_instance_exists(global.player.id, "isNegatouch") && global.player.isNegatouch)
                                {
                                        var _ngFrame = round((1.0 - (global.player.hp / scr_player_maxhp(global.character))) * 5); // v13: max por personaje
                                        
                                        if(global.player.hp <= 0)
                                                _ngFrame = 5;
                                        
                                        var _ngPair = global.player.redRingTimer > 0 ? scr_hud_strip_red_nega(_hudChar) : scr_hud_strip_nega(_hudChar);
                                        draw_sprite(_ngPair[0], _ngPair[1] + _ngFrame, _colX, _selfBot);
                                        
                                        // v10: el nega ve SU vida real tambien en la barra de su retrato propio
                                        hudAllyBar(_colX, _selfBot - 26, global.player.hp, scr_player_maxhp(global.character)); // v13: max por personaje
                                }
                                else
                                {
                                        var _hudDem = scr_hud_demon(_hudChar);
                                        draw_sprite(_hudDem[0], _hudDem[1], _colX, _selfBot);
                                }
                        }
                }
                else
                        // [Suite v5.1] escape: brillo si existe; si no, propio o común
                        if(!scr_lobby_shiny_escape(_hudChar, _colX, _selfBot))
                                scr_hud_escaped_draw(_hudChar, _colX, _selfBot);
        }
        
        var i = 0;
        for(var k = ds_map_find_first(obj_netclient.players); !is_undefined(k); k = ds_map_find_next(obj_netclient.players, k))
        {
                if(!ds_map_exists(obj_netclient.players, k))
                        continue;
                
                if(k == obj_netclient.exeId)
                        continue;
                
                var _rowBot = _selfBot - 26 - _rowPitch * i; // v12: aliados DE ABAJO HACIA ARRIBA (i=0 pegado a tu fila, los siguientes mas arriba)
                var player = obj_netclient.players[? k];
                var inst = noone;
                
                var redRing = false;
                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(master_id != k)
                                        continue;
                                        
                                inst = self;
                                redRing = hasRedRing;
                                break;
                        }
                }
                
                if(inst != noone)
                {
                        // [Suite TD2D v5.1] tiras por resolvedor (propias o común)
                        var _pch = inst.character;
                        if(!inst.isDemonized || inst.character == CHARACTER_EXE)
                        {
                                var sprIndex = round((1.0 - (inst.hp / scr_player_maxhp(_pch, inst))) * 5); // v13: max por personaje (Rouge 125 / Metal 150 / Kris por LV v95)
                                
                                if(inst.hp <= 0)
                                {
                                        if(inst.revivalTimes == 0)
                                                sprIndex = 5;
                                        else
                                                sprIndex = 6;
                                }
                                
                                var _hudPair2 = redRing ? scr_hud_strip_red(_pch) : scr_hud_strip(_pch);
                                draw_sprite(_hudPair2[0], _hudPair2[1] + sprIndex, _colX, _rowBot);
                                if(inst.revivalTimes >= 1 && inst.hp > 0)
                                {
                                        var _hudHit2 = scr_hud_hit(_pch);
                                        draw_sprite(_hudHit2[0], _hudHit2[1], _colX, _rowBot);
                                }
                                
                                if(inst.revivalTimes == 0 && inst.deadTimer < 31)
                                        scr_number_spr(_colX + 12, _rowBot - 4, string(inst.deadTimer), inst.deadColor);
                                else if(player_exists && global.character != CHARACTER_EXE && global.player.revivalTimes < 2 && !global.player.isDead && inst.shards > 0)
                                        scr_number_spr(_colX + 12, _rowBot - 4, string(inst.shards), #27ff23);
                                
                                // v10 (BARRA DE VIDA DE ALIADOS): AL LADO del retrato (como la
                                // imagen), con el hp real del puppet via UDP y su "+NN" dentro
                                hudAllyBar(_colX, _rowBot - 26, inst.hp, scr_player_maxhp(_pch, inst)); // v13: max por personaje (v95: Kris escala con su LV espejado)
                        }
                        else
                        {
                                // v11 (NEGAGEN): retrato nega del puppet — la
                                // TIRA NEGA propia (spr_playerhealth_nega) con SU
                                // frame de vida real via UDP, igual que el retrato
                                // local del nega (canon negademon2: inversion con
                                // contorno intacto). El esbirro comun sigue con su
                                // tira demon roja fija.
                                if(variable_instance_exists(inst, "isNegatouch") && inst.isNegatouch)
                                {
                                        var _ngFrame2 = round((1.0 - (inst.hp / scr_player_maxhp(_pch, inst))) * 5); // v13: max por personaje (v95: Kris por LV)
                                        
                                        if(inst.hp <= 0)
                                                _ngFrame2 = 5;
                                        
                                        var _ngPair2 = redRing ? scr_hud_strip_red_nega(_pch) : scr_hud_strip_nega(_pch);
                                        draw_sprite(_ngPair2[0], _ngPair2[1] + _ngFrame2, _colX, _rowBot);
                                        
                                        // v10: el nega del aliado tambien muestra su vida real en la barra
                                        hudAllyBar(_colX, _rowBot - 26, inst.hp, scr_player_maxhp(_pch, inst)); // v13: max por personaje (v95: Kris por LV)
                                }
                                else
                                {
                                        var _hudDem2 = scr_hud_demon(_pch);
                                        draw_sprite(_hudDem2[0], _hudDem2[1], _colX, _rowBot);
                                }
                        }
                }
                else 
                        {
                                var _ech = player.character;
                                // [Suite v5.1] escape: brillo si existe; si no, propio o común
                                if(!scr_lobby_shiny_escape(_ech, _colX, _rowBot))
                                        scr_hud_escaped_draw(_ech, _colX, _rowBot);
                        }
                        
                i++;
        }
}


if(titleCard < 8)
{
        if(cardX > 0)
                cardX -= 12;
                
        if(cardY < 0)
                cardY += 12;
}

if(titleCard < 18)
        draw_sprite_ext(spr_black, 0, 0, 0, 1, 1, 0, c_white, 1.0 - ((clamp(titleCard, 8, 16) - 8) / 8.0));

if(titleCard > 18)
{
        if(cardX < 480)
                cardX += 12;
                
        if(cardY > -270)
                cardY -= 12;
}

if(titleCard < 30)
{
        cardX = clamp(cardX, 0, 480);
        cardY = clamp(cardY, -270, 0);
        
        draw_sprite_ext(spr_titlecard2, obj_netclient.lvlId, 0, cardY, 1, 1, 0, c_white, 1);
        draw_sprite_ext(spr_titlecard1, obj_netclient.lvlId, cardX, 0, 1, 1, 0, c_white, 1);
        
        titleCard += 0.12;
}

if(global.showHud)
{
        var clr = #0fff39;
        if(obj_netclient.ping >= 80 && obj_netclient.ping < 160)
                clr = #ffc400;
        else if(obj_netclient.ping >= 160)
                clr = #ff0001;
        
        // v10: ping/fps/perf junto al reloj (x=268): antes vivian en (4,4),
        // donde ahora empieza la columna del equipo
        if(obj_netclient.ping <= 0)
                scr_text_spr(268, 4, $"waiting for players{string_copy("...", 0, (current_time / 500) % 4)}");
        else if(obj_config.showPing)
                scr_text_spr(268, 4, string(obj_netclient.ping) + "ms", clr);
        
        if(obj_config.showFps)
                scr_text_spr(268, 10, string(floor(fps_real)) + "fps");
        
        // v1 OPTIONS MORE: PERFORMANCE = tiempos de frame en pantalla (fps +
        // ms por frame con media movible; verde < 17ms, amarillo < 34, rojo
        // a partir de ahi — dos frames por segundo de presupuesto)
        if(obj_config.optPerf)
        {
                var _dt = delta_time / 1000; // microsegundos -> ms
                perfAvg = perfAvg == 0 ? _dt : lerp(perfAvg, _dt, 0.05);
                
                var _pclr = #0fff39;
                if(perfAvg >= 34) _pclr = #ff0001;
                else if(perfAvg >= 17) _pclr = #ffc400;
                
                scr_text_spr(268, 16, string(floor(fps_real)) + "fps " + string_format(perfAvg, 1, 1) + "ms", _pclr);
        }
}

//tab
if(keyboard_check(global.KeyPList))
{
        draw_sprite(spr_tab, 0, 0, 0);
        drawPing(global.character, global.exeCharacter, obj_netclient.ping, !instance_exists(global.player) ? 0 : global.player.revivalTimes, global.nickname, 0);
        
        var index = 1;
        for (var k = ds_map_find_first(obj_netclient.players); !is_undefined(k); k = ds_map_find_next(obj_netclient.players, k)) 
        {
                var plr = obj_netclient.players[? k];
                var ping = obj_netclient.pings[? k];
                var inst = noone;

                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(master_id != plr.nid)
                                        continue;
                                        
                                inst = self;
                        }
                }
                
                drawPing(plr.character, plr.exeCharacter, ping, inst == noone ? 0 : inst.revivalTimes, plr.nickname, index);
                index++;
        }
}