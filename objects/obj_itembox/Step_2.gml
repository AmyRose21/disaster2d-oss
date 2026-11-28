// v63 ITEM BOX v3 — GRAVEDAD PROPIA (regla de la duena: nada de cajas
// naciendo en el aire como si nada; como en los juegos clasicos la caja
// CAE desde su spawn y se CLAVA donde hay suelo). Fisica local con la
// gravedad de las entidades de la casa (yspd += 0.2 como obj_darktower_
// sisipart; el mismo obj_floor_parent de siempre como suelo).
//   grounded == true  -> apoyada en su sitio (la mayoria nace a <=32px
//                        del suelo: la caida es un peloton instantaneo)
//   grounded == false -> cayendo (vspd acumula gravedad)
// Todos los clientes ejecutan la MISMA caida deterministica, y el
// PUNTO de spawn sigue siendo del server (sx,sy del paquete).
if(grounded)
{
        // higiene del emitter (copia exacta del Step_2 del kaf_speedboobster:
        // la caja ES su propio posicional de audio).
        var gain = 1.0 - (min(distance_to_point(obj_camera.x + 240, obj_camera.y + 135), 700) / 700.0);
        audio_emitter_position(emitter, x, y-16, 0);
        audio_emitter_gain(emitter, gain);
}
else
{
        // ===== CAIDA CLASICA =====
        vspd += 0.2;
        if(vspd > 12)
                vspd = 12;

        y += vspd;

        // clavar al suelo (el mismo floor parent que camina el player).
        // place_meeting usa el bbox del sprite de la caja (30px, origin arriba):
        // el while RETROCEDE hasta que el bbox deja de tocar — la base queda
        // EXACTAMENTE sobre la superficie. (v64 metio aqui un y += 30 que
        // la VOLVIA A ENTERRAR 30px dentro del suelo -> caja invisible en
        // pantalla: eso era lo que se veia en la captura. El while es todo.)
        if(place_meeting(x, y, obj_floor_parent))
        {
                while(place_meeting(x, y, obj_floor_parent))
                        y -= 1;
                grounded = true;
                vspd = 0;
                // aterrizaje con polvita en la BASE de la caja.
                scr_effect_quick(x + 15, y + 30, spr_dust, 0.5, true);
        }
        // ===== TRAMPOLIN / ABISMO -> reporte al server =====
        // La caja cayo sobre un resorte (el trampolin la lanzaria al vacio)
        // o se salio del room / cayo al precipicio inferior sin encontrar
        // suelo: reportamos UNA vez (reported) y escondemos la instancia;
        // el server marca la entidad y la re-spawnea en OTRO punto libre
        // (CLIENT_BOX_RELOCATE — el server no tiene colision de mapa, el
        // reporte del cliente es la unica fuente, como CLIENT_FWBOLT_HIT).
        else if(!reported)
        {
                if(place_meeting(x, y, obj_spring_parent)
                || x < 0 || y < 0 || x > room_width || y > room_height)
                        report_relocate();
        }
}

// ===== v76 HAZARD RELOCATE (lava / precipicio / spikes) =====
// Regla de la duena: una caja que acabe dentro de un hazard se
// reubica SOLA en otro spawn ring. Esto NO lo cubria el v63: la lava
// NO es suelo (la caja la ATRAVIESA y quedaria clavada en el fondo del
// foso, bajo la lava) y el abismo (obj_abyss) solo teletransporta
// PLAYERS — una caja que cae por ahi sigue hasta el fondo. Ademas la
// corrida es en CUALQUIER estado, no solo cayendo: la columna de lava
// de Volcano Valley ERUPCIONA despues de spawnear la caja (su y la
// sincroniza el server en net_udpprocess) y la plataforma de lava de
// Marijua SUBE — una caja apoyada puede quedar DENTRO de un hazard
// que aparecio encima. Mismo canal de siempre (CLIENT_BOX_RELOCATE,
// one-shot por caja con `reported` aqui + flag `relocated` en el
// server): el server la retira y la re-spawnea en otro spawner libre.
//    - obj_abyss (32x32): precipicio. Caja 30px cayendo a <=12px/frame:
//      siempre hay frame de solape (62px de ventana), no se "salta".
//    - obj_vv_lavacolumn (113x200): lava de Volcano Valley, place_meeting
//      con la mascara en su y ACTUAL (identico al chequeo del player).
//    - obj_spike (32x32): spikes estaticos.
//    - obj_marijuna_lavaplatform: lava de Marijua con rectangulo manual
//      EXACTO del chequeo del player (x+48..x+113 / y+48..y+672), porque
//      su mascara no representa la zona letal.
// EXCLUIDOS A PROPOSITO (la caja alli es alcanzable = spawn valido):
// obj_ghz_water (agua nadable), obj_ycr_smokearea (roba 1 ring/s pero
// se puede entrar) y los barridos periodicos (obj_movingspike,
// obj_limpcity_echain1, obj_darktower_ball/sisi, obj_marijuna_judgerpor:
// entre pasada y pasada la caja se puede romper).
if(!reported)
{
        var _hz = (place_meeting(x, y, obj_abyss)
                || place_meeting(x, y, obj_vv_lavacolumn)
                || place_meeting(x, y, obj_spike));

        if(!_hz)
        {
                with(obj_marijuna_lavaplatform)
                {
                        if(other.bbox_right >= x + 48 && other.bbox_left <= x + 113
                        && other.bbox_bottom >= y + 48 && other.bbox_top <= y + 672)
                        {
                                _hz = true;
                                break;
                        }
                }
        }

        if(_hz)
                report_relocate();
}

// Rotura por proyectil de Tails (copia del Step_2 del Kaf: TODOS los
// clientes reportan — el server difunde y deduplica). v63: solo rompible
// apoyada (en plena caida no). v98d (duena): "si un proyectil lo
// destruye no cuenta para el que lo destruyo" — el paquete AHORA viaja
// con el nid del DUENO del laser (tercer campo, u16; melee manda 0) y el
// server le cobra el reward a EL (antes: proj=true => pid 0, no cobraba
// nadie). OJO: con 2+ Tails hay hasta 3 lasers vivos — se manda el nid
// del laser que TOCA la caja (instance_place), no el primero que haya.
if(!instance_exists(obj_tails_projectile))
        return;

if(grounded && place_meeting(x, y, obj_tails_projectile))
{
        isBroken = true;

        // la instancia EXACTA del laser que toca ESTA caja
        var _plaser = instance_place(x, y, obj_tails_projectile);

        var pack = cpacket_tcp(PacketType.CLIENT_BOX_ACTIVATE);
        buffer_write(pack, buffer_u8, nid);
        buffer_write(pack, buffer_bool, true);
        buffer_write(pack, buffer_u16, _plaser == noone ? 0 : _plaser.ownerNid); // v98d: el dueno cobra
        send_server_tcp(pack);
}
