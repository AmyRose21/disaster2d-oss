// Default player values (Vanilla: misma base que Cream).
// Las macros CREAM_* / ECREAM_* viven en obj_cream/Create_0.gml y
// NO se redeclaran aqui (mismo patron que obj_sally_canon con las
// macros de Sally). Habilidades: specialFunc inline (v1.2, abajo) -
// vuelo tipo Tails, anillos x3 y dash de Cream.
//
// V1.2 - macros propias de Vanilla (tunea aqui):
#macro VANILLA_FLY_SOLO (60 * 5)       // vuelo SOLO: 5 segundos (Cream planea 2 s)
#macro VANILLA_FLY_CARRY (60 * 7.5)    // vuelo con PASAJERO colgado (mod carry): 7.5 s
#macro VANILLA_FLY_RISE -3.5           // velocidad de subida MANTENIENDO la tecla A
#macro VANILLA_FLY_GLIDE 1             // al soltar A: planeo lento (como Cream)
#macro VANILLA_FLY_RECHARGE (60 * 15)  // recarga del vuelo (igual que Cream)
#macro VANILLA_DASH_RECHARGE (60 * 30) // recarga del dash (igual que Cream)
#macro VANILLA_RINGS_RECHARGE (60 * 15)  // recarga de anillos: 15 s (Cream: 40 s)
#macro EVANILLA_RINGS_RECHARGE (60 * 10) // idem escapada/demonizada (Cream: 30 s)

// V2 — paciencia, moribunda, chocola y float run: la logica y TODAS las
// macros de la v2 viven en scripts/scr_chocola/scr_chocola.gml
// (VANILLA_PACIENCIA_*, VANILLA_MORIBUNDA_*, VANILLA_FLOAT_*,
// VANILLA_CHOCOLA_*, pasivas de madre...). Regla GM: una #macro es
// GLOBAL y solo puede definirse UNA vez en todo el proyecto, asi que
// aqui no se repiten (v5: eliminadas las 3 duplicadas que rompian build).
#macro VANILLA_RINGS_WORTH 4               // cada anillo invocado vale 4 (server)

//Variables
gspd = 0;
xspd = 0;
yspd = 0;
state = 0;
angle = 0;
hurttime = 0;
rings = 0;
lookTimer = 0;
effectTime = 0;
revivalTimes = 0;
deadTimer = 31;
deadColor = c_white;
shockedTimer = 0;
ringsTimer = 0;
ringsSpawn = 0;
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
deadTimer = 0;
bounceTimer = 0;
shards = 0;
chunkX = -1000;
chunkY = -1000;
chunkTimer = 0;

isColliding = false;
isFlying = true;
dashing = 0;
flyTimer = 0;
flyTimeout = 0;
dashTimer = 0;

// V2: estado propio de Vanilla (ver scr_chocola.gml)
pacienciaState = 0;      // 0 normal | 1 paciencia | 2 agotada
pacienciaTimer = 0;
pacienciaWaitChocola = false; // congela el timer hasta el golpe de Chocola
pacienciaChocolaOut = false;  // ya salio Chocola en esta paciencia
pacienciaUsed = false;        // la paciencia solo 1 vez por ronda
moribundaState = 0;
moribundaTimer = 0;
chocolaCd = 0;           // enfriamiento compartido bloqueo/ataque de Chocola
chocolaProxTimer = 0;    // re-check del ataque cercano
dedemonCd = 0;           // anti-spam de la des-demonizacion
runHold = 0;             // frames corriendo a tope (rampa del float run)
floatRunCap = CREAM_MAXSPEED; // tope actual de corrida (11 -> 14)
isFloatRunning = false;  // en la pose de float run
floatGhostTimer = 0;     // cadencia de las imagenes residuales

//General
hp = 100;
isGrounded = false;
isJumping = false;
isLookingUp = false;
isLookingDown = false;
isDead = false;
isHurt = false;
isFlying = false;
isSpinning = false;
isAttacking = false;
isHiding = false;
justJumped = false;
emotion = false;
isBoosting = false;
isZipline = false;
isOnEdge = false;
edgeDir = 1;

