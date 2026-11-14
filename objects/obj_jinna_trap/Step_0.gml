// vida visual: si el server ya retiro la trampa (20 s) pero el paquete
// se perdio, desvanecer sola para no quedar colgada (patron Amelia)
life--;

if(life <= 0)
{
        image_alpha -= 0.05;

        if(image_alpha <= 0)
                instance_destroy();

        return;
}

// PISADA: solo el jugador LOCAL superviviente (cada cliente es la
// autoridad del suyo). El EXE, los esbirros (revival >= 2) y los muertos
// no la activan (quien ya escapo ni llega: su player se destruye al
// salir). SIN gate de hurttime: los i-frames no protegen de caer en la
// trampa (el dano igual entra y se remueven: ver el handler de
// SERVER_JINNA_TRAP_HIT).
if(!triggerSent && !obj_netclient.gameEnds && instance_exists(global.player)
&& global.character != CHARACTER_EXE && global.player.revivalTimes < 2
&& !global.player.isDead
&& point_distance(global.player.x, global.player.y - 8, x, y - 8) <= JINNA_TRAP_RADIUS)
{
        triggerSent = true;

        var pak = cpacket_tcp(PacketType.CLIENT_JINNA_TRAP_HIT, false);
        buffer_write(pak, buffer_u16, nid);
        buffer_write(pak, buffer_u16, obj_netclient.nid);

        // v4.5 (ROUGE): flag fatal al final del reporte. Su trampa hace
        // JINNA_TRAP_DAMAGE (30) MAS las mejoras acumulativas (v18: +10 por
        // especial atrapada / +20 por Amy Canon — nunca MENOS que el base)
        // PISANDO i-frames, y con 10+ anillos el golpe se absorbe (cuesta 10
        // anillos: ver scr_player_hurt). El golpe la "mataria" (hp tras dano
        // <= 0) solo si: no le salvan los anillos Y (le queda la moribunda o
        // ya la gasto). En ese caso el server la ABSORBE (kind 4) en vez
        // del dano + TP. Un server viejo ignora el byte extra.
        // v6 (CAPTURA UNIVERSAL): el flag fatal lo manda TODO
        // superviviente — el server lo traduce a kind 4 (Rouge) o kind 5
        // (el resto: atrapado generico con sprite de relevo). El calculo
        // es el de la v4.5 ampliado: la trampa tumbia a este jugador si
        // tras el dano quedaria <= 0 SIN que le salven (a) el blindaje
        // de 10 anillos, (b) los NERVIOS DE ACERO de Sonic (su 1ra
        // caida no cuenta: se levanta solo — en plena pasiva no es
        // capturable, igual que no es matable; si ya la gasto, si) o
        // (c) la burbuja/fase 2 de Amy/Sally Canon (esas tienen regla
        // canon directa en el server: kinds 1-4 y 6, ni llegan a este
        // calculo — su byte viaja igual pero el server lo ignora).
        var _jtrapDmg = JINNA_TRAP_DAMAGE + scr_jinna_power() * JINNA_BONUS_TRAP;
        var _ringAbsorb = global.player.rings >= 10;
        var _hpAfter = _ringAbsorb ? global.player.hp : (global.player.hp - _jtrapDmg);
        var _fatal = 0;

        if(global.character == CHARACTER_ROUGE)
        {
                // en moribunda el golpe NO la tumbaria (esta salvandose ya):
                // trampa normal, sin absorcion
                if(global.player.moribundaState <= 0 && _hpAfter <= 0)
                        _fatal = 1;
        }
        else if(_hpAfter <= 0)
        {
                // el resto: solo si su pasiva de salvacion NO lo cubre
                // (NERVIOS de Sonic sin gastar y en fase 0 = se salvaria:
                // la trampa le entra como dano normal y su flujo lo levanta)
                if(!(global.character == CHARACTER_SONIC && !global.player.nerviosUsed && global.player.nerviosState == 0))
                        _fatal = 1;
        }

        buffer_write(pak, buffer_u8, _fatal);

        send_server_tcp(pak);
}
