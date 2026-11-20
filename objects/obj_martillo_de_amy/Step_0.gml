// =====================================================================
//  v52 — SUPER AMY (HAMMER THROW): el vuelo del martillo. RECTO hacia
//  adelante + spriteroll (rota sobre su centro: el origin del sprite
//  esta en el centro del contenido para que el giro pivote justo ahi).
//  Failsafes de retiro: muro (scr_fw_wall_at — la MISMA jerarquia de
//  pisos que siente el jugador, la de la flecha de Fleetway v2.15.2:
//  nunca atraviesa un mapa), borde del mapa o tope de vida (4 s).
//  El GOLPE mira SOLO a puppets del bando EXE (exe real o esbirro
//  demonizado, visibles): los supervivientes lo atraviesan limpio.
// =====================================================================

// vuelo recto + spriteroll (rueda en el sentido del vuelo)
x += AMY_SUPER_HTHROW_SPEED * dir;
image_angle += AMY_SUPER_HTHROW_SPIN * dir;
life--;

// fuera de mapa o tope de vida: se retira sin golpe
if(life <= 0 || x <= 1 || x >= room_width - 1)
{
        instance_destroy();
        return;
}

// muro: la misma jerarquia de pisos del jugador (ver scr_fw_wall_at)
if(scr_fw_wall_at(x, y))
{
        instance_destroy();
        return;
}

// GOLPE: puppet del bando EXE tocando el martillo. La senal viaja como
// snd_none posicionado EN el nid de la victima y SU cliente se aturde
// a si mismo con scr_amy_super_hammer_signal (3.5 s, IGNORA i-frames).
// Efectos locales del impacto: particula + snap + shake (el grito y el
// stun canonico los manda la propia victima desde su signal).
var _hit = noone;

if(instance_exists(obj_player_puppet))
{
        var _list = ds_list_create();
        var _n = collision_rectangle_list(x + bbox_left, y + bbox_top, x + bbox_right, y + bbox_bottom, obj_player_puppet, false, true, _list, false);

        for(var i = 0; i < _n; i++)
        {
                var _p = _list[| i];

                if(_p.isInactive || !_p.visible)
                        continue;

                if(_p.character != CHARACTER_EXE && !_p.isDemonized)
                        continue;   // solo el bando del exe

                _hit = _p;
                break;
        }

        ds_list_destroy(_list);
}

if(_hit != noone)
{
        net_sound_emit_at(snd_none, _hit.master_id);

        // impacto local en la pantalla de Amy (la victima manda el canonico)
        net_quick_effect(_hit.x, _hit.y, spr_shockparticle, false, 1, 0, 0, 1);
        audio_play_sound(snd_snap, 0, false);
        scr_camera_shake(20, 2, 0.2);

        instance_destroy();
        return;
}