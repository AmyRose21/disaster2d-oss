/// @description General movement

// ESTADO BURBUJA (secuestro): mientras esta dentro usa su fisica
// propia (levitacion + lateral, ver scr_amy_canon_bubble.gml);
// no corre, no salta y no puede atacar.
if(bubbleState == AMY_BUBBLE_ACTIVE)
{
        scr_amy_canon_bubble();
}
else if(shockedTimer <= 0)
{
        scr_move_basic();
}
else
{
        isBoosting = false;
        isLookingDown = false;
        isLookingUp = false;
        isAttacking = false;
        isJumping = false;
        isDashing = false; // ATAQUE 3: el electro-shock cancela la acometida
        isTarotDashing = false; // el stun tambien cancela el impulso aereo
        isTarotFloat = false;   // ... y la pasiva del tarot
        gspd -= min(abs(gspd), acc) * sign(gspd); 
        xspd -= min(abs(xspd), acc) * sign(xspd); 
        shockedTimer--;
        hurttime = 60 * 2;
}

scr_collision_basic();

// --- PASIVA TAROT FLOAT: entrada / salida / frenado de la caida ---
// Aqui, despues de scr_collision_basic, para conocer el isGrounded
// fresco de este frame y capear la yspd que la gravedad acabo de sumar.
if(isTarotFloat)
{
        // Salidas: soltar Z, tocar el suelo, o cualquier cosa que la pare.
        if(!global.playerControls || !keyboard_check(global.KeyA) || isGrounded || isHurt || isDead || shockedTimer > 0 || isZipline || isDashing || isTarotDashing || isHJ || isAttacking || bubbleState != AMY_BUBBLE_NONE)
                isTarotFloat = false;
}

// Entrada: en el aire, ya cayendo, con Z presionado. La pasiva no
// tiene cooldown: se puede usar cada vez que empiece a caer.
if(!isTarotFloat && global.playerControls && bubbleState == AMY_BUBBLE_NONE && shockedTimer <= 0
&& !isHurt && !isDead && !isZipline && !isDashing && !isTarotDashing && !isHJ && !isAttacking
&& !isGrounded && yspd > 0.5 && keyboard_check(global.KeyA))
{
        isTarotFloat = true;
        image_index = 0;
}

// La caida lenta: mientras flota, su velocidad de caida queda limitada
// a AMY_CANON_TAROT_FALLSPD (1.5 px/frame: unas 8 veces mas lento).
if(isTarotFloat)
        yspd = min(yspd, AMY_CANON_TAROT_FALLSPD);

// --- AUDIO DEL TAROT (compartido por la pasiva y el impulso aereo) ---
// DSTAROT1 + DSTAROT2 + Loop_Card en loop; arranca al entrar en
// cualquiera de los dos estados y se detiene al salir de ambos.
// Va antes de los return de abajo para que corra SIEMPRE.
if((isTarotFloat || isTarotDashing) && tarotSnd1 == -1)
{
        tarotSnd1 = audio_play_sound(DSTAROT1, 0, true);
        tarotSnd2 = audio_play_sound(DSTAROT2, 0, true);
        tarotSnd3 = audio_play_sound(Loop_Card, 0, true);
}
else if(!(isTarotFloat || isTarotDashing) && tarotSnd1 != -1)
{
        audio_stop_sound(tarotSnd1);
        audio_stop_sound(tarotSnd2);
        audio_stop_sound(tarotSnd3);
        tarotSnd1 = -1;
        tarotSnd2 = -1;
        tarotSnd3 = -1;
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

if(isAttacking || isTarotDashing || (isHJ && image_index <= 3))
        return;

var list = ds_list_create();
instance_place_list(x, y, obj_player_puppet, list, false);

for(var i = 0; i < ds_list_size(list); i++)
{
        var inst = list[| i];
        if(inst.isDemonized && inst.visible && (inst.state == JUMP || inst.state == SPIN))
        {
                if(inst.character == CHARACTER_EGGMAN || inst.character == CHARACTER_AMY || inst.character == CHARACTER_SALLY)
                        continue;
                        
                if(revivalTimes >= 2)
                        continue;
                        
                if(inst.character == CHARACTER_EXE && inst.exeCharacter == 1 && inst.slimeMode)
                        continue;
                
                var dirX = -sign(inst.x - x) * 3;
                scr_player_hurt(20, dirX, -4, snd_hurt, spr_blood2);
                
                if(hp <= 0 && inst.revivalTimes >= 2)
                {               
                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                        buffer_write(pak, buffer_u16, inst.master_id);
                        buffer_write(pak, buffer_u8, 4);
                        send_server_tcp(pak);
                }
                
                if(inst.character == CHARACTER_EXE)
                        scr_exe_checkwin();
                
                var buffer = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                buffer_write(buffer, buffer_u8, 2);
                buffer_write(buffer, buffer_u16, inst.master_id);
                buffer_write(buffer, buffer_u16, 20);
                buffer_write(buffer, buffer_u16, hp);
                send_server_tcp(buffer);
                
                obj_level.bloodFade = 0.4;
        }
}

ds_list_destroy(list);