// DIANA SPECIFIC
doubleJump = false;

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = true;
specialFunc = function() /* V1.2: habilidades propias de Vanilla (antes scr_cream_special) */
{

        // V2: paciencia/moribunda, float run, tecla V (Chocola), ataque
        // cercano de Chocola y des-demonizacion (todo en scr_chocola.gml).
        scr_vanilla_v2_step();
        
        if(pacienciaState > 0 || moribundaState > 0)
                return; // quieta mientras dura: ni vuelo, ni dash, ni anillos
        if(redRingTimer > 0)
        {
                if(flyTimer <= 2)
                        flyTimer = 2;
                
                if(dashTimer <= 2)
                        dashTimer = 2;
                        
                if(ringsTimer <= 2)
                        ringsTimer = 2;
                        
                ringsSpawn = 0;
        }
        
        if(isHiding)
        {
                if(flyTimer <= 60 * 2)
                        flyTimer = 60 * 2;
                
                if(dashTimer <= 60 * 2)
                        dashTimer = 60 * 2;
                        
                if(ringsTimer <= 60 * 2)
                        ringsTimer = 60 * 2;
                        
                ringsSpawn = 0;
        }
        
        // VUELO TIPO TAILS (v1.2): pulsar A en el aire tras un salto.
        // MIENTRAS se mantiene A SUBE (VANILLA_FLY_RISE); al soltar
        // planea lento (VANILLA_FLY_GLIDE, como Cream). Dura 5 s
        // (VANILLA_FLY_SOLO) o 7.5 s con pasajero (VANILLA_FLY_CARRY).
        if(global.playerControls && isJumping && !justJumped && keyboard_check_pressed(global.KeyA) && flyTimer <= 0)
        {
                flyTimeout = 0;
                isFlying = true;
                isJumping = false;
                isSpinning = false;
                flyTimer = VANILLA_FLY_RECHARGE;
        }
        
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && dashTimer <= 0 && abs(xspd) > 0 && ringsSpawn <= 0)
        {
                dashing = .5 * 60;
                effectTime = .5 * 60;
                dashTimer = VANILLA_DASH_RECHARGE;
                maxHSpeed = 13;
                                
                audio_play_sound(snd_creamdash, 0, false);
                net_sound_emit(snd_creamdash);
        }
        
        isColliding = place_meeting(x, y, obj_angleanuller) || collision_circle(x - 12 + (image_xscale < 0 ? 7 : 0), y-16, 32, obj_floor_parent, true, true);
        
        if(revivalTimes >= 2 && instance_exists(obj_redring) && distance_to_object(obj_redring) < 130)
                isColliding = true;
        
        // ANILLOS (v2): cada anillo invocado por Vanilla VALE 4 al
        // recogerlo (lo aplica el server, vale para quien lo recoja) y la
        // recarga es VANILLA_RINGS_RECHARGE (15 s; Cream tarda 40 s).
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && ringsTimer <= 0 && isGrounded)
        {
                if(!isColliding)
                {
                        ringsTimer = revivalTimes >= 2 ? EVANILLA_RINGS_RECHARGE : VANILLA_RINGS_RECHARGE;
                        ringsSpawn = 60;
                        image_index = 0; // v1.2: la animacion de invocar arranca en el frame 0
                }       
        }
        
        if(ringsSpawn > 1)
        {
                if(!isGrounded || !global.playerControls)
                {
                        ringsTimer = global.player.revivalTimes >= 2 ? EVANILLA_RINGS_RECHARGE : VANILLA_RINGS_RECHARGE;
                        ringsSpawn = 0;
                }
                
                gspd = 0;
                xspd = 0;
                yspd = 0;
                ringsSpawn--;
        }
        else if(ringsSpawn == 1)
        {
                if(!collision_circle(x - 12 + (image_xscale < 0 ? 7 : 0), y-16, 32, obj_floor_parent, true, true))
                {
                        audio_play_sound(snd_creamring, 0, false);
                        net_sound_emit(snd_creamring);
                        
                        // V2: si Chocola esta en casa, celebra el poder con su giro
                        // de 360 (spr_vanilla_chocola_support_power, como el Cheese
                        // de Cream: el giro lo hace la animacion del sprite)
                        var _choc = scr_chocola_get();
                        
                        if(_choc != noone && _choc.mode == CHOCOLA_FOLLOW)
                                _choc.supportTimer = 40;
                
                        var pk = cpacket_tcp(PacketType.CLIENT_CREAM_SPAWN_RINGS, false);
                        buffer_write(pk, buffer_u16, x - 12 + (image_xscale < 0 ? 7 : 0));
                        buffer_write(pk, buffer_u16, y - 16);
                        buffer_write(pk, buffer_bool, revivalTimes >= 2);
                        send_server_tcp(pk);
                }
                
                ringsSpawn = 0;
        }
        
        if(isFlying)
        {
                // v1.2: manteniendo A SUBE, soltando planea (antes era el
                // planeo fijo de Cream, yspd = 1, sin poder subir nunca).
                if(global.playerControls && keyboard_check(global.KeyA))
                        yspd = VANILLA_FLY_RISE;
                else
                        yspd = VANILLA_FLY_GLIDE;
                
                flyTimeout++;
                
                // CARRY (v1.2): con un PASAJERO colgado dura mas.
                var _flyCap = VANILLA_FLY_SOLO;
                
                if(scr_carry_find_hanger(id, CARRY_CHECK_DIST) != noone)
                        _flyCap = VANILLA_FLY_CARRY;
                
                if(flyTimeout > _flyCap)
                        isFlying = false;
                
                if(isGrounded)
                        isFlying = false;
        }
        
        if(dashing > 0)
        {
                if(isJumping)
                        isJumping = false;
                        
                acc = .8;
                dashing--;
        } 
        else 
        {
                if(isSlow)
                { 
                        maxHSpeed = (CREAM_MAXSPEED * (100-30)) / 100;
                        acc = (CREAM_ACC * (100-30)) / 100;
                }
                else
                {
                        maxHSpeed = floatRunCap; // V2: el tope sube de 11 a 14 (float run)
                        acc = CREAM_ACC;
                }
        }
        
        if(!isFlying && flyTimer > 0)
                flyTimer--;
        
        if(ringsTimer > 0)
                ringsTimer--;
        
        if(dashTimer > 0)
                dashTimer--;
};

//constants
acc = CREAM_ACC;
maxHSpeed = CREAM_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 7;
isSlow = false;

// Create sensors
instance_create_depth(x, y, 0, obj_player_sensorTL);
instance_create_depth(x, y, 0, obj_player_sensorTR);
instance_create_depth(x, y, 0, obj_player_sensorL);
instance_create_depth(x, y, 0, obj_player_sensorR);
instance_create_depth(x, y, 0, obj_player_sensorBL);
instance_create_depth(x, y, 0, obj_player_sensorBR);
instance_create_depth(x, y, 0, obj_player_sensorAL);
instance_create_depth(x, y, 0, obj_player_sensorAR);

// V2: sensores pasivos (solo SU cliente): flecha verde hacia la salida
// + flecha roja hacia el EXE real (los mismos de Amy Canon).
instance_create_depth(x, y, 0, obj_vanilla_indicators);