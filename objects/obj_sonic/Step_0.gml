/// @description General movement

// ABRAZO COMBINADO (interaccion con Amy Canon): si una Amy cerca ya
// esta abrazandolo y Sonic esta abrazable (parado, en tierra, nada
// en manos), entra solo en SONIC_HUGGED. Va arriba del todo: si rompe
// el abrazo con una tecla, el resto del step de este frame procesa
// esa tecla con normalidad (p.ej. romper con C y parrear).
scr_amy_hug_step_sonic();

// =====================================================================
//  PASIVA NERVIOS DE ACERO
//  Fase 1: tirado en el suelo 4 seg con ..._Idle en LOOP (sin control;
//          cae plano si estaba en el aire). Inmune a TODO (scr_player_hurt).
//  Fase 2: animacion de levantarse ..._finish (SONIC_NERVIOS_FINISH_TIME).
//  Fase 3: POWERBOOST 4 seg: control total, invulnerable, con los
//          efectos Frontiers (aura + rayos + speed lines + estela de
//          fantasmas al moverse: scr_powerboost_fx).
//  Las fases 1-2 reemplazan el movimiento normal; la 3 lo deja correr
//  con normalidad (solo añade la estela y el timer).
// =====================================================================
if(nerviosState == 1 || nerviosState == 2)
{
        // Sin control: se cancela todo lo que estuviera haciendo
        isAttacking = false;
        isSpinCharging = false;
        spinCharge = 0;
        isJumping = false;
        isSpinning = false;
        isBoosting = false;
        isZipline = false;
        isHiding = false;
        isLookingDown = false;
        isLookingUp = false;
        emotion = false;
        
        // v3: la pasiva tambien corta el armado del drop dash (si
        // cayo a la agonia con la bola armada, no puede salir disparado
        // al levantarse)
        dropDashTimer = 0;
        dropDashReady = false;
        dropDashFromJump = false;
        
        // Cae plano; ya en el suelo queda clavado en el sitio
        if(isGrounded)
        {
                xspd = 0;
                gspd = 0;
                yspd = 0;
        }
        
        if(nerviosState == 1)
        {
                nerviosTimer--;
                
                if(nerviosTimer <= 0)
                {
                        // Fin de la espera: empieza a levantarse
                        nerviosState = 2;
                        nerviosTimer = SONIC_NERVIOS_FINISH_TIME;
                        image_index = 0; // el finish empieza desde el frame 0
                }
        }
        else
        {
                nerviosTimer--;
                
                if(nerviosTimer <= 0)
                {
                        // De pie: 4 segundos de powerboost (invulnerable
                        // + estela de fantasmas)
                        nerviosState = 3;
                        nerviosTimer = SONIC_NERVIOS_INVULN;
                        ghostTimer = 0;
                        pbFlash = SONIC_PB_FLASH_FRAMES; // anillo de activacion del boost
                        hp = 100;
                        
                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);
                        net_quick_effect(x, y, spr_shockparticle, false, 1, 0, 0, 1);
                }
        }
        // (la colision la aplica la llamada unica de abajo, igual que las
        // demas ramas: asi no se aplica la gravedad dos veces)
}
else if(nerviosState == 3)
{
        // POWERBOOST: se mueve y actua con total normalidad, pero va
        // dejando fantasmas detras (estilo dash de Cream) y no puede
        // recibir dano (check en scr_player_hurt).
        nerviosTimer--;
        
        if(nerviosTimer <= 0)
                nerviosState = 0; // fin de la pasiva: vuelta a la normalidad
        else
        {
                pbTime++;       // reloj de la animacion de los efectos
                ghostTimer++;
                
                // la estela sale solo en movimiento: parado se ve "cargado"
                // (aura + rayos); corriendo o en el aire si deja la estela
                if((!isGrounded || abs(xspd) + abs(gspd) > 0.5) && ghostTimer mod SONIC_NERVIOS_GHOST_EVERY == 0)
                {
                        var _ghost = instance_create_depth(x, y, 0, obj_quickeffect_fade);
                        _ghost.sprite_index = sprite_index;
                        _ghost.image_index = image_index;
                        _ghost.image_xscale = image_xscale;
                        _ghost.image_yscale = 1;
                        _ghost.image_angle = radtodeg(angle);
                        _ghost.fadeSpeed = SONIC_NERVIOS_GHOST_FADE;
                        _ghost.depth = 1; // detras del jugador (depth 0)
                }
        }
        
        scr_move_basic();
        // (la colision la aplica la llamada unica de abajo)
}
else if(shockedTimer <= 0)
        scr_move_basic();
