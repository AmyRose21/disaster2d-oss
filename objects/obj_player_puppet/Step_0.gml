isDemonized = revivalTimes >= 2 || character == CHARACTER_EXE;

if(alarm[2] > 0)
{
        x += xspd;
        y += yspd;
}

if(reviveObj != noone)
{
        reviveObj.master_id = master_id;
        reviveObj.x = x;
        reviveObj.y = y - 40;
}

if(healObj != noone)
{
        healObj.x = floor(x);
        healObj.y = floor(y) - 45;
}

if(isInactive)
        image_blend = c_dkgray;
else 
        image_blend = c_white;
        
if(room == room_act9)
        image_blend = c_black;

if(character == -1)
        return;

// SALLY CANON fase 2: el squash & stretch del salto (pt3) y del
// aterrizaje (pt4) se deriva SOLO del estado sincronizado: al ver la
// transicion pt2->pt3 se estira, pt3->pt4 se aplasta, y decae solo
// (mismo feel que el jugador local, sin datos extra por red).
if(character == CHARACTER_SALLY_CANON)
{
        if(state == SALLY_CANON_F2_PT3 && f2LastState != SALLY_CANON_F2_PT3)
                f2Sq = SALLY_CANON_SQ_STRETCH;
        
        if(state == SALLY_CANON_F2_PT4 && f2LastState != SALLY_CANON_F2_PT4)
                f2Sq = SALLY_CANON_SQ_SQUASH;
        
        f2LastState = state;
        f2Sq += (0 - f2Sq) * SALLY_CANON_SQ_DECAY;
        
        if(abs(f2Sq) < 0.01)
                f2Sq = 0;
}

// SONIC POWERBOOST (Nervios de Acero): el Sonic remoto deja estela
// de fantasmas mientras dura (bitflag PLAYER_POWERBOOST de
// CLIENT_PLAYER_DATA). Mismo efecto de corta duracion que el jugador
// local: un quickeffect_fade justo detras del puppet.
if(powerBoost)
{
        // la estela sale solo en movimiento (parado queda solo el aura,
        // como el boost de Frontiers); la posicion llega por red, asi que
        // el movimiento se mide con el desplazamiento real del puppet.
        ghostTimer++;
        
        if((abs(x - xprevious) + abs(y - yprevious) > 0.1) && ghostTimer mod SONIC_NERVIOS_GHOST_EVERY == 0)
        {
                var _ghost = instance_create_depth(x, y, 0, obj_quickeffect_fade);
                _ghost.sprite_index = sprite_index;
                _ghost.image_index = image_index;
                _ghost.image_xscale = image_xscale;
                _ghost.image_yscale = 1;
                _ghost.image_angle = radtodeg(angle);
                _ghost.fadeSpeed = SONIC_NERVIOS_GHOST_FADE;
                _ghost.depth = depth + 1; // detras del puppet
        }
}

if(character == CHARACTER_TAILS)
{
        if(state != TAILS_FLY && audio_is_playing(snd_tails_fly))
                audio_stop_sound(snd_tails_fly);
}

// TAROT de Amy Canon: cortar los loops del tarot cuando el estado
// termina en este cliente (mismo patron que el vuelo de Tails: el
// estado ya viene sincronizado en CLIENT_PLAYER_DATA y quien emite
// los sonidos los re-envia cada cierto tiempo mientras dura el
// estado, asi el corte tambien corta el re-envio). OJO con las
// transiciones directas flotacion <-> impulso: DSTAROT2 solo suena
// flotando (se corta al pasar a TAROTDASH), Loop_Card suena en ambos
// (se corta al salir de los dos), igual que en el jugador local.
if(character == CHARACTER_AMY_CANON)
{
        if(state != AMY_CANON_TAROT && audio_is_playing(DSTAROT2))
                audio_stop_sound(DSTAROT2);
        if(state != AMY_CANON_TAROT && state != AMY_CANON_TAROTDASH && audio_is_playing(Loop_Card))
                audio_stop_sound(Loop_Card);
}

if(instance_exists(obj_hiding_parent))
        isHiding = place_meeting(x, y, obj_hiding_parent) && state == LOOKDOWN;

var gain = 1.0 - (min(distance_to_point(obj_camera.x + 240, obj_camera.y + 135), 700) / 700.0);
audio_emitter_position(emitter, x, y, 0);
audio_emitter_gain(emitter, gain);

