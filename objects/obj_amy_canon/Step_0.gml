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
        if(!global.playerControls || !keyboard_check(global.KeyA) || isGrounded || isHurt || isDead || shockedTimer > 0 || isZipline || isDashing || isTarotDashing || isHJ || isAttacking || bubbleState == AMY_BUBBLE_ACTIVE)
                isTarotFloat = false;
}

// Entrada: en el aire, ya cayendo (yspd > 0: engancha en el mismo
// apex del salto), con Z presionado. La pasiva no tiene cooldown:
// se puede usar cada vez que empiece a caer. BUGFIX burbuja: antes
// se exibia el estado NONE de la burbuja y tras salir (OVER) la
// pasiva quedaba muerta; ahora solo se bloquea DENTRO (!= ACTIVE)
// y la salida de arriba solo corta DENTRO (== ACTIVE).
if(!isTarotFloat && global.playerControls && bubbleState != AMY_BUBBLE_ACTIVE && shockedTimer <= 0
&& !isHurt && !isDead && !isZipline && !isDashing && !isTarotDashing && !isHJ && !isAttacking
&& !isGrounded && yspd > 0 && keyboard_check(global.KeyA))
{
        isTarotFloat = true;
        image_index = 0;
}

// La caida lentisima: mientras flota, su velocidad de caida queda
// limitada a AMY_CANON_TAROT_FALLSPD (0.5 px/frame: 24 veces mas lenta
// que la caida normal de 12). OJO: scr_collision_basic suma la gravedad
// (yAccel) a la yspd DESPUES de este tope, al moverse en el frame
// siguiente, asi que aqui se le resta para que la caida real sea
// EXACTAMENTE el valor de la macro (mismo truco que scr_amy_canon_bubble).
if(isTarotFloat)
        yspd = min(yspd, AMY_CANON_TAROT_FALLSPD - yAccel);

// --- AUDIO DEL TAROT (cada estado con SUS sonidos) ---
// PASIVA float: DSTAROT2 + Loop_Card en loop (DSTAROT1 NO suena aqui).
// IMPULSO aereo (hab. 2, tecla X): DSTAROT1 sono 1 vez al arrancar (es
// one-shot: se apaga solo, nunca se corta ni loopea) y aqui solo va
// Loop_Card en loop. Loop_Card es compartido: en las transiciones
// directas (impulso que acaba -> sigues con Z presionado -> pasiva)
// suena sin cortarse. Va antes de los return de abajo para que corra
// SIEMPRE.
if(isTarotDashing)
{
        if(tarotSnd3 == -1)
                tarotSnd3 = audio_play_sound(Loop_Card, 0, true);
        if(tarotSnd2 != -1) // venia de la pasiva: DSTAROT2 fuera
        {
                audio_stop_sound(tarotSnd2);
                tarotSnd2 = -1;
        }
}
else if(isTarotFloat)
{
        if(tarotSnd2 == -1)
                tarotSnd2 = audio_play_sound(DSTAROT2, 0, true);
        if(tarotSnd3 == -1)
                tarotSnd3 = audio_play_sound(Loop_Card, 0, true);
}
else
{
        // Ni pasiva ni impulso: los loops fuera (DSTAROT1 ya se apago solo).
        if(tarotSnd2 != -1)
        {
                audio_stop_sound(tarotSnd2);
                tarotSnd2 = -1;
        }
        if(tarotSnd3 != -1)
        {
                audio_stop_sound(tarotSnd3);
                tarotSnd3 = -1;
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