else
{
        isBoosting = false;
        isLookingDown = false;
        isLookingUp = false;
        isAttacking = false;
        isJumping = false;
        isSpinCharging = false; // el electro-shock cancela la carga del spindash
        spinCharge = 0;
        dropDashTimer = 0;     // v3: y tambien el armado del drop dash
        dropDashReady = false;
        dropDashFromJump = false;
        gspd -= min(abs(gspd), acc) * sign(gspd); 
        xspd -= min(abs(xspd), acc) * sign(xspd); 
        shockedTimer--;
        hurttime = 60 * 2;
}

// =====================================================================
//  POWERBOOST DE REVIVE (fase 2 persistente)
//  Al ser revivido por un companero (SERVER_REVIVAL_REVIVED), Sonic
//  activa el powerboost: 6 seg de inmunidad (SONIC_REVIVEBOOST_INVULN,
//  el revive normal da 4) y los efectos visuales del boost NO se
//  apagan al acabar la inmunidad: esa es su fase 2, y dura hasta que
//  muera de verdad o se demonice. La estela solo sale en movimiento.
// =====================================================================
if(reviveBoost)
{
        pbTime++;
        
        ghostTimer++;
        
        if((!isGrounded || abs(xspd) + abs(gspd) > 0.5) && ghostTimer mod SONIC_NERVIOS_GHOST_EVERY == 0)
        {
                var _rbGhost = instance_create_depth(x, y, 0, obj_quickeffect_fade);
                _rbGhost.sprite_index = sprite_index;
                _rbGhost.image_index = image_index;
                _rbGhost.image_xscale = image_xscale;
                _rbGhost.image_yscale = 1;
                _rbGhost.image_angle = radtodeg(angle);
                _rbGhost.fadeSpeed = SONIC_NERVIOS_GHOST_FADE;
                _rbGhost.depth = 1; // detras del jugador (depth 0)
        }
        
        if(isDead || revivalTimes >= 2)
                reviveBoost = false; // murio o se demonizo: fin de la fase 2
}

if(pbFlash > 0)
        pbFlash--; // contador del anillo de activacion (lo dibuja Draw_0)

// PARRY (tecla C): maquina de fases, deteccion de exito y desvios.
// No toca el movimiento: el parry es un estado, no una postura.
scr_parry_step();

scr_collision_basic();

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

// Mientras pega o carga el spindash no procesa contactos (los muelles
// y el propio sistema ya cancelan el ataque).
if(isAttacking || isSpinCharging)
        return;

if(bounceTimer > 0)
        return;

// PASIVA SPIN: si Sonic esta en bola (saltando en giro o rodando), el
// ataque de salto/rodadura del EXE NO le hace dano: ambos se repelen
// (misma mecanica de Tails/Knux). Sin bola, el contacto le hace 20.
var list = ds_list_create();
instance_place_list(x, y, obj_player_puppet, list, false);

for(var i = 0; i < ds_list_size(list); i++)
{
        var inst = list[| i];
        if(inst.isDemonized && inst.visible && (inst.state == JUMP || inst.state == SPIN))
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
                
                // exeSource=true: daño de un ataque del lado EXE (parry puede negarlo)
                scr_player_hurt(dmg, dirX, dirY, (isJumping || isSpinning) ? snd_buble : snd_hurt, spr_blood2, true, true);
                
                if(hp <= 0 && inst.revivalTimes >= 2)
                {               
                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS, true);
                        buffer_write(pak, buffer_u16, inst.master_id);
                        buffer_write(pak, buffer_u8, 4);
                        send_server_tcp(pak);
                }
                
                if(dmg > 0)
                {
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
                
                if(dmg <= 0 && bounceTimer <= -1)
                        bounceTimer = 6;
        }
}

ds_list_destroy(list);