if(!instance_exists(global.player))
        return;
        
var globalExe = (global.character == CHARACTER_EXE || global.player.revivalTimes >= 2);

//hack
if((character == CHARACTER_AMY || character == CHARACTER_AMY_CANON) && state == AMY_HJUMP && image_index < 3)
        isAttacking = true;

// IMPULSO AEREO DE AMY CANON (habilidad 2, tecla X): el stuneo al killer
// le entra hasta ~5px de distancia (distance_to_object mide entre
// bounding boxes), asi el dash lo caza aunque el roce sea minimo: la
// hitbox efectiva queda ~20% mas grande (AMY_CANON_TAROTDASH_HITBOX_PAD).
var _acTarotPad = (character == CHARACTER_AMY_CANON && state == AMY_CANON_TAROTDASH && distance_to_object(global.player) <= AMY_CANON_TAROTDASH_HITBOX_PAD);

// SALTO DE MARTILLO DE AMY CANON (Abajo+Z): mismo pad para el swing
// (frames 0-2 del HJUMP, los mismos en los que el hack de arriba pone
// isAttacking en true). AMY_CANON_HJUMP y AMY_HJUMP valen lo mismo
// (BALANCING+2), asi que el hack de la Amy original ya la cubre.
var _acHJPad = (character == CHARACTER_AMY_CANON && state == AMY_CANON_HJUMP && image_index < 3 && distance_to_object(global.player) <= AMY_CANON_HJUMP_HITBOX_PAD);

// ATAQUE DE SONIC: hitbox de stuneo ampliada segun la variante del
// golpe: en el AIRE es 30% mas grande (SONIC_ATTACK_AIRE_PAD) y en
// tierra la variante 2 o superior un 20% (SONIC_ATTACK_TIERRA2_PAD).
// La variante 1 de tierra usa el contacto normal (place_meeting),
// como siempre. El estado ya codifica la variante: SONIC_ATK_AIRE o
// mas (aire) / SONIC_ATK_TIERRA+1 en adelante (tierra variante 2+).
// Si empezo en el aire sigue contando como aire aunque aterrice: la
// variante se fijo al empezar el golpe.
var _sonicPad = 0;
if(character == CHARACTER_SONIC && isAttacking)
{
        if(state >= SONIC_ATK_AIRE)
                _sonicPad = SONIC_ATTACK_AIRE_PAD;
        else if(state >= SONIC_ATK_TIERRA + 1)
                _sonicPad = SONIC_ATTACK_TIERRA2_PAD;
}

