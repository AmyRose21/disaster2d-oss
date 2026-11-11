/// @description General movement (Jinna, plantilla obj_metalamy v2.2)

// =====================================================================
//  v3 — ADAPTACION A ATURDIMIENTOS (pasiva de lore de JINNA).
//  Todas las fuentes de stun del juego escriben shockedTimer SOBRE el
//  cliente del EXE (trampa de Amelia, parry de Sonic, electro de Metal,
//  ballesta de FW...), asi que aqui se detecta cualquier stun NUEVO con
//  un solo comparador: si shockedTimer subio por encima de lo que el
//  conteo normal dejaba esperado, acabo de entrar un stun fresco.
//  Efecto: la resistencia ACTUAL recorta su duracion y luego aprende
//  +10% (tope 50%). El primer stun de la ronda entra entero; el segundo
//  sale al 90%, el tercero al 80%... y del sexto en adelante al 50%.
// =====================================================================
if(shockedTimer > jinnaShockNext)
{
        shockedTimer = max(1, round(shockedTimer * (100 - jinnaStunResist) / 100));
        jinnaStunResist = min(50, jinnaStunResist + 10);
}
jinnaShockNext = (shockedTimer > 0) ? shockedTimer - 1 : 0;

// v3 — VANILLA ATRAPADA: espera de la animacion de absorcion; al terminar
// se fija jinnaCaughtShow (Draw_0 dibuja spr_vanilla_caught sobre su cabeza
// hasta el fin de ronda). El flag global (los aumentos del kit) lo activa
// el propio handler del paquete en TODOS los clientes.
if(jinnaCaughtDelay > 0)
{
        jinnaCaughtDelay--;
        if(jinnaCaughtDelay == 0)
                jinnaCaughtShow = true;
}

if(shockedTimer <= 0)
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
        jinnaAttackLock = 0;  // el stun corta el commit del golpe
        jinnaTeleWindup = 0;  // y cancela el telegraph del teletransporte
        jinnaTelePose = 0;    // la pose de tele tambien
        gspd -= min(abs(gspd), acc) * sign(gspd);
        xspd -= min(abs(xspd), acc) * sign(gspd);
        shockedTimer--;
        hurttime = 60 * 2;
}

if(won || lost)
{
        gspd = 0;
        xspd = 0;
        angle = 0;
}

scr_collision_basic();

if(invisTimer <= 0 && bounceTimer <= 0)
{
        var list = ds_list_create();
        instance_place_list(x, y, obj_player_puppet, list, false);

        for(var i = 0; i < ds_list_size(list); i++)
        {
                var inst = list[| i];

                if(inst.isDemonized)
                        continue;

                if(inst.isInactive)
                        continue;

                if(inst.isHurt)
                        continue;

                // PASIVA TAROT de Amy Canon: flotando con la tarjeta, su cuerpo
                // cuenta como bola para el rebote (ataque de salto del EXE = 0).
                var _amyTarot = (inst.character == CHARACTER_AMY_CANON && inst.state == AMY_CANON_TAROT);
                var jumping = (inst.state == JUMP || inst.state == SPIN) || _amyTarot;
                if(jumping && (isJumping || isSpinning))
                {
                        if(!_amyTarot && (inst.character == CHARACTER_EGGMAN || (inst.character == CHARACTER_AMY || inst.character == CHARACTER_AMY_CANON) || inst.character == CHARACTER_SALLY || inst.character == CHARACTER_SALLY_CANON))
                                continue;

                        var dirX = sign(inst.x - x);
                        var dirY = sign(inst.y - y);

                        scr_player_hurt(0, -dirX * 3, -dirY * 4, snd_buble, spr_blood2, true);

                        bounceTimer = 6;
                }

                if((isJumping || isSpinning) && (inst.hp > 0 && !inst.isHurt))
                        scr_camera_shake(30, 1, 0.15);
        }

        ds_list_destroy(list);
}

if(hurttime > 0)
        hurttime--;

// LINEA DE ARRANQUE: suena UNA vez al empezar de verdad la ronda (el
// primer frame con controles: la cuenta atras de spawn ya termino).
if(!jinnaGoSnd && global.playerControls)
{
        jinnaGoSnd = true;
        audio_play_sound(snd_jina_go, 0, false);
        net_sound_emit(snd_jina_go);
}

// =====================================================================
//  Timers de JINNA (corren SIEMPRE, tambien durante el stun — leccion
//  v4.8 de Metal Amy: si viven en el special se congelan aturdida).
// =====================================================================

// enfriamientos
if(jinnaTeleCd > 0)
        jinnaTeleCd--;

if(jinnaGrabCd > 0)
        jinnaGrabCd--;

// pose de tele (se sostiene mientras aterriza)
if(jinnaTelePose > 0)
        jinnaTelePose--;

// pose de agarre
if(jinnaGrabVisual > 0)
        jinnaGrabVisual--;

// commit del golpe (frena el impulso mientras dura el swing)
if(jinnaAttackLock > 0)
{
        jinnaAttackLock--;
        xspd = xspd * .8;
        gspd = gspd * .8;
}

if(won || lost)
        return;
