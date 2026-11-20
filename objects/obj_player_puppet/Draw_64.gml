// v2.13 (ECLIPSE de «Sol y Luna»): cegado el bando EXE, tampoco ve el
// HUD de ningun superviviente (nick/HP/anillos) — «todos se
// esfumaron». Sus esbirros (isDemonized) si conservan su HUD.
// v17 (NEGAGEN): cegado el SUPERVIVIENTE por la trampa de una Amelia
// NEGA, es el HUD del bando EXE el que no renderiza (el otro lado).
if(global.eclipseTimer > 0
&& instance_exists(global.player)
&& ((global.character == CHARACTER_EXE || global.player.revivalTimes >= 2) ? !isDemonized : isDemonized))
        return;

if(instance_exists(obj_deserttown_i))
{
        var _coll = position_meeting(x, y, obj_deserttown_trigger);
        if(_coll != obj_deserttown_i.coll)
                return;
}

if(!isHiding)
{
        var _colour = room == room_act9 ? c_dkgray : c_white;
        
        if(hp > 0 && character != CHARACTER_EXE)
        {
                var frame = 5;

                if(hp >= 100)
                        frame = 5;
                else if(hp >= 75)
                        frame = 4;
                else if(hp >= 50)
                        frame = 3;
                else if(hp >= 25)
                        frame = 2;
                else if(hp > 0)
                        frame = 1
                else
                        frame = 0;

                // v6 (minions): el MINION de Jinna tiene VIDA REAL y su barra
                // la muestra (frame por hp, igual que un superviviente — el
                // hp ya viaja en el CLIENT_PLAYER_DATA de siempre). El esbirro
                // comun (demonizado normal) sigue con su barra fija frame 0.
                // v11 (NEGAGEN): el SUBDITO NEGATIVO usa la BARRA NEGA propia
                // (spr_hp_nega: inversion con contorno intacto) con SU vida
                // real — mismo canon que su cuerpo en sprites nega.
                if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
                        draw_sprite_ext(hasRedRing ? spr_hp_rr_nega : spr_hp_nega, frame, floor(x-obj_camera.x), floor(y-obj_camera.y) - 45, 1, 1, 0, _colour, 1);
                else
                        draw_sprite_ext(hasRedRing ? spr_hp_rr : spr_hp, (isDemonized && !isMinion) ? 0 : frame, floor(x-obj_camera.x), floor(y-obj_camera.y) - 45, 1, 1, 0, _colour, 1);
        }
        
        if(nicknameWidth == 0)
                nicknameWidth = scr_text_spr(0, 0, nickname);
        
        if(global.showHud)
        {
                // v10 (NEGAGEN): el nombre del SUBDITO NEGATIVO va en TURQUESA
                // (el color de su piel invertida), NO en rojo exe: es un
                // MINION ALTERNATIVO que conserva su identidad de personaje
                // invertida. El esbirro comun sigue rojo como siempre.
                if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
                        scr_text_spr(floor(x-obj_camera.x) - nicknameWidth / 2, floor(y-obj_camera.y) - 43, nickname, room == room_act9 ? c_dkgray : #30e0c8, 1);
                else if(character == CHARACTER_EXE || isDemonized)
                        scr_text_spr(floor(x-obj_camera.x) - nicknameWidth / 2, floor(y-obj_camera.y) - 43, nickname, room == room_act9 ? c_dkgray : c_red, 1);
                else
                        scr_text_spr(floor(x-obj_camera.x) - nicknameWidth / 2, floor(y-obj_camera.y) - 43, nickname, room == room_act9 ? c_dkgray : (hasRedRing ? #9943ad : c_green), 1);
        }
        
        if(!isDemonized && hp > 0)
                scr_number_spr(floor(x-obj_camera.x) - 2, floor(y-obj_camera.y) - 45 - 12, string(rings), _colour);

        // v47 (T2, duena): "los demas jugadores deberian ver el nivel
        // de Violencia de kris". El LV del puppet de Kris con la MISMA
        // disposicion del jugador local (una linea encima del contador
        // de anillos, y este a 12 px de la barra) y el MISMO color
        // progresivo: blanco en el LV 1, rojo pleno en el LV 20.
        // krisLvNet es el espejo de la senal silenciosa v46 (sin
        // senales recibidas vale 1 = LV inicial). Lo ve TODO el que
        // ya ve la barra de siempre: el exe, los esbirros y el resto
        // de supervivientes (eclipse/isHiding siguen cortando arriba).
        if(!isDemonized && hp > 0 && character == CHARACTER_KRIS)
        {
                var _klv = variable_instance_exists(id, "krisLvNet") ? krisLvNet : 1;
                var _klvCol = room == room_act9 ? c_dkgray : merge_color(c_white, c_red, (_klv - 1) / (KRIS_LV_MAX - 1));
                scr_text_spr(floor(x-obj_camera.x) - 14, floor(y-obj_camera.y) - 45 - 24, "lv " + string(_klv), _klvCol, 1);
        }
}