/// @description General movement (v2.2 TTB: Metal Amy)
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
        dashBoost = 0; // v4.6: el stun corta el impulso del dash
        scanPose = 0;  // v4.7: y tambien corta la pose de escaneo
        gspd -= min(abs(gspd), acc) * sign(gspd);
        xspd -= min(abs(xspd), acc) * sign(gspd);
        shockedTimer--;
        hurttime = global.noStunIframes ? 0 : 60 * 2;
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

                // PASIVA TAROT de Amy Canon: flotando con la tarjeta, su cuerpo cuenta
                // como bola para el rebote (el ataque de salto del EXE no le hace dano).
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

// =====================================================================
//  v4.8 — PASIVAS (corren SIEMPRE, tambien durante el stun, cuando
//  scr_move_basic — y con el scr_metalamy_special — no corre).
// =====================================================================

// timers del scan (v4.7 los llevaba el special: ahi se congelaban si
// la stuneaban a mitad de revelado)
if(scanTimer > 0)
        scanTimer--;

if(scanRecharge > 0)
        scanRecharge--;

if(scanPose > 0)
        scanPose--;

// ---- MARCA DE LA CAZADORA: el ultimo superviviente ----
// Al quedar exactamente 1 vivo (esbirros y agonizantes fuera del conteo),
// la V se apaga (huntMode) y el rastreo sale solo: ventana de 8 s
// (METALAMY_HUNT_WINDOW; la V manual dura 12 s — v4.10: "de 8 a 12 s"),
// luego 14 s de enfriamiento — que arranca cuando la ventana TERMINA — y
// vuelta a empezar. Reviven a alguien (2+ vivos) -> vuelve al scan manual.
var _alive = 0;

if(instance_exists(obj_player_puppet))
{
        with(obj_player_puppet)
        {
                // FIX v4.8.1: los desconectados (isInactive) tampoco cuentan:
                // su puppet queda congelado con la ultima hp viva y la pasiva
                // no arrancaba aunque quedara un solo jugador real.
                if(isInactive || hp <= 0 || revivalTimes >= 2)
                        continue;

                _alive++;
        }
}

if(_alive == 1)
{
        if(!huntMode)
        {
                huntMode = true;
                huntCd = 0;
                scanRecharge = 0;                      // la V queda lista para si vuelve el modo manual
                scanTimer = METALAMY_HUNT_WINDOW;      // la primera ventana sale YA (v4.10: 8 s, la V manual son 12)

                audio_play_sound(snd_egg_tracker, 0, false); // aviso local, sin emitir
        }
}
else
        huntMode = false;

if(huntMode)
{
        // ciclo: ventana -> CD de 14 s al terminar -> nueva ventana
        if(scanTimer > 0)
        {
                if(scanTimer == 1)
                        huntCd = METALAMY_HUNT_TIME;
        }
        else if(huntCd > 0)
        {
                huntCd--;

                if(huntCd == 0)
                {
                        scanTimer = METALAMY_HUNT_WINDOW; // v4.10: ventana pasiva de 8 s (la V manual son 12)

                        audio_play_sound(snd_egg_tracker, 0, false);
                }
        }
}
else
        huntCd = 0;

// ---- ADAPTABILIDAD: el anti stun-lock ----
// Si la stunean dentro de los 3 s siguientes a perder la inmunidad por
// golpe (hurttime — la rama del stun de arriba la re-arma a 2 s en cada
// frame aturdido, y los golpes normales la dejan en 3 s), gana una carga
// del dash X (hasta 3). Detecta el ARRANQUE del stun (shockedTimer 0 -> >0),
// asi cubre TODAS las fuentes sin tocarlas: trampa de Amelia, proyectil de
// Tails, bola de fuego de Blaze, electroduoble de Eggman, parry de Sonic...
// Como la rama del stun re-arma la inmunidad cada vez, la ventana solo se
// abre si la inmunidad se agoto de verdad y la volvieron a aturdir dentro
// de esos 3 s: encadenar stunes justos la va cargando.
if(shockedTimer > 0)
{
        if(!wasShocked) // el stun acaba de empezar
        {
                wasShocked = true;

                if(adaptWindow > 0)
                {
                        adaptWindow = 0;

                        if(dashCharges < METALAMY_DASH_MAX)
                        {
                                dashCharges++;

                                // aviso local: choque metalico de su kit
                                audio_play_sound(snd_metal_hiit, 0, false);
                                scr_camera_shake(10, 0.5, 0.1);
                        }
                }
        }
}
else
        wasShocked = false;

// la ventana se abre justo cuando la inmunidad por golpe se agota
// (hurttime solo lo deja el stun en los killers: no hay falsos positivos)
if(hurttime > 0)
{
        adaptAfter = true;  // inmunidad activa: ventana cerrada
        adaptWindow = 0;
}
else if(adaptAfter)
{
        adaptAfter = false;
        adaptWindow = METALAMY_ADAPT_WINDOW;
}

if(adaptWindow > 0)
        adaptWindow--;

if(won || lost)
        return;
