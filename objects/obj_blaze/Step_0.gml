/// @description General movement (v2.2 TTB: Blaze)
if(shockedTimer <= 0)
{
        scr_move_basic();
}
else
{
        burning = 0;
        shootPose = 0;
        isBoosting = false;
        isLookingDown = false;
        isLookingUp = false;
        isAttacking = false;
        isJumping = false;
        gspd -= min(abs(gspd), acc) * sign(gspd);
        xspd -= min(abs(xspd), acc) * sign(xspd);
        shockedTimer--;
        hurttime = 60 * 2;
        ringsSpawn = 0;
}

// v2.9 — GIRO DE FUEGO: velocidad horizontal PRE-colision (para el
// rebote elastico contra paredes: la colision la pone a 0)
var _pvx = max(abs(gspd), abs(xspd));

scr_collision_basic();

// =====================================================================
//  v2.9 — GIRO DE FUEGO (tecla C): mientras arde, Blaze es un
//  remolino de fuego que REBOTA en el suelo, las paredes y el techo
//  (patron pinball). Suelo: rebota siempre con la fuerza del salto
//  (a la misma altura, como una pelota viva); pared: rebote
//  elastico (conserva la velocidad que traia, minimo 3); techo: la
//  suelta hacia abajo. El jugador sigue pudiendo dirigir en el aire
//  (scr_move_basic) y el salto de fuego (Z) sigue disponible a media
//  altura. El stun de 3 s al killer que la toque y el +30% de
//  velocidad de la forma ardiente quedan intactos.
// =====================================================================
if(burning > 0 && !isDead && shockedTimer <= 0 && !isZipline && !isHiding && redRingTimer <= 0)
{
        // SUELO: en vez de aterrizar, rebota hacia arriba
        if(isGrounded && yspd >= 0)
        {
                yspd = -BLAZE_BURN_BOUNCE;
                isGrounded = false;
                isJumping = true; // el salto de fuego (Z) sigue disponible

                net_quick_effect(x, y + 16, spr_dust);
        }

        // PARED: rebote elastico horizontal (solo en suelo plano: en
        // cuestas el chequeo lateral daria falsos positivos)
        if(angle == 0)
        {
                var _wall = 0;

                if(place_meeting(x + 4, y, obj_floor_parent))
                        _wall = 1;
                else if(place_meeting(x - 4, y, obj_floor_parent))
                        _wall = -1;

                if(_wall != 0)
                {
                        var _sp = max(_pvx, 3);
                        gspd = _sp * -_wall;
                        xspd = _sp * -_wall;
                        image_xscale = -_wall;

                        net_quick_effect(x + 10 * _wall, y, spr_shard_sparkle);
                }
        }

        // TECHO: yspd == 0 en el aire = acaba de dar con la cabeza
        // (la colision lo pone a 0): soltarla hacia abajo
        if(!isGrounded && yspd == 0 && place_meeting(x, y - 2, obj_floor_parent))
        {
                yspd = BLAZE_BURN_BOUNCE * 0.6;

                net_quick_effect(x, y - 18, spr_shard_sparkle);
        }
}

if(reviveObj != noone)
{
        reviveObj.x = x;
        reviveObj.y = y - 40;
        reviveObj.master_id = obj_netclient.nid;
}

if(redRingTimer > 0)
{
        if(redRingTimer == 1)
        {
                audio_stop_sound(mus_mindfuck);
                instance_destroy(obj_redring_screen);
        }

        redRingTimer--;
}

if(hurttime > 0)
        hurttime--;

if(hurttime > 0)
        return;

if(hp <= 0 && revivalTimes < 2)
        return;

if(bounceTimer > 0)
        return;

var list = ds_list_create();
instance_place_list(x, y, obj_player_puppet, list, false);

for(var i = 0; i < ds_list_size(list); i++)
{
        var inst = list[| i];
        if(inst.isDemonized && inst.visible && (inst.state == JUMP || inst.state == SPIN) && !isAttacking)
        {
                if(inst.character == CHARACTER_EGGMAN || (inst.character == CHARACTER_AMY || inst.character == CHARACTER_AMY_CANON) || inst.character == CHARACTER_SALLY || inst.character == CHARACTER_SALLY_CANON)
                        continue;

                if(revivalTimes >= 2)
                        continue;

                if(inst.character == CHARACTER_EXE && inst.exeCharacter == 1 && inst.slimeMode)
                        continue;

                var dmg = (isJumping || isSpinning) ? 0 : 20;
                var dirX = -sign(inst.x - x) * 3;
                var dirY = dmg == 0 ? -sign(inst.y - y) * 4 : -4;

                // exeSource=true: dano de un ataque del lado EXE (parry puede negarlo)
                scr_player_hurt(dmg, dirX, dirY, (isJumping || isSpinning) ? snd_buble : snd_hurt, spr_blood2, true, true);

                if(hp <= 0 && inst.revivalTimes >= 2)
                {
                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                        buffer_write(pak, buffer_u16, inst.master_id);
                        buffer_write(pak, buffer_u8, 4);
                        send_server_tcp(pak);
                }

                if(dmg > 0 && hurttime >= 0)
                {
                        obj_level.bloodFade = 0.4;

                        if(inst.character == CHARACTER_EXE)
                                scr_exe_checkwin();

                        var buffer = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                        buffer_write(buffer, buffer_u8, 2);
                        buffer_write(buffer, buffer_u16, inst.master_id);
                        buffer_write(buffer, buffer_u16, 20);
                        buffer_write(buffer, buffer_u16, hp);
                        send_server_tcp(buffer);
                }

                if(dmg <= 0 && bounceTimer <= -1)
                        bounceTimer = 6;
        }
}

ds_list_destroy(list);