if(place_meeting(x, y, global.player) || _acTarotPad || _acHJPad || (_sonicPad > 0 && distance_to_object(global.player) <= _sonicPad))
{
        if(isAttacking)
        {
                if(isDemonized && visible)
                {
                        if(global.character == CHARACTER_EXE)
                                return;
                        
                        if((character != CHARACTER_AMY && character != CHARACTER_AMY_CANON) && character != CHARACTER_EGGMAN)
                        {
                                if((global.character == CHARACTER_KNUX || global.character == CHARACTER_SALLY) && global.player.isAttacking && global.player.revivalTimes < 2)
                                {
                                        global.player.isAttacking = false;
                                        global.player.isHurt = true;
                                        global.player.hurttime = 60;
                                        global.player.xspd = sign(global.player.x - x) * 3;
                                        global.player.yspd = -2;
                                        global.player.isGrounded = false;
                                        audio_play_sound(snd_buble, 0, false);
                                        net_sound_emit(snd_buble);
                                        return;
                                }
                        }
                        
                        if(global.player.hurttime <= 0 && global.player.hp > 0)
                        {
                                if(global.player.revivalTimes >= 2)
                                        return;
                                
                                if((character != CHARACTER_AMY && character != CHARACTER_AMY_CANON))
                                {
                                        if(global.character == CHARACTER_EGGMAN && global.player.isAttacking)
                                                return;
                                }
                                
                                if((global.character == CHARACTER_AMY || global.character == CHARACTER_AMY_CANON) && global.player.isAttacking)
                                        return;
                                        
                                if(global.character == CHARACTER_SALLY && global.player.shieldTimer > 0)
                                {                       
                                        global.player.isGrounded = false;
                                        global.player.isHurt = true;
                                        global.player.hurttime = 60;
                                        global.player.xspd = sign(global.player.x - x) * 2;
                                        global.player.yspd = -2;
                                        global.player.shieldTimer = 0;
                                        
                                        if(global.player.revivalTimes < 2 && global.player.hp <= 20)
                                        {
                                                obj_achivements.rSallyShield++;
                                                
                                                if(obj_achivements.rSallyShield >= 2 && room != room_fartzone && !obj_achivements.achivements[32])
                                                {
                                                        obj_achivements.achivements[32] = true;
                                                        obj_achivements.show();
                                                        obj_achivements.save();
                                                        
                                                        obj_achivements.mercoins += 75;
                                                        obj_achivements.save();
                                                }
                                        }
                                        global.player.hurttime = 60;
                                        
                                        audio_play_sound(snd_sally_shieldbreak, 0, false);
                                        net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                                        net_sound_emit(snd_sally_shieldbreak);
                                        return;
                                }
                                
                                var damage = 20;
                                if(character == CHARACTER_EXE)
                                {
                                        switch(exeCharacter)
                                        {
                                                case 0:
                                                case 2:
                                                case 3:
                                                        damage = 40;
                                                        break;
                                        }
                                }
                                
                                if(character == CHARACTER_EGGMAN && global.player.hurttime <= 0)
                                        scr_player_slow(3);
                                        
                                if((character == CHARACTER_AMY || character == CHARACTER_AMY_CANON))
                                {
                                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                                        buffer_write(pak, buffer_u16, master_id);
                                        buffer_write(pak, buffer_u8, 3);
                                        send_server_tcp(pak);
                                }
                                
                                // exeSource=true: dano de un ataque del lado EXE (el parry de
                                // Sonic puede negarlo en scr_player_hurt)
                                scr_player_hurt(damage, image_xscale * 3, -3, snd_hurt, spr_blood3, false, true);
                                
                                if(character == CHARACTER_EXE)
                                {
                                        if(exeCharacter == EXE_CHAOS && sprite_index == spr_chaos_attack2)
                                        {
                                                var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                                                buffer_write(pak, buffer_u16, master_id);
                                                buffer_write(pak, buffer_u8, 10);
                                                send_server_tcp(pak);
                                        }
                                        
                                        scr_exe_checkwin();
                                }
                                
                                obj_level.bloodFade = 1;
                                obj_camera.spectatingObj = noone;
                                
                                var buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
                                buffer_write(buffer, buffer_u16, master_id);
                                buffer_write(buffer, buffer_u16, x);
                                buffer_write(buffer, buffer_u16, y);
                                buffer_write(buffer, buffer_u16, 0);
                                send_server_tcp(buffer);
                                
                                if(revivalTimes >= 2 && global.player.hp <= 0)
                                {
                                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                                        buffer_write(pak, buffer_u16, master_id);
                                        buffer_write(pak, buffer_u8, 4);
                                        send_server_tcp(pak);
                                }
                                
                                if(revivalTimes >= 2 && character == CHARACTER_KNUX && sprite_index == spr_eknux_attack2)
                                {
                                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                                        buffer_write(pak, buffer_u16, master_id);
                                        buffer_write(pak, buffer_u8, 8);
                                        send_server_tcp(pak);
                                }
                                
                                var buffer = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(buffer, buffer_u8, 2);
                                buffer_write(buffer, buffer_u16, master_id);
                                buffer_write(buffer, buffer_u16, damage);
                                buffer_write(buffer, buffer_u16, global.player.hp);
                                send_server_tcp(buffer);
                                
                                return;
                        }
                }
                
                if(!isDemonized && globalExe)
                {
                        if(global.character == CHARACTER_EXE && global.player.invisTimer > 0)
                                return;
                        
                        if((global.character != CHARACTER_AMY && global.character != CHARACTER_AMY_CANON) && global.character != CHARACTER_EGGMAN)
                        {
                                if(global.player.isAttacking && (character == CHARACTER_KNUX || character == CHARACTER_SALLY))
                                {
                                        global.player.isAttacking = false;
                                        global.player.isHurt = true;
                                        global.player.hurttime = 60;
                                        global.player.xspd = sign(global.player.x - x) * 2;
                                        global.player.yspd = -2;
                                        global.player.isGrounded = false;
                                        audio_play_sound(snd_buble, 0, false);
                                        net_sound_emit(snd_buble);
                                        return;
                                }
                        }
                        
                        if(global.player.shockedTimer <= 0 && global.player.hurttime <= 0)
                        {
                                if(global.character == CHARACTER_SALLY && global.player.shieldTimer > 0)
                                {                       
                                        global.player.isGrounded = false;
                                        global.player.isHurt = true;
                                        global.player.hurttime = 60;
                                        global.player.xspd = sign(global.player.x - x) * 2;
                                        global.player.yspd = -2;
                                        global.player.shieldTimer = 0;
                                        
                                        audio_play_sound(snd_sally_shieldbreak, 0, false);
                                        net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                                        net_sound_emit(snd_sally_shieldbreak);
                                        return;
                                }
                                
                                if((global.character == CHARACTER_AMY || global.character == CHARACTER_AMY_CANON) && global.player.isAttacking)
                                        return;
                                
                                var stunTime = 3;
                                // IMPULSO AEREO DE AMY CANON (tarot): el stuneo dura 2s en
                                // vez de 3 mientras ella este en ese estado.
                                if(character == CHARACTER_AMY_CANON && state == AMY_CANON_TAROTDASH)
                                        stunTime = 2;
                                var snd = snd_exe_stun;
                                var xxspd = -sign(x - global.player.x) * 4;
                                                                
                                if(character == CHARACTER_EGGMAN)
                                {
                                        net_quick_effect(global.player.x, global.player.y, spr_shockparticle);
                                        stunTime = 2;
                                        snd = snd_electroshock;
                                        xxspd = 0;
                                }
                                
                                var buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
                                buffer_write(buffer, buffer_u16, master_id);
                                buffer_write(buffer, buffer_u16, x);
                                buffer_write(buffer, buffer_u16, y);
                                buffer_write(buffer, buffer_u16, stunTime);
                                send_server_tcp(buffer);
                                
                                if(character == CHARACTER_KNUX && sprite_index == spr_knux_attack2)
                                {
                                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                                        buffer_write(pak, buffer_u16, master_id);
                                        buffer_write(pak, buffer_u8, 9);
                                        send_server_tcp(pak);
                                }
                                
                                if(global.character == CHARACTER_SALLY)
                                        global.player.isSliding = false;
                                
                                global.player.shockedTimer = stunTime * 60;
                                global.player.xspd = xxspd;
                                global.player.yspd = -2;
                                global.player.isGrounded = false;
                                audio_play_sound(snd, 0, false);
                                net_sound_emit(snd);
                                
                                var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(pak, buffer_u8, 1);
                                buffer_write(pak, buffer_u16, obj_netclient.nid);
                                buffer_write(pak, buffer_u16, master_id);
                                buffer_write(pak, buffer_u8, stunTime);
                                send_server_tcp(pak);
                                
                                if((character == CHARACTER_AMY || character == CHARACTER_AMY_CANON))
                                {
                                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                                        buffer_write(pak, buffer_u16, master_id);
                                        buffer_write(pak, buffer_u8, 11);
                                        send_server_tcp(pak);
                                }
                                
                                if(global.character == CHARACTER_EXE)
                                {
                                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                                        buffer_write(pak, buffer_u16, master_id);
                                        buffer_write(pak, buffer_u8, 1);
                                        send_server_tcp(pak);
                                        
                                        scr_exe_stunsound();
                                }
                                return;
                        }
                }
        }
        
        // =================================================================
        //  PARRY DE SONIC (lado del ATACANTE): el jugador local es el EXE
        //  o un esbirro y su ataque (golpe / escudo / salto / rodadura)
        //  esta tocando a ESTE puppet. Si esa victima esta cubierta por la
        //  ventana activa del parry de un Sonic (es el propio Sonic o un
        //  aliado dentro de su aura de 56px), el ataque queda PARRYADO:
        //  el atacante se aturde a si mismo IGNORANDO sus i-frames y su
        //  escudo se consume entero. Corre en el cliente del atacante:
        //  cada maquina es autoridad sobre su propio jugador (mismo modelo
        //  que el stun normal de arriba).
        //  El EXE invisible NO se parrea (consistente: invisible no pega
        //  ni puede ser stuneado, igual que el bloque de arriba).
        // =================================================================
        if(globalExe && !isDemonized && visible && !isInactive
        && !(global.character == CHARACTER_EXE && global.player.invisTimer > 0)
        && (global.player.isAttacking || global.player.isJumping || global.player.isSpinning))
        {
                if(scr_parry_try_stun_attacker())
                        return;
        }
}