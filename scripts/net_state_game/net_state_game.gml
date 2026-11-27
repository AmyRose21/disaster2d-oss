// v70 SUITE CAJAS — duraciones de las recompensas de las cajas de items
// (SERVER_BOX_STATE, rewards del switch(_type)). Macros al nivel del
// archivo (convención de la casa: NINGUNA de las ~745 macros del repo
// vive dentro de una función). El módulo «Cajas» del Suite TD2D las edita
// con el mismo motor de macros que Recargas (formato (60 * N) = segundos).
// Defaults = valores de la casa v62: escudo Sally 5 s, invencibilidad 3 s
// (hurttime: el MISMO timer de los i-frames del golpe estándar, pero la
// caja solo cambia ESTE valor — el golpe normal usa su propio 60 en
// scr_player_hurt), escudo eléctrico 2.5 s (Eggman 1.5 + 1 s pedido de la
// dueña), botas 8 s (Power Sneakers: tope +3 y acc x1.5, control total —
// NO la carrera forzada del Kaf).
#macro ITEMBOX_SHIELD_TIME (60 * 7.5)
#macro ITEMBOX_INVULN_TIME (60 * 7)
#macro ITEMBOX_ELECTRIC_TIME (60 * 7)
#macro ITEMBOX_BOOTS_TIME (60 * 17)
// v78 (duena): "el escudo electrico de la caja despues que explote dara
// inmunidad de dano de 2.5 seg" — al ABSORBER un golpe el escudo electrico
// revienta y su portador queda inmune al dano este tiempo (era 60f = 1 s de
// gracia). Se aplica con max() para JAMAS acortar una inmunidad ya vigente
// (caja invulnerable, i-frames de golpe, etc).
#macro ITEMBOX_ELECTRIC_BREAK_INVULN (60 * 2.5)
// v92 (duena: "que ahora podra stunear, tipo ataque jina — si se parte el
// stun le stuneara"): el STUN que el escudo electrico le mete a quien lo
// rompio pasa de 60f (1 s) a 3 s TIPO ATAQUE (ITEMBOX_ELECTRIC_STUN): el
// mismo tiempo que el golpe X del exe (el "ataque de Jinna"), con su
// empujon — antes el stun ni salia (deteccion a 64 px: ver
// scr_player_hurt) y cuando salia era tan corto que ni se notaba.
#macro ITEMBOX_ELECTRIC_STUN (60 * 3)
// v78 (duena): "aumenta la invulerabilidad del escudo de sally (caja) en 3
// seg" — el escudo de burbuja (el de Sally, el que da la caja tipo 1) al
// romperse absorbiendo un golpe dejaba 60f (1 s) de invulnerabilidad; ahora
// 60f base + 3 s = 4 s (Sally Canon conserva su macro propia de fase 2,
// SALLY_CANON_SHIELD_BREAK_INVULN). Tambien con max(): nunca acorta una
// inmunidad vigente.
#macro ITEMBOX_SHIELD_BREAK_INVULN (60 * 4)

function net_send_palette()
{
        var pak = cpacket_tcp(PacketType.CLIENT_PLAYER_PALETTE, true);
        buffer_write(pak, buffer_bool, true);
        buffer_write(pak, buffer_u16, obj_netclient.nid);
        buffer_write(pak, buffer_string, global.palleteName);
        buffer_write(pak, buffer_u8, array_length(global.palleteFrom));
        
        for(var i = 0; i < array_length(global.palleteFrom); i++)
                buffer_write(pak, buffer_u8, global.palleteFrom[i] * 255);
        
        send_server_tcp(pak);
        
        pak = cpacket_tcp(PacketType.CLIENT_PLAYER_PALETTE, true);
        buffer_write(pak, buffer_bool, false);
        buffer_write(pak, buffer_u16, obj_netclient.nid);
        buffer_write(pak, buffer_string, global.palleteName);
        buffer_write(pak, buffer_u8, array_length(global.palleteTo));
        
        for(var i = 0; i < array_length(global.palleteTo); i++)
                buffer_write(pak, buffer_u8, global.palleteTo[i] * 255);
                
        send_server_tcp(pak);
        
        if(obj_unlockables.pet != -1)
        {
                pak = cpacket_tcp(PacketType.CLIENT_PET_PALETTE, true);
                buffer_write(pak, buffer_bool, true);
                buffer_write(pak, buffer_u16, obj_netclient.nid);
                buffer_write(pak, buffer_u8, array_length(global.petPallettes[obj_unlockables.pet]));
                
                for(var i = 0; i < array_length(global.petPallettes[obj_unlockables.pet]); i++)
                        buffer_write(pak, buffer_u8, global.petPallettes[obj_unlockables.pet][i] * 255);
                
                send_server_tcp(pak);
                
                var arr = obj_unlockables.pet >= 7 ? [ 0, 0, 0, 0 ] : obj_unlockables.petPallettes[? obj_unlockables.pet].to;
                pak = cpacket_tcp(PacketType.CLIENT_PET_PALETTE, true);
                buffer_write(pak, buffer_bool, false);
                buffer_write(pak, buffer_u16, obj_netclient.nid);
                buffer_write(pak, buffer_u8, array_length(arr));
                
                for(var i = 0; i < array_length(arr); i++)
                        buffer_write(pak, buffer_u8, arr[i] * 255);
                
                send_server_tcp(pak);
        }
}

function net_state_game(rbuff, nps, isPasstrough)
{
        switch(nps)
        {
                // ============================================================
                //  v2.2 (TTB) — entidades de los personajes rescatados
                // ============================================================
                case PacketType.SERVER_AMELIA_BANANA_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _id = buffer_read_s(rbuff, buffer_u16);
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        if(_state == 0)
                        {
                                // colocar el resorte-trampa (la fisica del rebote
                                // la aplica el sistema de resortes estandar en el
                                // cliente de quien la pise)
                                var inst = instance_create_depth(_x, _y, 0, obj_amelia_banana);
                                inst.nid = _id;
                        }
                        else
                        {
                                with(obj_amelia_banana)
                                {
                                        if(nid != _id)
                                                continue;
                                        
                                        instance_destroy();
                                        break;
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_AMELIA_TRAP_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _id = buffer_read_s(rbuff, buffer_u16);
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        if(_state == 0)
                        {
                                var inst = instance_create_depth(_x, _y, 0, obj_amelia_trap);
                                inst.nid = _id;
                                inst.life = 60 * 60;
                        }
                        else if(_state == 1)
                        {
                                // retirada (60 s agotados, fin de ronda etc.)
                                with(obj_amelia_trap)
                                {
                                        if(nid != _id)
                                                continue;
                                        
                                        instance_destroy();
                                        break;
                                }
                        }
                        else if(_state == 2)
                        {
                                // PISADA: la trampa se activo. El STUN (3 s) y el slow
                                // (-40%, 3.5 s tras el stun) ya los aplico el cliente
                                // de la victima al detectar la pisada; el resto solo
                                // ve el efecto y escucha el sonido.
                                with(obj_amelia_trap)
                                {
                                        if(nid != _id)
                                                continue;

                                        instance_destroy();
                                        break;
                                }

                                audio_play_sound(snd_amelia_trap_goth, 0, false);
                                net_sound_emit(snd_amelia_trap_goth);
                                net_quick_effect(_x, _y, spr_shockparticle, true, 1, 0, 0, 1.5);
                                scr_camera_shake(20, 1, 0.2);
                        }
                        else if(_state == 3)
                        {
                                // v3.0 («GENIO MALVADO» de Eggman): la trampa esta
                                // MEJORADA (5 anillos del Dr.): +25% de stun / slow /
                                // ceguera (lo aplica el cliente de la victima al
                                // pisarla) y contorno DORADO.
                                // v3.1 (estilo RESCATE): la mejora ahora se completa
                                // con la BARRA (server) — aqui se cierra la barra, y si
                                // YO soy el Eggman que tenia el lock sobre esta trampa
                                // (patron dedemonTarget de Vanilla), pago los anillos
                                // AL COMPLETAR (soltar el ABAJO a mitad no tira nada).
                                // El DORADO, la barra y los efectos SOLO los ve el bando
                                // SUPERVIVIENTE (pedido v3.1): el exe no sabe cual
                                // trampa se mejoro.
                                with(obj_amelia_trap)
                                {
                                        if(nid != _id)
                                                continue;

                                        upgraded = true;
                                        upgShow = false;
                                        upgProg = 0;
                                        break;
                                }

                                if(global.character == CHARACTER_EGGMAN && instance_exists(global.player)
                                && global.player.geniusTarget == _id && global.player.geniusTargetType == 1)
                                {
                                        global.player.rings = max(0, global.player.rings - EGG_GENIUS_TRAP_COST);
                                        global.player.geniusTarget = -1;
                                        global.player.geniusTargetType = -1;
                                }

                                // chispas + jingle del genio SOLO para el bando
                                // superviviente (efecto local: sin broadcast, el lado
                                // del exe no se entera de nada)
                                if(instance_exists(global.player) && global.character != CHARACTER_EXE
                                && global.player.revivalTimes < 2)
                                {
                                        repeat(6)
                                                scr_effect_quick(_x + random_range(-14, 14), _y - random_range(0, 20), spr_shockparticle, 1, false, 0, 0);

                                        audio_play_sound(snd_heal, 0, false);
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_BLAZE_FIREBALL_STATE:
                {
                        if(isPasstrough)
                                break;

                        var _state = buffer_read_s(rbuff, buffer_u8);

                        if(_state == 0) // Spawn
                        {
                                // v2.9: nid por bola — pueden convivir
                                // varias a la vez (patron v2.8 trampa)
                                var _nid = buffer_read_s(rbuff, buffer_u16);
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                                var _dir = buffer_read_s(rbuff, buffer_s8);

                                var inst = instance_create_depth(_xx, _yy, 0, obj_blaze_fireball);
                                inst.nid = _nid;
                                inst.image_xscale = _dir;
                                inst.dir = _dir;
                        }
                        else if(_state == 1) // Tick
                        {
                                // v2.9b: el tick real viaja por el canal NO confiable
                                // (UDP) y se procesa en net_udpprocess (patron laser
                                // de Tails / bala de Metal Amy). Esta rama queda como
                                // salvaguarda: el server (bfire_tick) envia el estado 1
                                // con server_broadcast(..., false), asi que por aqui no
                                // deberia llegar nunca.
                                // v2.9: nid + dir + vy (gravedad del
                                // server): el cometa rota siguiendo su
                                // trayectoria de proyectil rebotante
                                var _nid = buffer_read_s(rbuff, buffer_u16);
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                                var _dir = buffer_read_s(rbuff, buffer_s8);
                                var _vy = buffer_read_s(rbuff, buffer_s8);

                                with(obj_blaze_fireball)
                                {
                                        if(nid != _nid || isBreaking)
                                                continue;

                                        vx = _dir * 10;
                                        vy = _vy;
                                        self.dir = _dir;
                                        x = _xx;
                                        y = _yy;
                                        image_xscale = 1;
                                        image_angle = point_direction(0, 0, vx, vy);
                                        break;
                                }
                        }
                        else // 2: despawn
                        {
                                var _nid = buffer_read_s(rbuff, buffer_u16);

                                with(obj_blaze_fireball)
                                {
                                        if(nid != _nid)
                                                continue;

                                        if(!isBreaking)
                                                _destroy(false);
                                        break;
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_FWBOLT_STATE:
                {
                        if(isPasstrough)
                                break;

                        var _state = buffer_read_s(rbuff, buffer_u8);
                        // v2.15 («La Torre»): TODOS los estados llevan el id de
                        // la entidad del server (hasta 3 flechas simultaneas).
                        var _fwid = buffer_read_s(rbuff, buffer_u16);

                        if(_state == 0) // Spawn: flecha de la ballesta de Fleetway Amy
                        {
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                                var _owner = buffer_read_s(rbuff, buffer_u16);
                                var _dir = buffer_read_s(rbuff, buffer_s8);
                                var _dmg = buffer_read_s(rbuff, buffer_u8);

                                var inst = instance_create_depth(_xx, _yy, 0, obj_fw_bolt);
                                inst.isOwner = (_owner == obj_netclient.nid);
                                inst.fwId = _fwid;
                                inst.dmg = _dmg;
                                inst.image_xscale = _dir;
                        }
                        else if(_state == 1) // Tick (canal UDP: posicion integrada por el server)
                        {
                                // v2.15.1 — FIX «LA FLECHA TRASPASA LA PARED»:
                                // la posicion del server ya NO se aplica: el
                                // server no conoce el mapa y sus teleports de
                                // 14 px por UDP hacian que la flecha se
                                // saltara la pared en las rafagas. El vuelo
                                // ahora lo simula cada cliente localmente
                                // (obj_fw_bolt/Step_0, barrido sub-pixel).
                                // Los campos se leen igual para no desalinear
                                // el buffer si un server viejo lo manda.
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                        }
                        else if(_state == 3) // v2.15: CLAVADA en un solido -> plataforma 5 s
                        {
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);

                                // el bolt en vuelo de este cliente deja de existir
                                // (si el evento de colision local aun no la clavo)
                                with(obj_fw_bolt)
                                {
                                        if(isBreaking || fwId != _fwid)
                                                continue;
                                        instance_destroy();
                                        break;
                                }

                                // plataforma idempotente: la crea o la reposiciona
                                // con la pos autoritativa del server
                                var _adir = 1;
                                with(obj_fw_arrow)
                                {
                                        if(fwId != _fwid)
                                                continue;
                                        _adir = image_xscale;
                                        break;
                                }
                                scr_fw_arrow_spawn(_fwid, _xx, _yy, _adir);
                        }
                        else // 2: despawn (expiro su vida / se rompio / cayo la plataforma)
                        {
                                with(obj_fw_bolt)
                                {
                                        if(fwId != _fwid)
                                                continue;
                                        _destroy();
                                        break;
                                }

                                with(obj_fw_arrow)
                                {
                                        if(fwId != _fwid)
                                                continue;
                                        arrowDrop = true;
                                        break;
                                }
                        }
                        break;
                }

                // v1 JINNA (D.I.B.): portales gemelos del teletransporte.
                // El server replica salida + llegada: cada cliente planta
                // los DOS obj_jinna_portal (puro visual, sin colision). La
                // jugadora de Jinna ya vio el suyo localmente: el pid evita
                // duplicarlo en su pantalla.
                case PacketType.SERVER_JINNA_PORTAL_STATE:
                {
                        if(isPasstrough)
                                break;

                        var _jpid = buffer_read_s(rbuff, buffer_u16);
                        var _ox = buffer_read_s(rbuff, buffer_u16);
                        var _oy = buffer_read_s(rbuff, buffer_u16);
                        var _nx = buffer_read_s(rbuff, buffer_u16);
                        var _ny = buffer_read_s(rbuff, buffer_u16);

                        // v3 — VENTANA DE PODER del teleport (3 s) para TODOS los
                        // clientes (incluida la propia Jinna): durante estos frames la
                        // hitbox del golpe basico de Jinna crece +25% (el pad lo aplica
                        // obj_player_puppet con el puppet atacante). obj_netclient/Step_0
                        // lo hace bajar; obj_level/Create lo resetea por ronda.
                        global.jinnaTelePower = JINNA_TELE_IFRAME;

                        if(_jpid != obj_netclient.nid)
                        {
                                instance_create_depth(_ox, _oy, 0, obj_jinna_portal);
                                instance_create_depth(_nx, _ny, 0, obj_jinna_portal);
                        }
                        break;
                }

                // v1 JINNA: agarre. La VICTIMA se congela (JINNA_GRAB_LOCK)
                // y sufre el dano EN SU cliente (la autoridad de su propio
                // jugador, mismo lado que el stun y que los golpes del exe);
                // la garra se ve en todos: sobre el puppet en los clientes
                // ajenos y sobre el jugador real en el de la victima (el
                // local no tiene puppet de si mismo — obj_netclient/Other_4).
                case PacketType.SERVER_JINNA_GRAB_STATE:
                {
                        if(isPasstrough)
                                break;

                        var _gpid = buffer_read_s(rbuff, buffer_u16);
                        var _gdir = buffer_read_s(rbuff, buffer_s8);

                        if(_gpid == obj_netclient.nid)
                        {
                                // VICTIMA: bloqueo + dano sobre mi jugador real
                                if(instance_exists(global.player) && !global.player.isDead)
                                {
                                        var _fx = instance_create_depth(global.player.x, global.player.y, 0, obj_jinna_grab_effect);
                                        _fx.target = global.player;
                                        _fx.image_xscale = _gdir;
                                        _fx.locked = true;
                                        _fx.timer = JINNA_GRAB_LOCK;

                                        // v4.1 — HITSPARK del impacto (la funcion
                                        // existia desde el base, estaba sin usar;
                                        // pedido de la duena): destello duro + su
                                        // sonido pesado sobre la victima
                                        hitspark(global.player.x, global.player.y - 12, 3, 3, hitspark_hard, [[hitspark_snd_heavy, 1]]);

                                        // el golpe: misma via que los golpes del exe
                                        // (exeSource=true: el parry de Sonic puede negarlo)
                                        // v18: MEJORA DIRECTA ACUMULATIVA — el dano del
                                        // agarre YA NO se reemplaza: cada especial
                                        // atrapada SUMA +5 (Amy Canon +10) sobre el
                                        // base 25. Ej.: 1 regular = 30 / Amy = 35 /
                                        // las 4 especiales = 50 (ver scr_jinna_power)
                                        var _hpB4 = global.player.hp;
                                        var _jgrabDmg = JINNA_GRAB_DAMAGE + scr_jinna_power() * JINNA_BONUS_GRAB;
                                        scr_player_hurt(_jgrabDmg, 0, 0, snd_hurt, spr_blood3, false, true);

                                        // v3 — MARCA MEJORADA de Jinna: el agarre que calo
                                        // tambien mete las habilidades de la victima en
                                        // recarga (13 s por personaje; el contacto la aplica
                                        // en obj_player_puppet)
                                        if(global.player.hp < _hpB4 || global.player.isHurt)
                                                scr_weak_mark_hit(JINNA_WEAKMARK_CD);

                                        // v7 — TOQUE NEGATIVO: el agarre que calo tambien
                                        // acumula ENERGIA NEGATIVA (el "negatimer" de
                                        // Negagen). A 100 el propio cliente pide la
                                        // conversion instantanea a súbdito negativo
                                        // (CLIENT_JINNA_NEGATOUCH). La gracia de 3 s
                                        // (jinnaNegaGrace / Antinegatemper) la respeta
                                        // scr_jinna_negatouch_hit.
                                        scr_jinna_negatouch_hit(JINNA_NEGA_CHARGE);
                                }
                        }
                        else if(instance_exists(obj_player_puppet))
                        {
                                // resto: garra visual + hitspark del impacto sobre
                                // el puppet de la victima (v4.1)
                                with(obj_player_puppet)
                                {
                                        if(master_id != _gpid)
                                                continue;

                                        var _fx2 = instance_create_depth(x, y, 0, obj_jinna_grab_effect);
                                        _fx2.target = id;
                                        _fx2.image_xscale = _gdir;

                                        hitspark(x, y - 12, 3, 3, hitspark_hard, [[hitspark_snd_heavy, 1]]);
                                        break;
                                }
                        }
                        break;
                }

                // v3 JINNA — PORTAL TRAMPA: replica de la entidad del server
                // (entities/JinnaTrap.c). 0 = spawn del portal en (x, y); 1 =
                // retirada (vida agotada / fin de ronda); 2 = PISADA: la
                // trampa se consume (los efectos sobre la victima llegan con
                // SERVER_JINNA_TRAP_HIT justo detras).
                case PacketType.SERVER_JINNA_TRAP_STATE:
                {
                        if(isPasstrough)
                                break;

                        var _tstate = buffer_read_s(rbuff, buffer_u8);
                        var _tid = buffer_read_s(rbuff, buffer_u16);
                        var _tx = buffer_read_s(rbuff, buffer_u16);
                        var _ty = buffer_read_s(rbuff, buffer_u16);

                        if(_tstate == 0)
                        {
                                var _trapInst = instance_create_depth(_tx, _ty, 0, obj_jinna_trap);
                                _trapInst.nid = _tid;
                        }
                        else
                        {
                                with(obj_jinna_trap)
                                {
                                        if(nid != _tid)
                                                continue;

                                        instance_destroy();
                                        break;
                                }

                                if(_tstate == 2)
                                {
                                        audio_play_sound(snd_teleport, 0, false);
                                        net_sound_emit(snd_teleport);
                                        net_quick_effect(_tx, _ty - 20, spr_shockparticle, true, 1, 0, 0, 1.5);
                                        scr_camera_shake(20, 1, 0.2);
                                }
                        }
                        break;
                }

                // v3/v4 JINNA — ALGUIEN CAYO EN LA TRAMPA. kind 0 = victima
                // normal: su cliente la teletransporta HASTA JINNA (jx/jy =
                // posicion de ella segun el server) y le hace el dano SIN
                // regalarle i-frames (si los tenia, se los REMUEVE). kind 1 =
                // VANILLA y kind 2 = AMY CANON (v4): absorbidas a la otra
                // dimension — su cliente corre la animacion (obj_jinna_absorb
                // con el sprite de la victima) y al terminar queda FUERA DE
                // JUEGO (muerte directa: su UI como si hubiera muerto); el
                // resto deja de verla y Jinna queda POTENCIADA
                // (v18: los flags de mejora por especial en todos: cada una
                // suma "+", Amy Canon el doble; ver scr_jinna_power). v6: kind 5 = CAPTURA
                // UNIVERSAL (el resto del reparto): misma absorcion pero SIN
                // tier de potenciacion (eso es de las canon) y con sprite de
                // RELEVO spr_(personaje)_hurt mientras llega el arte propio
                // de captura — y el atrapado queda a la espera de la
                // INVOCACION de Jinna (minion, ver SERVER_JINNA_MINION_STATE).
                case PacketType.SERVER_JINNA_TRAP_HIT:
                {
                        if(isPasstrough)
                                break;

                        var _hpid = buffer_read_s(rbuff, buffer_u16);
                        var _hkind = buffer_read_s(rbuff, buffer_u8);
                        var _hjx = buffer_read_s(rbuff, buffer_u16);
                        var _hjy = buffer_read_s(rbuff, buffer_u16);

                        // todos los clientes: v18 — las 4 ESPECIALES
                        // (Vanilla 1, Amy Canon 2, Sally Canon 3 y AHORA
                        // AMELIA 6) activan SU flag de mejora y su MUNECO
                        // se acomoda AL LADO de las que ya flotan sobre
                        // Jinna (solo las especiales se acumulan). Las
                        // mejoras ahora son "+" ACUMULATIVOS sobre el valor
                        // base (ver scr_jinna_power en scr_jinna_special):
                        // Amy Canon es la mas fuerte (doble de bono).
                        if(_hkind == 1 || _hkind == 2 || _hkind == 3 || _hkind == 6)
                        {
                                if(_hkind == 1)
                                        global.jinnaCaughtVanilla = true;
                                else if(_hkind == 2)
                                        global.jinnaCaughtAmy = true;
                                else if(_hkind == 3)
                                        global.jinnaCaughtSally = true;
                                else
                                        global.jinnaCaughtAmelia = true;

                                // la propia Jinna vera a la atrapada sobre su
                                // cabeza al terminar la animacion de absorcion
                                // de SU captura (~1,7 s). v18: la senal YA NO se
                                // reemplaza — se ACUMULA en una fila lado a
                                // lado ("se acomodara para que puedan
                                // acumularse"): pantalla de Vanilla, fantasmas
                                // canon y el muneco de Amelia
                                // (spr_amelia_doll_placed).
                                if(instance_exists(obj_jinna))
                                {
                                        var _dollSpr = (_hkind == 1) ? spr_vanilla_caught : ((_hkind == 2) ? spr_amy_capture_canon : ((_hkind == 3) ? spr_sally_capture_canon : spr_amelia_doll_placed));

                                        // dedup defensivo: si su muneco ya flota
                                        // (p.ej. la atraparon, la invocaron de
                                        // minion y la rescataron de vuelta), no
                                        // se duplica en la fila
                                        var _haveDoll = false;
                                        for(var _dd = 0; _dd < array_length(obj_jinna.jinnaCaughtDolls); _dd++)
                                        {
                                                if(obj_jinna.jinnaCaughtDolls[_dd] == _dollSpr)
                                                {
                                                        _haveDoll = true;
                                                        break;
                                                }
                                        }

                                        if(!_haveDoll)
                                        {
                                                array_push(obj_jinna.jinnaCaughtDolls, _dollSpr);
                                                array_push(obj_jinna.jinnaCaughtDollDelay, 102); // espera su absorcion (~1,7 s)
                                        }
                                }
                        }
                        else if(_hkind == 4 || _hkind == 5)
                        {
                                // v18: ROUGE (4) y la CAPTURA GENERICA (5) ya no
                                // suman mejoras ni entran a la fila de munecos
                                // ("solo a los que tengan animacion especial"):
                                // conservan su fantasma individual de siempre,
                                // visible SOLO mientras NINGUNA especial flota.
                                if(instance_exists(obj_jinna))
                                {
                                        if(_hkind == 4)
                                        {
                                                obj_jinna.jinnaCaughtDelay = 102;
                                                obj_jinna.jinnaCaughtKind = JINNA_CAUGHT_AMY; // estilo fantasma semitransparente
                                                obj_jinna.jinnaCaughtSprite = spr_rouge_traped;
                                        }
                                        else
                                        {
                                                var _capPid = _hpid;
                                                with(obj_player_puppet)
                                                {
                                                        if(master_id != _capPid)
                                                                continue;

                                                        other.jinnaCaughtDelay = 102;
                                                        other.jinnaCaughtKind = JINNA_CAUGHT_AMY; // dibujo "semi-transparente" (patron canon), sin bonus
                                                        other.jinnaCaughtSprite = scr_jinna_capture_sprite(character);
                                                        break;
                                                }
                                        }
                                }
                        }

                        if(_hpid == obj_netclient.nid)
                        {
                                if(_hkind >= 1 && _hkind <= 6)
                                {
                                        // VICTIMA ABSORBIDA (yo): Vanilla / Amy Canon /
                                        // Sally Canon / Rouge (kinds 1-4, reglas canon),
                                        // AMELIA (kind 6, v18: spr_amelia_trapped) o
                                        // CAPTURA GENERICA (kind 5, v6: el resto del
                                        // reparto). Secuencia de absorcion con el sprite
                                        // de la victima: los canon usan su sprite de
                                        // captura propio; el kind 5 el sprite de relevo
                                        // scr_jinna_capture_sprite (su _hurt por ahora).
                                        if(instance_exists(global.player) && !global.player.isDead)
                                        {
                                                var _abs = instance_create_depth(global.player.x, global.player.y, 0, obj_jinna_absorb);
                                                _abs.jinnaX = _hjx;
                                                _abs.jinnaY = _hjy;
                                                _abs.absorbVictim = (_hkind == 2) ? spr_amy_capture_canon : ((_hkind == 3) ? spr_sally_capture_canon : ((_hkind == 4) ? spr_rouge_traped : ((_hkind == 6) ? spr_amelia_trapped : ((_hkind == 5) ? scr_jinna_capture_sprite(global.character) : spr_vanilla_absorb_trap))));
                                        }
                                }
                                else if(instance_exists(global.player) && !global.player.isDead)
                                {
                                        // VICTIMA NORMAL (yo): portal de salida + dano SIN
                                        // i-frames + TP hasta Jinna.
                                        // v4: los portales del TRAER-JUGADOR se dibujan
                                        // DETRAS de los personajes (depth 5, el mismo del
                                        // agujero-trampa: antes heredaban el -50 del
                                        // obj_jinna_portal y quedaban POR DELANTE de los
                                        // jugadores — peticion de la duena)
                                        var _p1 = instance_create_depth(global.player.x, global.player.y, 0, obj_jinna_portal);
                                        _p1.depth = 5;

                                        global.player.hurttime = 0; // los que tuviera: REMOVIDOS
                                        var _hpB4t = global.player.hp;
                                        // v18: MEJORA DIRECTA ACUMULATIVA — la trampa pega
                                        // el base 30 MAS lo que sumen las especiales
                                        // atrapadas (+10 cada una / Amy Canon +20):
                                        // nunca MENOS que el base (el viejo 18/22 del
                                        // tier quedaba por debajo del 30)
                                        var _jtrapDmg = JINNA_TRAP_DAMAGE + scr_jinna_power() * JINNA_BONUS_TRAP;
                                        scr_player_hurt(_jtrapDmg, 0, 0, snd_hurt, spr_blood3, false, true);
                                        global.player.hurttime = 0; // la trampa JAMAS regala i-frames

                                        // la marca mejorada tambien entra por la trampa
                                        if(global.player.hp < _hpB4t || global.player.isHurt)
                                                scr_weak_mark_hit(JINNA_WEAKMARK_CD);

                                        // v7 — TOQUE NEGATIVO por la trampa: mismo canal
                                        // que el agarre (la energia negativa de Jinna
                                        // impregna sus portales). Solo en la victima NORMAL
                                        // (los kinds 1-5 son absorbidos: ya no estan).
                                        scr_jinna_negatouch_hit(JINNA_NEGA_CHARGE);

                                        // teleport hasta ELLA (si el dano no la mato)
                                        if(instance_exists(global.player) && !global.player.isDead)
                                        {
                                                global.player.x = _hjx;
                                                global.player.y = _hjy;
                                                global.player.xspd = 0;
                                                global.player.yspd = 0;
                                                global.player.gspd = 0;
                                                global.player.isGrounded = false;
                                                var _p2 = instance_create_depth(_hjx, _hjy, 0, obj_jinna_portal);
                                                _p2.depth = 5; // v4: detras de los jugadores
                                        }
                                }
                        }
                        else if(_hkind >= 1 && _hkind <= 6)
                        {
                                // el resto: la atrapada YA no es de este mundo — su
                                // puppet se oculta al instante (el paquete de
                                // muerte la retirara del todo en un momento)
                                with(obj_player_puppet)
                                {
                                        if(master_id != _hpid)
                                                continue;

                                        visible = false;
                                        break;
                                }
                        }
                        break;
                }

                // v6 JINNA — INVOCACION DE LOS MINIONS DEL PORTAL (↓+C). El
                // server reenvia la posicion de Jinna (jx/jy) y la lista de
                // pids invocados. El cliente de CADA minion reusa el flujo de
                // demonizacion local: revive con 100 hp y pasa a pelear para
                // el bando EXE con VIDA REAL (su hp viaja en el UDP como el
                // de cualquier jugador; los golpes de los supervivientes le
                // hacen 20 de dano — ver obj_player_puppet).
                // v9 (NEGAGEN): el invocado se materializa con el LOOK
                // NEGATIVO (isNegatouch + shd_negative, el mismo patron del
                // subdito convertido del toque negativo v8), NO con la paleta
                // demon: Jina los trae del portal "negativizados". Solo
                // cambia la piel — mecanicamente siguen siendo MINIONS plenos
                // (golpe de 20, vuelta al portal al caer). Los demas clientes
                // ven el efecto de portal en su puppet y el look negativo al
                // marcarlo aqui (la marca viaja con ESTE paquete; el
                // revivalTimes 2 llega con el UDP de siempre).
                case PacketType.SERVER_JINNA_MINION_STATE:
                {
                        if(isPasstrough)
                                break;

                        var _mjx = buffer_read_s(rbuff, buffer_u16);
                        var _mjy = buffer_read_s(rbuff, buffer_u16);
                        var _mcount = buffer_read_s(rbuff, buffer_u8);

                        var _mine = false;

                        for(var _mi = 0; _mi < _mcount; _mi++)
                        {
                                var _mpid = buffer_read_s(rbuff, buffer_u16);

                                if(_mpid == obj_netclient.nid)
                                {
                                        _mine = true;
                                        continue;
                                }

                                // los demas: efecto de portal sobre el puppet del
                                // invocado (aun invisible: reaparecera con la
                                // paleta demon al llegar su primer paquete UDP)
                                with(obj_player_puppet)
                                {
                                        if(master_id != _mpid)
                                                continue;

                                        visible = true;
                                        x = _mjx;
                                        y = _mjy;
                                        // id. = el puppet del with: sin prefijo, xspd/yspd
                                        // colisionan con los var locales del script (lineas
                                        // 2918+) y el reset no llega a la instancia (GM2043)
                                        id.xspd = 0;
                                        id.yspd = 0;
                                        isMinion = true; // v6: barra de vida real + dano recibido
                                        isNegatouch = true; // v9: look NEGATIVO (shader nega, sin paleta demon)
                                        scr_effect_quick(x, y - 20, spr_ring_teleport, 1, false, 0, 0);
                                        break;
                                }
                        }

                        if(_mine && instance_exists(global.player))
                        {
                                // YO SOY UN MINION: revivo a los pies de Jinna con el
                                // flujo de demonizacion (mismo efecto que
                                // SERVER_GAME_DEATHTIMER_END con demonize=true,
                                // copiado aqui porque ese paquete no llega: el
                                // server ya nos marco demonizados a su manera).
                                global.player.x = _mjx;
                                global.player.y = _mjy;
                                global.player.xspd = 0;
                                global.player.yspd = 0;
                                global.player.gspd = 0;
                                global.player.isDead = false;
                                global.player.hp = scr_player_maxhp(global.character); // v13: minion a vida COMPLETA del personaje (125/150)
                                global.player.rings = 0;
                                global.player.hurttime = 60 * 2; // 2 s de i-frames al materializarse
                                global.player.isHurt = false;
                                global.player.shockedTimer = 0;
                                global.player.deadTimer = 31;
                                global.player.revivalTimes = 2; // esbirro: cuenta como caido y pelea para el EXE
                                global.player.isMinion = true; // v6: MINION de Jinna — tiene VIDA REAL (los supervivientes le hacen dano)
                                global.player.isNegatouch = true; // v9: look NEGATIVO — patron del subdito convertido (v8)
                                // v13 (EL BUG DE "NO ME VEO"): la absorcion del portal (obj_jinna_absorb/
                                // Step_0: "visible = false") y la vuelta al portal al caer (MINION_DOWN, mas
                                // abajo: "global.player.visible = false") OCULTAN el cuerpo del minion EN SU
                                // PROPIA PANTALLA. Esta invocacion devolvia TODO (posicion, vida, isDead,
                                // isMinion, isNegatouch, control, camara) MENOS el visible: la invocada
                                // seguia invisible para SI MISMA mientras Jinna y el resto SI la veian (la
                                // rama de arriba restaura el visible del puppet en los DEMAS clientes, lineas
                                // 688-705). La flecha que la propia minion si veia es el obj_demon_indicator:
                                // OTRO objeto que se dibuja sobre global.player en GUI — por eso se veia "la
                                // flecha y nada mas". visible es una variable built-in de la instancia (como
                                // hp/isDead, que siempre llegaron): el dot-write sobre global.player aterriza
                                // igual. Es la unica restauracion que faltaba del ciclo
                                // atrapar -> ocultar -> INVOCAR -> volver a VERSE.
                                global.player.visible = true; // v13: el cuerpo del minion vuelve a SU pantalla

                                // v9 (NEGAGEN): SIN paleta demon — el look del
                                // invocado es la INVERSION FOTOGRAFICA del sprite
                                // original (shd_negative en el Draw de cada objeto),
                                // el mismo patron del subdito convertido del toque
                                // negativo (v8): el sprite normal viaja como siempre
                                // y cada cliente lo invierte con la marca isNegatouch.
                                // Mecanicamente sigue siendo MINION pleno (100 hp,
                                // golpe de 20, vuelta al portal al caer): SOLO cambia
                                // la piel. Se purga la carga negativa residual que
                                // trajera de golpes previos a la captura (ya es
                                // minion: la purga de scr_jinna_negatouch_purge no le
                                // aplica — el bloque isMinion de obj_player_puppet
                                // corta antes — y la barra v7 exige revivalTimes < 2).
                                if(variable_instance_exists(global.player.id, "jinnaNegaCharge"))
                                        global.player.jinnaNegaCharge = 0;

                                // el control vuelve SI estaba apagado (patron del
                                // obj_jinna_absorb: congelar quita el control UNA vez)
                                global.playerControls = true;

                                instance_create_depth(_mjx, _mjy, 0, obj_demon_indicator);
                                net_quick_effect(_mjx, _mjy + 32, spr_ring_teleport, false, 1, 0, 0, 2);
                                scr_effect_quick(_mjx, _mjy - 20, spr_ring_teleport, 1, false, 0, 0);
                                audio_play_sound(snd_demonization, 0, false);
                                net_sound_emit(snd_demonization);
                                scr_camera_shake(16, 0.7, 0.15);

                                global.cameraMode = 0;
                        }

                        // sonido de invocacion para todos
                        audio_play_sound(snd_teleport, 0, false);
                        scr_camera_shake(12, 0.4, 0.1);
                        break;
                }

                // v6 JINNA — UN MINION CAYO (0 hp). Su cliente lo reporto
                // (CLIENT_JINNA_MINION_DOWN); aqui cada maquina reacciona:
                // el propio minion vuelve AL PORTAL (fuera de juego otra
                // vez, a la espera de que Jinna lo re-invoque) y el resto
                // deja de verlo (su puppet se oculta).
                case PacketType.SERVER_JINNA_MINION_DOWN:
                {
                        if(isPasstrough)
                                break;

                        var _dpid = buffer_read_s(rbuff, buffer_u16);

                        if(_dpid == obj_netclient.nid)
                        {
                                if(!instance_exists(global.player))
                                        break;

                                // de vuelta a la otra dimension: fuera de juego,
                                // sin reportar muerte al server (el server ya nos
                                // re-mojo PLAYER_CAUGHT: seguimos "vivos" alli).
                                global.playerControls = false;
                                global.player.isMinion = false; // deja de ser minion activo
                                global.player.isNegatouch = false; // v9: de vuelta al portal: el look negativo se apaga hasta la re-invocacion
                                global.player.hp = 0;
                                global.player.isHurt = false;
                                global.player.shockedTimer = 0;
                                global.player.xspd = 0;
                                global.player.yspd = 0;
                                global.player.gspd = 0;
                                global.player.isSpinning = false;
                                global.player.isAttacking = false;
                                global.player.isJumping = false;
                                global.player.visible = false;

                                var _dportal = instance_create_depth(global.player.x, global.player.y, 0, obj_jinna_portal);
                                _dportal.depth = 5;

                                audio_play_sound(snd_teleport, 0, false);
                                scr_camera_shake(16, 0.7, 0.15);

                                global.cameraMode = 3; // camara de espectador: espera la re-invocacion
                        }
                        else
                        {
                                // el resto: su puppet desaparece devorado por un portal
                                with(obj_player_puppet)
                                {
                                        if(master_id != _dpid)
                                                continue;

                                        visible = false;
                                        isMinion = false; // v6: de vuelta al portal, ya no es minion activo
                                        isNegatouch = false; // v9: y su look negativo se apaga hasta la re-invocacion
                                        scr_effect_quick(x, y - 20, spr_ring_teleport, 1, false, 0, 0);
                                        audio_play_sound(snd_teleport, 0, false);
                                        break;
                                }
                        }
                        break;
                }

                // v7 JINNA — TOQUE NEGATIVO: el server valido la conversion
                // de un superviviente cargado de energia negativa (su
                // jinnaNegaCharge llego a 100 tras los golpes de Jinna).
                // Conversion INSTANTANEA (el modo alternativo de Negagen:
                // sin agonia, sin death-timer, sin tope de mitad del lobby):
                // el propio negativo revive donde estaba con paleta demon,
                // 60 hp y golpe de 15 (mas debil que un esbirro comun, pero
                // ilimitados); el resto ve el estallido sobre su puppet (la
                // paleta demon y el revivalTimes 2 llegan solos con el
                // siguiente UDP de estado).
                case PacketType.SERVER_JINNA_NEGATOUCH_STATE:
                {
                        if(isPasstrough)
                                break;

                        var _ngpid = buffer_read_s(rbuff, buffer_u16);

                        scr_jinna_negatouch_convert(_ngpid);
                        break;
                }

                // v3/v4 JINNA — RAFAGA DEL TELETRANSPORTE: el server detecto a
                // este cliente (pid) dentro del radio de la llegada de Jinna:
                // ralentizacion sobre el jugador LOCAL (la autoridad de cada
                // victima es su propio cliente, patron de la trampa de Amelia).
                // 3 s normales / 3,75 con Amy atrapada / 4,5 con Vanilla (v4).
                case PacketType.SERVER_JINNA_TELE_AOE:
                {
                        if(isPasstrough)
                                break;

                        var _spid = buffer_read_s(rbuff, buffer_u16);

                        if(_spid == obj_netclient.nid && instance_exists(global.player) && !global.player.isDead)
                                scr_player_slow(JINNA_TELE_SLOW_TIME + scr_jinna_power() * JINNA_BONUS_SLOW);

                        break;
                }

                case PacketType.SERVER_METALAMY_BULLET_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state == 0) // Spawn
                        {
                                if(instance_exists(obj_metal_amy_bullet))
                                        break;
                                
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                                var _dir = buffer_read_s(rbuff, buffer_s8);
                                
                                var inst = instance_create_depth(_xx, _yy, 0, obj_metal_amy_bullet);
                                inst.image_xscale = _dir;
                                inst.dir = _dir;
                        }
                        else if(_state == 1) // Tick
                        {
                                // v2.2b: el tick real viaja por el canal NO confiable
                                // (UDP) y se procesa en net_udpprocess (patron laser
                                // de Tails). Esta rama queda como salvaguarda: el
                                // server (mabul_tick) envia el estado 1 con
                                // server_broadcast(..., false), asi que por aqui no
                                // deberia llegar nunca.
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                                
                                with(obj_metal_amy_bullet)
                                {
                                        if(isBreaking)
                                                continue;
                                        
                                        x = _xx;
                                        y = _yy;
                                        break;
                                }
                        }
                        else // 2: despawn
                        {
                                with(obj_metal_amy_bullet)
                                {
                                        if(!isBreaking)
                                                _destroy();
                                        break;
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_FELLA:
                {
                        var pid = buffer_read_s(rbuff, buffer_u16);
                        var _x = buffer_read_s(rbuff, buffer_f32);
                        var _y = buffer_read_s(rbuff, buffer_f32);
                        
                        if(obj_netclient.nid == pid)
                        {
                                instance_create_depth(_x, _y, 0, obj_player_POVODOK);
                                break;
                        }
                        
                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(pid != master_id)
                                                continue;
                                        
                                        is_cheating = 1;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_PLAYER_ESCAPED:
                {
                        if(!instance_exists(global.player))
                                break;
                                
                        if(instance_exists(obj_deserttown_i))
                                with(obj_deserttown_i)
                                        show = false;
                
                        obj_camera.spectatingObj = noone;
                        if(global.cameraMode != 2 && global.cameraMode != 3)
                                global.cameraMode = 3;
        
                        if(room != room_fartzone && !obj_achivements.achivements[10] && global.player.hp <= 20 && global.timeMinutes == 0 && global.timeSeconds <= 5)
                        {
                                obj_achivements.mercoins += 100;
                                obj_achivements.save();
                
                                obj_achivements.achivements[10] = true;
                                obj_achivements.save();
                                obj_achivements.show();
                        }
                        
                        with(global.player)
                                instance_destroy();
                                
                        if(instance_exists(obj_redring_screen))
                        {
                                audio_stop_sound(mus_mindfuck);
                                instance_destroy(obj_redring_screen);
                        }
                        break;
                }
                
                case PacketType.SERVER_PLAYER_BACKTRACK:
                {
                        if(isPasstrough)
                                break;
                                
                        var _x = buffer_read_s(rbuff, buffer_f32);
                        var _y = buffer_read_s(rbuff, buffer_f32);
                        
                        if(!instance_exists(global.player))
                                break;
                                
                        global.player.x = _x;
                        global.player.y = _y;
                        break;
                }
                
                case PacketType.CLIENT_MERCOIN_BONUS:
                {
                        var _tid = buffer_read_s(rbuff, buffer_u16);
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_tid != obj_netclient.nid)
                                break;
                                
                        switch(_type)
                        {
                                case 0: //exe kill
                                        obj_achivements.mercoins += 2;
                                        obj_achivements.exeKills++;
                                        
                                        if(obj_achivements.exeKills >= 3 && room != room_fartzone && !obj_achivements.achivements[12])
                                        {
                                                obj_achivements.achivements[12] = true;
                                                obj_achivements.show();
                                                obj_achivements.mercoins += 25;
                                        }
                                        
                                        if(obj_achivements.exeKills >= 10 && room != room_fartzone && !obj_achivements.achivements[13])
                                        {
                                                obj_achivements.achivements[13] = true;
                                                obj_achivements.show();
                                                obj_achivements.mercoins += 50;
                                        }
                                        
                                        if(obj_achivements.exeKills >= 50 && room != room_fartzone && !obj_achivements.achivements[14])
                                        {
                                                obj_achivements.achivements[14] = true;
                                                obj_achivements.show();
                                                obj_achivements.mercoins += 250;
                                        }
                                        
                                        if(obj_achivements.exeKills >= 100 && room != room_fartzone && !obj_achivements.achivements[15])
                                        {
                                                obj_achivements.achivements[15] = true;
                                                obj_achivements.show();
                                                obj_achivements.mercoins += 500;
                                        }
                                        
                                        if(obj_achivements.rUsedClone && room != room_fartzone && !obj_achivements.achivements[37])
                                        {
                                                obj_achivements.achivements[37] = true;
                                                obj_achivements.show();
                                                obj_achivements.mercoins += 100;
                                        }
                                        
                                        if(obj_achivements.rExeInvis && room != room_fartzone && !obj_achivements.achivements[34])
                                        {
                                                obj_achivements.achivements[34] = true;
                                                obj_achivements.show();
                                                obj_achivements.mercoins += 100;
                                        }
                                        
                                        obj_achivements.save();
                                        break;
                                        
                                case 1: //exe stun
                                        
                                        if(++obj_achivements.stunnedExe >= 5 && room != room_fartzone && !obj_achivements.achivements[9])
                                        {
                                                obj_achivements.achivements[9] = true;
                                                obj_achivements.show();
                                                obj_achivements.save();
                                                
                                                obj_achivements.mercoins += 100;
                                        }
                                                                                
                                        obj_achivements.mercoins += 1;
                                        obj_achivements.save();
                                        break;
                                        
                                case 2: //tails hit
                                        var _charge = buffer_read_s(rbuff, buffer_u8);
                                        
                                        if(_charge >= 6 && _charge <= 10 && room != room_fartzone && !obj_achivements.achivements[22])
                                        {
                                                obj_achivements.achivements[22] = true;
                                                obj_achivements.mercoins += 75;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }
                                        
                                        if(_charge >= 60 && room != room_fartzone && !obj_achivements.achivements[23])
                                        {
                                                obj_achivements.achivements[23] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }
                                        
                                        if(_charge <= 10 && ++obj_achivements.stunnedExe >= 5 && room != room_fartzone && !obj_achivements.achivements[9])
                                        {
                                                obj_achivements.achivements[9] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }

                                        audio_play_sound(snd_tails_hit, 0, false);
                                        obj_achivements.mercoins++;
                                        obj_achivements.save();
                                        break;
                                        
                                case 3: //amy.exe hit
                                        if(++obj_achivements.rExeAmyHits >= 5 && room != room_fartzone && !obj_achivements.achivements[29])
                                        {
                                                obj_achivements.achivements[29] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        break;
                                        
                                case 4: //demon kill
                                        obj_achivements.rDemonKills++;
                                        if(obj_achivements.demonLast && room != room_fartzone && !obj_achivements.achivements[8])
                                        {
                                                obj_achivements.achivements[8] = true;
                                                obj_achivements.mercoins += 125;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        
                                        if(room != room_fartzone && !obj_achivements.achivements[31] && obj_achivements.rDemonKills >= 2 && global.character == CHARACTER_CREAM)
                                        {
                                                obj_achivements.achivements[31] = true;
                                                obj_achivements.mercoins += 75;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        
                                        if(room != room_fartzone && !obj_achivements.achivements[7])
                                        {
                                                obj_achivements.achivements[7] = true;
                                                obj_achivements.mercoins += 25;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        break;
                                        
                                case 5:
                                {
                                        if(++obj_achivements.rSallyShield >= 2 && room != room_fartzone && !obj_achivements.achivements[33])
                                        {
                                                obj_achivements.achivements[33] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        break;
                                }
                                
                                case 7:
                                {
                                        if(++obj_achivements.rShockwave >= 2 && room != room_fartzone && !obj_achivements.achivements[36])
                                        {
                                                obj_achivements.achivements[36] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        break;
                                }
                                
                                case 8:
                                {
                                        obj_achivements.alarm[7] = 60;
                                        if(++obj_achivements.rUpper >= 2 && room != room_fartzone && !obj_achivements.achivements[25])
                                        {
                                                obj_achivements.achivements[25] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        break;
                                }
                                
                                case 9:
                                {
                                        obj_achivements.alarm[7] = 60;
                                        if(++obj_achivements.rUpper >= 2 && room != room_fartzone && !obj_achivements.achivements[24])
                                        {
                                                obj_achivements.achivements[24] = true;
                                                obj_achivements.mercoins += 75;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        break;
                                }
                                
                                case 10:
                                {
                                        if(++obj_achivements.rChaosDash >= 2 && room != room_fartzone && !obj_achivements.achivements[35])
                                        {
                                                obj_achivements.achivements[35] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.save();
                                                obj_achivements.show();
                                                obj_achivements.save();
                                        }
                                        break;
                                }
                                
                                case 11:
                                {
                                        obj_achivements.rAmyStuns++;
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_HDDOOR_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_type == 0)
                        {
                                var _state = buffer_read_s(rbuff, buffer_bool);
                                
                                if(!instance_exists(obj_hd_door))
                                        break;
                                        
                                if(!instance_exists(obj_hd_door2))
                                        break;
                                        
                                if(!instance_exists(obj_hd_crystal))
                                        break;
                                
                                with(obj_hd_crystal)
                                        state = _state;
                                        
                                with(obj_hd_door)
                                {
                                        state = _state;
                                        audio_play_sound_on(emitter, snd_door, false, 0);
                                }
                                
                                with(obj_hd_door2)
                                {
                                        state = _state;
                                        audio_play_sound_on(emitter, snd_door, false, 0);
                                }
                        }
                        else
                        {
                                var _state = buffer_read_s(rbuff, buffer_bool);
                                        
                                if(!instance_exists(obj_hd_crystal))
                                        break;
                                
                                with(obj_hd_crystal)
                                {
                                        if(canUse)
                                                audio_play_sound_on(emitter, snd_message, false, 0);
                                                
                                        canUse = _state;
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_WDLATERN_ACTIVATE:
                {
                        var _state = buffer_read_s(rbuff, buffer_bool);
                        var _nid = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_weed))
                                break;
                                
                        if(!instance_exists(obj_weed_lantern))
                                break;
                                
                        with(obj_weed_lantern)
                        {
                                if(nid == _nid)
                                {
                                        active = _state;
                                        
                                        if(active)
                                        {
                                                audio_play_sound(snd_wdlamp, false, 0);
                                                
                                                if(global.character == CHARACTER_EXE)
                                                        break;
                                
                                                if(!instance_exists(global.player))
                                                        break;
                                
                                                if(global.player.revivalTimes >= 2 || global.player.isDead)
                                                        break;
                                                        
                                                var _inst = instance_create_depth(global.player.x, global.player.y, 0, obj_surv_lampindicator);
                                                _inst.targetX = targetX;
                                                _inst.targetY = targetY;
                                        }
                                }
                                else
                                        active = false;
                        }
                        break;
                }
                
                case PacketType.SERVER_DTASS_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_type == 0)
                        {
                                var _id = buffer_read_s(rbuff, buffer_u8);
                                var _x = buffer_read_s(rbuff, buffer_u16);
                                var _y = buffer_read_s(rbuff, buffer_u16);
                                
                                var _inst = instance_create_depth(_x, _y, 0, obj_darktower_sisi);
                                _inst.nid = _id;
                                _inst.visible = true;
                        }
                        else if(_type == 1)
                        {
                                var _id = buffer_read_s(rbuff, buffer_u8);
                                
                                if(!instance_exists(obj_darktower_sisi))
                                        break;
                                        
                                with(obj_darktower_sisi)
                                {
                                        if(nid != _id)
                                                continue;
                                                
                                        _destroy();
                                        break;
                                }
                        }
                        else
                        {
                                var _id = buffer_read_s(rbuff, buffer_u8);
                                
                                if(!instance_exists(obj_darktower_sisi))
                                        break;
                                        
                                with(obj_darktower_sisi)
                                {
                                        if(nid != _id)
                                                continue;
                                                
                                        audio_play_sound_on(emitter, snd_sisi_notice, false, 0);
                                        break;
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_DTTAILSDOLL_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_type == 0)
                        {
                                var _x = buffer_read_s(rbuff, buffer_u16);
                                var _y = buffer_read_s(rbuff, buffer_u16);
                                var _tar = buffer_read_s(rbuff, buffer_u8);
                                
                                if(!instance_exists(obj_darktower_tailsdoll))
                                        instance_create_depth(_x, _y, 0, obj_darktower_tailsdoll);
                                        
                                obj_darktower_tailsdoll.x = _x;
                                obj_darktower_tailsdoll.y = _y;
                                obj_darktower_tailsdoll.image_index = _tar;
                        }
                        else if(_type == 1 && instance_exists(global.player))
                        {
                                if(global.player.hp <= 0)
                                        break;
                                        
                                audio_play_sound(snd_tailsball_jumpscare, false, 0);
                                net_sound_emit(snd_tailsball_jumpscare2);
                                
                                obj_darktower_jumpscare.visible = true;
                                obj_darktower_jumpscare.alarm[0] = 60;
                                scr_player_slow(3);
                        }
                        else if(_type == 2)
                        {
                                if(!instance_exists(obj_darktower_tailsdoll))
                                        break;
                                        
                                audio_play_sound(snd_tailsball, false, 0);
                        }
                        else if(_type == 3)
                        {
                                audio_play_sound(snd_tailsball_chase, 0, false);
                        }
                        
                        break;
                }
                
                case PacketType.CLIENT_PLAYER_POTATER:
                {
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        
                        if(_type == 0) //Activate & Timer
                        {
                                var timer = buffer_read_s(rbuff, buffer_u8);
                                
                                if(!instance_exists(obj_player_puppet))
                                        return;
                                        
                                with(obj_player_puppet)
                                {
                                        if(_pid != master_id)
                                                continue;
                                                
                                        potater = true;
                                        potatoTimer = timer;
                                        break;
                                }
                                
                                if(timer >= 4)
                                {                               
                                        if(obj_netclient.nid == _pid)
                                        {
                                                obj_fart_controller.potater = true;
                                                obj_fart_controller.potatoTimer = 60 * 4;
                                                break;
                                        }
                                }
                                
                        }
                        else //Deactivate
                        {
                                if(!instance_exists(obj_player_puppet))
                                        return;
                                        
                                with(obj_player_puppet)
                                {
                                        if(_pid != master_id)
                                                continue;
                                                
                                        potater = false;
                                        potatoTimer = 0;
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_EXELLERCLONE_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_type == 0)
                        {
                                var _id = buffer_read_s(rbuff, buffer_u16);
                                var _pid = buffer_read_s(rbuff, buffer_u16);
                                var _x = buffer_read_s(rbuff, buffer_u16);
                                var _y = buffer_read_s(rbuff, buffer_u16);
                                var _dir = buffer_read_s(rbuff, buffer_s8);
                                
                                var _inst = instance_create_depth(_x, _y, 0, obj_exeller_clone);
                                _inst.nid = _id;
                                _inst.pindex = 0;
                                _inst.image_xscale = _dir;
                                
                                if(ds_map_exists(obj_netclient.players, _pid))
                                        _inst.pname = obj_netclient.players[? _pid].nickname;
                                
                                if(global.character == CHARACTER_EXE)
                                {
                                        if(global.player.clones[0] != -1)
                                                _inst.pindex = 1;
                                        
                                        global.player.clones[_inst.pindex] = _id;
                                        global.player.cloneCount++;
                                        
                                        net_sound_emit(snd_exeller_clone);
                                        audio_play_sound(snd_exeller_clone, 0, false);
                                }
                                
                                net_quick_effect(_inst.x, _inst.y + 32, spr_ring_teleport, false, 1, 0, 0, 2);
                        }
                        else
                        {
                                var _id = buffer_read_s(rbuff, buffer_u16);
                                
                                if(!instance_exists(obj_exeller_clone))
                                        return;
                        
                                with(obj_exeller_clone)
                                {
                                        if(nid != _id)
                                                continue;
                                        
                                        if(global.character == CHARACTER_EXE)
                                        {
                                                global.player.x = x;
                                                global.player.y = y;
                                                global.player.clones[pindex] = -1;
                                                global.player.cloneTimer = EXELLER_CLONE_RECHARGE;
                                                global.player.cloneCount--;
                                                
                                                obj_achivements.alarm[3] = 60;
                                                obj_achivements.rUsedClone = true;
                                                
                                                obj_exetior_indicator.showTimer = 7 * 60;       
                                                
                                                net_sound_emit(snd_exe_appear);
                                                audio_play_sound(snd_exe_appear, 0, false);
                                                net_quick_effect(x, y + 32, spr_ring_teleport, false, 1, 0, 0, 2);
                                        }
                                        
                                        instance_destroy();
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.CLIENT_ERECTOR_BALLS:
                {
                        var xx = buffer_read_s(rbuff, buffer_f32);
                        var yy = buffer_read_s(rbuff, buffer_f32);
                        
                        var inst = instance_create_depth(xx-25, yy+19, -1, obj_exetior_stompballs);
                        inst.dir = -1;
                        
                        inst = instance_create_depth(xx+25, yy+19, -1, obj_exetior_stompballs);
                        inst.dir = 1;
                        
                        if(global.character == CHARACTER_EXE)
                                obj_achivements.alarm[4] = 60;
                                
                        break;
                }
                
                case PacketType.SERVER_ERECTOR_BRING_SPAWN:
                {
                        if(isPasstrough)
                                break;
                                
                        var _gid = buffer_read_s(rbuff, buffer_u16);
                        var _xx = buffer_read_s(rbuff, buffer_u16);
                        var _yy = buffer_read_s(rbuff, buffer_u16);
                        
                        var _inst = instance_create_depth(_xx, _yy, 0, obj_blackring);
                        _inst.nid = _gid;
                        
                        with(_inst)
                        {
                                tar = noone;
                                if(global.character != CHARACTER_EXE)
                                {
                                        if(!instance_exists(obj_player_puppet))
                                                return;
                                        
                                        var _tg = noone;
                                        with(obj_player_puppet)
                                        {
                                                if(character != CHARACTER_EXE)
                                                        continue;
                                                        
                                                _tg = self;
                                        }
                                        
                                        tar = _tg;
                                }
                                else
                                {
                                        if(global.palleteName == "menace")
                                                sprite_index = spr_blackring_purple;
                                }
                                
                                if(tar != noone)
                                {
                                        if(tar.palleteName == "menace")
                                                sprite_index = spr_blackring_purple;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_TCGOM_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _gid = buffer_read_s(rbuff, buffer_u8);
                        var _pus = buffer_read_s(rbuff, buffer_bool);
                                
                        if(_pus)
                        {
                                with(obj_soundemitter)
                                {
                                        if(stype == _gid)
                                                scr_audio_play_3d(emitter, snd_acid, false, 0);
                                }
                        }
                        
                        if(!instance_exists(obj_abadon_cloud))
                                break;
                                
                        with(obj_abadon_cloud)
                        {
                                if(nid != _gid)
                                        continue;
                                        
                                if(_pus)
                                {
                                        image_index = 0;
                                        visible = true;
                                }
                                
                                damage = _pus;
                        }
                                
                        break;
                }
                
                case PacketType.CLIENT_RMZSHARD_LAND:
                {
                        if(isPasstrough)
                                break;
                                
                        var _gid = buffer_read_s(rbuff, buffer_u16);
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        if(!instance_exists(obj_ravintmist_shard))
                                break;
                        
                        with(obj_ravintmist_shard)
                        {
                                if(gid != _gid)
                                        continue;
                                
                                x = _x;
                                y = _y;
                                break;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_RMZSHARD_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        switch(_type)
                        {
                                case 0:
                                {
                                        var _id = buffer_read_s(rbuff, buffer_u16);
                                        var _x = buffer_read_s(rbuff, buffer_u16);
                                        var _y = buffer_read_s(rbuff, buffer_u16);
                                        
                                        var _inst = instance_create_depth(_x, _y, 0, obj_ravintmist_shard);
                                        _inst.x = _x;
                                        _inst.y = _y;
                                        _inst.gid = _id;
                                        _inst.grv = false;
                                        _inst.ground = true;
                                        
                                        break;
                                }
                                        
                                case 1:
                                {
                                        var _id = buffer_read_s(rbuff, buffer_u16);
                                        var _x = buffer_read_s(rbuff, buffer_u16);
                                        var _y = buffer_read_s(rbuff, buffer_u16);
                                        
                                        var _inst = instance_create_depth(_x, _y, 0, obj_ravintmist_shard);
                                        _inst.x = _x;
                                        _inst.y = _y;
                                        _inst.gid = _id;
                                        _inst.grv = true;
                                        _inst.ground = false;
                                        break;
                                }
                                        
                                case 2:
                                {
                                        var _id = buffer_read_s(rbuff, buffer_u16);
                                        var _pid = buffer_read_s(rbuff, buffer_u16);
                                        
                                        if(!instance_exists(obj_ravintmist_shard))
                                                break;
                                        
                                        with(obj_ravintmist_shard)
                                        {
                                                if(gid != _id)
                                                        continue;
                                                        
                                                net_quick_effect(x, y, spr_shard_sparkle);
                                                instance_destroy();
                                                break;
                                        }
                                                
                                        if(_pid == obj_netclient.nid)
                                        {
                                                if(!instance_exists(global.player))
                                                        break;
                                                        
                                                global.player.shards++;
                                                
                                                if(global.timeMinutes < 1)
                                                        obj_achivements.rShardsCollected++;
                                                
                                                break;
                                        }
                                        
                                        if(!instance_exists(obj_player_puppet))
                                                break;
                                                
                                                
                                        with(obj_player_puppet)
                                        {
                                                if(master_id != _pid)
                                                        continue;
                                                        
                                                shards++;
                                                break;
                                        }
                                        
                                        break;
                                }
                                
                                case 3:
                                {
                                        if(!instance_exists(obj_ravinemist_controller))
                                                break;
                                                
                                        var _cnt = buffer_read_s(rbuff, buffer_u8);
                                        obj_ravinemist_controller.prevShardCount = obj_ravinemist_controller.shardCount;
                                        obj_ravinemist_controller.shardCount = _cnt;
                                        
                                        if(obj_ravinemist_controller.shardCount > obj_ravinemist_controller.prevShardCount)
                                        {
                                                audio_play_sound(snd_shard, 0, false);
                                        }
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_GHZTHUNDER_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_type == 0)
                        {
                                instance_create_depth(0, 0, 0, obj_flash);
                                audio_play_sound(snd_thunder, 0, false);
                                
                                obj_ghz_water.electro = true;
                        }
                        else if(_type == 1)
                        {
                                obj_ghz_water.electro = false;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_VVVASE_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        var _canHeal = buffer_read_s(rbuff, buffer_bool);
                        
                        if(!instance_exists(obj_vv_vase))
                                break;
                                
                        with(obj_vv_vase)
                        {
                                if(nid != _id)
                                        continue;
                                        
                                for(var i = 0; i < irandom_range(6, 8); i++)
                                {
                                        var _inst = instance_create_depth(x, y, depth, obj_vv_vasepiece);
                                        _inst.xspd = irandom_range(2, 4) * (irandom(2) >= 1 ? -1 : 1);
                                        _inst.yspd = irandom_range(-4, -2);
                                }
                                
                                sndid = scr_audio_play_3d(emitter, snd_vasebreak, false, 0);
                                visible = false;
                                break;
                        } 
                        
                        if(!instance_exists(global.player))
                                break;
                                
                        if(global.player.isDead)
                                break;
                        
                        if(obj_netclient.nid != _pid)
                                break;
                        
                        switch(_type)
                        {
                                case 0:
                                        audio_play_sound(snd_ring, 0, false);
                                        net_sound_emit(snd_ring);
                                        net_quick_effect(global.player.x, global.player.y, spr_ring_sparkle);
                                        global.player.rings++;
                                        break;
                                        
                                case 1:
                                        audio_play_sound(snd_ring, 0, false);
                                        net_sound_emit(snd_ring);
                                        net_quick_effect(global.player.x, global.player.y, spr_ring_sparkle);
                                        global.player.rings += 2;
                                        break;
                                        
                                case 2:
                                        audio_play_sound(snd_ring, 0, false);
                                        net_sound_emit(snd_ring);
                                        net_quick_effect(global.player.x, global.player.y, spr_ring_sparkle);
                                        global.player.rings += 3;
                                        break;
                                        
                                case 3:
                                        audio_play_sound(snd_ring, 0, false);
                                        net_sound_emit(snd_ring);
                                        net_quick_effect(global.player.x, global.player.y, spr_ring_sparkle);
                                        global.player.rings += 4;
                                        break;
                        }                       
                        
                        // v4.10 blindaje «gomunkulus»: el anticheat del server
                        // desconecta con rings >= 120 en cualquier mapa que no
                        // sea el 20 (practica). Desde que la practica elige mapa
                        // AL AZAR (v4.7) una partida de practica puede caer en un
                        // mapa normal, y los anillos que genera la Cream esbirro
                        // podian llevarte al tope sin querer. Techo definitivo:
                        // nunca se pasa de 119 (seguir recogiendo simplemente no
                        // suma; el gasto de la cura de 10 anillos sigue igual).
                        global.player.rings = min(global.player.rings, 119);
                                
                        if(global.player.redRingTimer >= 60)
                        {
                                var cnt = ((global.timeMinutes <= 0 && global.timeSeconds <  60) ? 2 : 0.5) * 60;
                                
                                global.player.redRingTimer = max(global.player.redRingTimer - cnt, 60);
                        }
                        
                        if(global.player.rings >= 10 && global.player.hp < scr_player_maxhp(global.character) && _canHeal) // v13: max por personaje
                        {
                                global.player.rings -= 10;
                                global.player.hp = min(scr_player_maxhp(global.character), global.player.hp + 20); // v13: max por personaje
                                audio_play_sound(snd_heal, 0, false);
                                net_sound_emit(snd_heal);
                                
                                var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(pak, buffer_u8, 0);
                                send_server_tcp(pak);
                                
                                obj_achivements.healthRestore++;
                                if(obj_achivements.healthRestore >= 3 && room != room_fartzone && !obj_achivements.achivements[16])
                                {
                                        obj_achivements.mercoins += 100;
                                        obj_achivements.save();
                                        
                                        obj_achivements.achivements[16] = true;
                                        obj_achivements.save();
                                        obj_achivements.show();
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_MOVINGSPIKE_STATE:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _frame = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_movingspike))
                                break;
                                                
                        if(!instance_exists(obj_soundemitter))
                                break;
                        
                        with(obj_soundemitter)
                        {
                                if(stype != SOUNDEMT_MOVINGSPIKE)
                                        continue;
                                
                                if(_frame == 1 || _frame == 3)
                                        scr_audio_play_3d(emitter, snd_movingspike, false, 0);
                        }
                        
                        with(obj_movingspike)   
                                image_index = _frame;
                        
                        break;
                }
                
                case PacketType.SERVER_YCRSMOKE_READY:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _nid = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_ycr_smokearea))
                                break;
                                
                        with(obj_ycr_smokearea)
                        {
                                if(nid == _nid)
                                {
                                        activated = true;
                                        break;
                                }
                        }
                                
                        break;
                }
                
                case PacketType.SERVER_YCRSMOKE_STATE:
                {                       
                        if(isPasstrough)
                                break;
                                
                        var _activated = buffer_read_s(rbuff, buffer_bool);
                        var _nid = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_ycr_smokearea))
                                break;
                        
                        if(_activated)
                        {
                                with(obj_ycr_smokearea)
                                {
                                        if(nid == _nid)
                                        {
                                                scr_audio_play_3d(emitter, snd_smoke, false, 0);
                                                for(var i = 0; i < sprite_width; i += 228)
                                                {
                                                        for(var j = 0; j < sprite_height; j += 178)
                                                        {
                                                                if(i >= sprite_width || j >= sprite_height)
                                                                        break;
                                                                        
                                                                var inst = instance_create_depth(bbox_left+i,bbox_top+j, -300, obj_ycr_smoke);
                                                                inst.area = self;
                                                        }
                                                }
                                                
                                                break;
                                        }
                                }
                        }
                        else
                        {
                                with(obj_ycr_smokearea)
                                        activated = false;
                                
                                if(!instance_exists(obj_ycr_smoke))
                                        break;
                                        
                                with(obj_ycr_smoke)
                                        mDestroy = true;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_LCCHAIN_STATE:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _active = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_limpcity_echain1))
                                break;
                                
                        with(obj_limpcity_echain1)
                                active = _active == 1;
                                
                        if(!instance_exists(obj_soundemitter))
                                break;
                        
                        with(obj_soundemitter)
                        {
                                if(stype != SOUNDEMT_LCCHAIN)
                                        continue;
                                
                                if(_active == 0)
                                        scr_audio_play_3d(emitter, snd_echain_prepare, false, 0);
                                else if(_active == 1)
                                        scr_audio_play_3d(emitter, snd_echain, false, 0);
                        }
                        break;
                }
                
                case PacketType.SERVER_LCEYE_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        if(!instance_exists(obj_limpcity_eyeA))
                                break;
                        
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _used = buffer_read_s(rbuff, buffer_bool);
                        var _useID = buffer_read_s(rbuff, buffer_u16);
                        var _target = buffer_read_s(rbuff, buffer_u8);
                        var _charge = buffer_read_s(rbuff, buffer_u8);
                                                
                        with(obj_limpcity_eyeA)
                        {
                                if(nid != _id)
                                        continue;
                                        
                                requested = false;
                                used = _used;
                                useID = _useID;
                                charge = _charge;
                                break;
                        }
                        
                        with(obj_limpcity_eyeB)
                        {
                                if(nid != _target)
                                        continue;
                                
                                used = _used;
                                        
                                if(_used && _useID == obj_netclient.nid)
                                {
                                        if(global.cameraMode == 0)
                                                global.cameraMode = 4;
                                        
                                        if(!instance_exists(obj_camera))
                                                break;
                                        
                                        obj_camera.target = self;
                                }
                                
                                if(used)
                                        sprite_index = spr_limpcity_eye;
                                else
                                        sprite_index = spr_limpcity_eye_recharge;
                                break;
                        }
                        
                        if(!_used && _useID == obj_netclient.nid && global.cameraMode == 4)
                                global.cameraMode = 0;
                        
                        break;
                }
                
                case PacketType.SERVER_NPCONTROLLER_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _warn = buffer_read_s(rbuff, buffer_bool);
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _prevState = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_warn)
                        {
                                instance_create_depth(-999, -999, -99999, obj_np_white);
                                audio_play_sound(snd_npteleport, false, 0);
                                
                                with(obj_tile)
                                {
                                        if(depth == 90)
                                        {
                                                isVis = false;
                                                image_alpha = 0;
                                        }
                                }
                                
                                if(!instance_exists(global.player))
                                        break;
                                        
                                if(global.character == CHARACTER_KNUX && global.player.isStuck)
                                {
                                        global.player.isStuck = false;
                                        global.player.isGliding = false;
                                        global.player.glideTimer = KNUX_GLIDE_RECHARGE;
                                }

                                // v4.4: Rouge se agarra a las paredes igual que
                                // Knuckles (mismo reset al cruzar la puerta)
                                if(global.character == CHARACTER_ROUGE && global.player.isStuck)
                                {
                                        global.player.isStuck = false;
                                        global.player.isGliding = false;
                                        global.player.glideTimer = ROUGE_GLIDE_RECHARGE;
                                }

                                if(_prevState == 1 || _prevState == 3)
                                {
                                        global.player.x -= 2904;
                                        
                                        with(obj_exeller_clone)
                                                x -= 2904;
                                }
                                
                                if(_prevState == 2 || _prevState == 3)
                                {
                                        global.player.y -= 1368;
                                        
                                        with(obj_exeller_clone)
                                                y -= 1368;
                                }
                                 
                                if(_state == 1 || _state == 3)
                                {
                                        global.player.x += 2904;
                                        
                                        with(obj_exeller_clone)
                                                x += 2904;
                                }
                                
                                if(_state == 2 || _state == 3)
                                {
                                        global.player.y += 1368;
                                        
                                        with(obj_exeller_clone)
                                                y += 1368;
                                }
                                
                                if(global.character == CHARACTER_CREAM || global.character == CHARACTER_VANILLA)
                                {
                                        ringsTimer = global.player.revivalTimes >= 2 ? ECREAM_RINGS_RECHARGE : CREAM_RINGS_RECHARGE;
                                        ringsSpawn = 0;
                                }
                                
                                with(obj_leftvitalkivatel)
                                        active = true;
                                        
                                with(obj_rightvitalkivatel)
                                        active = true;
                                        
                                obj_np_controller.tid = _state;
                        }
                        else
                        {
                                with(obj_tile)
                                {
                                        if(depth == 90)
                                        {
                                                isVis = true;
                                                image_alpha = 0;
                                        }
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_KAFMONITOR_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _nid = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_kaf_speedboobster))
                                break;
                        
                        var inst = instance_find(obj_kaf_speedboobster, _nid % (instance_number(obj_kaf_speedboobster)));
                        inst.nid = _nid;
                        
                        if(_state == 1)
                        {
                                inst.image_index = 0;
                                inst.isBroken = false;
                        }
                        else if(_state == 2)
                        {
                                inst.image_index = 1;
                                inst.isBroken = true;
                                
                                scr_audio_play_3d(inst.emitter, snd_break, false, 0);
                                
                                if(!instance_exists(global.player))
                                        break;
                                        
                                var _pid = buffer_read_s(rbuff, buffer_u16);
                                
                                if(obj_netclient.nid != _pid)
                                        break;
                                
                                if(global.player.isBoosting)
                                        break;
                                
                                global.player.isBoosting = true;
                                global.player.isSpinning = false;
                                global.player.isJumping = false;
                        }
                                
                        net_quick_effect(inst.x+15, inst.y+15, spr_explosion);
                        break;
                }
                
                // v62 ITEM BOX v2 (cajas de recompensa aleatorias). Clon del
                // convenio KAFMONITOR con tres extensiones: byte de TIPO,
                // posiciones explicitas (el server es la unica verdad de
                // posicion: el paquete trae sx,sy — nada de instance_find,
                // mas robusto ante ordenes de instancia distintos) y los 5
                // rewards aplicados SOLO por el cliente del pid premiado
                // (patron boost Kaf: guard !ya-activo).
                // Estados: 3=spawn / 2=rota+reward / 1=ready (re-difusion).
                case PacketType.SERVER_BOX_STATE:
                {
                        if(isPasstrough)
                                break;
                        
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _nid   = buffer_read_s(rbuff, buffer_u8);
                        var _type  = buffer_read_s(rbuff, buffer_u8);
                        var _pid   = buffer_read_s(rbuff, buffer_u16);
                        var _sx    = buffer_read_s(rbuff, buffer_u16);
                        var _sy    = buffer_read_s(rbuff, buffer_u16);
                        
                        if(_state == 3)
                        {
                                // SPAWN: crear la caja en la posicion exacta del
                                // servidor. Si ya existe una viva con este nid
                                // (re-difusion / reconexion) se REUSA: resetea
                                // tipo y posicion (roundtrip: el estado trae
                                // TODO el contexto).
                                var _inst = noone;
                                var _num = instance_number(obj_itembox);
                                for(var _i = 0; _i < _num; _i++)
                                {
                                        var _e = instance_find(obj_itembox, _i);
                                        if(_e.nid == _nid)
                                        {
                                                _inst = _e;
                                                break;
                                        }
                                }
                                
                                if(_inst == noone)
                                        _inst = instance_create_depth(_sx, _sy, 0, obj_itembox);
                                
                                _inst.nid = _nid;
                                _inst.type = _type;
                                _inst.x = _sx;
                                _inst.y = _sy;
                                _inst.isBroken = false;
                                // v63 GRAVEDAD: la caja (re)nace CAYENDO — el Step la
                                // apoya en el suelo (regla de la duena: nada de cajas
                                // en el aire). Reset completo del estado v63: reported
                                // (por si es una re-difusion tras un RELOCATE).
                                // v64 FIX DIMINUTA: escala 1.0 SIEMPRE en la viva (el
                                // 0.47 de la v63 aqui volvia diminuta a la caja recien
                                // nacida; el 0.47 es SOLO del residuo roto en state 2).
                                _inst.grounded = false;
                                _inst.vspd = 0;
                                _inst.reported = false;
                                _inst.visible = true;
                                _inst.image_xscale = 1;
                                _inst.image_yscale = 1;
                                
                                switch(_type)
                                {
                                        case 0: _inst.sprite_index = spr_ring_box; break;
                                        case 1: _inst.sprite_index = spr_shield_box; break;
                                        case 2: _inst.sprite_index = spr_invincibility_box; break;
                                        case 3: _inst.sprite_index = spr_lightning_shield_box; break;
                                        case 4: _inst.sprite_index = spr_speedboots_box; break;
                                }
                        }
                        else if(_state == 4)
                        {
                                // DESPAWN al expirar la rota: destruir la instancia
                                // boxused (sin esto quedaba colgada hasta que el azar
                                // re-sorteara este nid). Destroy_0 libera el emitter.
                                var _num = instance_number(obj_itembox);
                                for(var _i = 0; _i < _num; _i++)
                                {
                                        var _e = instance_find(obj_itembox, _i);
                                        if(_e.nid == _nid)
                                        {
                                                instance_destroy(_e);
                                                break;
                                        }
                                }
                        }
                        else if(_state == 1)
                        {
                                // READY (re-difusion): reposicion por si acaso — el
                                // respawn real crea estado 3 de nuevo. Cero cambios
                                // visuales (la caja rota sigue en boxused).
                                // v67: si NO existe instancia con este nid, la re-difusion
                                // llega a un cliente que cambio de room/volvio a entrar:
                                // ignorarla dejaria un hueco silencioso (el server cree
                                // que la caja ya vive ahi pero el cliente nunca la ve).
                                // Crearla como ROTA (boxused apoyada): es el estado real
                                // de esa entidad — hasta que su countdown expire.
                                var _num = instance_number(obj_itembox);
                                var _found = false;
                                for(var _i = 0; _i < _num; _i++)
                                {
                                        var _e = instance_find(obj_itembox, _i);
                                        if(_e.nid == _nid)
                                        {
                                                _found = true;
                                                _e.x = _sx;
                                                _e.y = _sy;
                                                break;
                                        }
                                }
                                if(!_found)
                                {
                                        var _inst = instance_create_depth(_sx, _sy, 0, obj_itembox);
                                        _inst.nid = _nid;
                                        _inst.type = _type;
                                        _inst.x = _sx;
                                        _inst.y = _sy;
                                        _inst.isBroken = true;
                                        _inst.sprite_index = spr_boxused;
                                        _inst.grounded = true;
                                        _inst.vspd = 0;
                                        _inst.image_xscale = 0.47;
                                        _inst.image_yscale = 0.47;
                                        _inst.visible = true;
                                }
                        }
                        else if(_state == 2)
                        {
                                // ROTA: todos ven la explosion y la caja usada; SOLO el
                                // cliente del pid cobra (patron boost Kaf).
                                var _num = instance_number(obj_itembox);
                                var _inst = noone;
                                for(var _i = 0; _i < _num; _i++)
                                {
                                        var _e = instance_find(obj_itembox, _i);
                                        if(_e.nid == _nid)
                                        {
                                                _inst = _e;
                                                break;
                                        }
                                }
                                
                                if(_inst == noone)
                                        break;
                                
                                _inst.isBroken = true;
                                _inst.sprite_index = spr_boxused;
                                // v63: la rota queda apoyada (ya no cae ni reporta).
                                // v64 FIX RESIDUO: spr_boxused es 64x64 con el contenido
                                // en la MITAD INFERIOR (y 32-63) — dibujado tal cual
                                // quedaba ENORME (el bug gigante de la v62); a escala 0.47
                                // el contenido visible mide ~30x15 = el hueco exacto de la
                                // caja que estuvo ahi.
                                // v66 FIX FLOTANTE: el contenido del sprite (filas 32-63)
                                // a escala 0.47 cae en la MITAD INFERIOR del area de dibujo
                                // de 30px (local y 15-30) — o sea el residuo YA apoya su
                                // base en la superficie sin ningun ajuste. El y -= 15 de
                                // la v64 estaba INVERTIDO: levantaba el residuo 15px al
                                // aire (el "aparece arriba del lugar original" de la
                                // captura). Fix: y SIN TOCAR.
                                _inst.grounded = true;
                                _inst.vspd = 0;
                                _inst.image_xscale = 0.47;
                                _inst.image_yscale = 0.47;
                                
                                scr_audio_play_3d(_inst.emitter, snd_break, false, 0);
                                net_quick_effect(_inst.x + 15, _inst.y + 15, spr_explosion);
                                
                                if(!instance_exists(global.player))
                                        break;
                                
                                if(obj_netclient.nid != _pid)
                                        break;
                                
                                // v75: el Exe JAMAS cobra rewards de caja (regla de
                                // la duena: puede romperla para negarle el buff a
                                // quien pase por ahi, pero el no cobra nada). El
                                // server ya difunde pid 0 cuando el Exe la rompe;
                                // esta guarda blinda contra un server sin
                                // recompilar (defensa en profundidad, regla 7).
                                // SOLO las cajas nuevas: los monitores Kaf de
                                // KindAndFair conservan su comportamiento original.
                                if(global.character == CHARACTER_EXE)
                                        break;
                                
                                // ===== REWARDS (aplicados al jugador local) =====
                                // Duraciones exactas de la casa: anillos +5 con
                                // techo 119 (anti-cheat server desconecta 120+);
                                // escudo = shieldTimer (el de Sally, scr_sally_special L223;
                                // v71: de verdad para TODOS — scr_player_hurt consume
                                // shieldTimer>0 con guarda, tick en scr_move_basic y burbuja
                                // en el Draw de cada uno + el puppet); invencibilidad = hurttime 3*60
                                // (los i-frames estandar del golpe, L802); escudo electrico
                                // = electricShieldTimer 60*2.5 (Eggman 60*1.5 + 1 s pedido
                                // de la duena); botas = bootsTimer 60*8 (Power Sneakers
                                // clasico: TOPE de carrera +3 y acc x1.5, control total —
                                // NO la carrera forzada del Kaf).
                                switch(_type)
                                {
                                        case 0: // anillos
                                                global.player.rings = min(global.player.rings + 5, 119);
                                                // v78 FIX (duena): "cuando llegas a los 10 rings con
                                                // la caja no cuenta como 1 cura" — los anillos de la
                                                // caja NO pasaban por la cura de 10 anillos (solo los
                                                // recogidos del mapa la aplicaban, tres copias en los
                                                // handlers SERVER_RING_COLLECTED / SERVER_RING_STATE).
                                                // Misma cura exacta que al recoger: con 10+ anillos
                                                // gastan 10 y curan +20 hp (techo por personaje),
                                                // sonido difundido, reporte al server (el mismo
                                                // CLIENT_STATS_REPORT tipo 0 que lleva la cuenta de
                                                // hp_restored) y contador de logro de las 3 curas.
                                                // _canHeal local: el server manda canHeal = rings>0
                                                // en los rings del mapa; aqui los anillos recien
                                                // sumados garantizan rings>0 — la expresion se
                                                // mantiene por fidelidad al patron de la casa.
                                                var _boxCanHeal = global.player.rings > 0;
                                                if(global.player.rings >= 10 && global.player.hp < scr_player_maxhp(global.character) && _boxCanHeal)
                                                {
                                                        global.player.rings -= 10;
                                                        global.player.hp = min(scr_player_maxhp(global.character), global.player.hp + 20);
                                                        audio_play_sound(snd_heal, 0, false);
                                                        net_sound_emit(snd_heal);
                                                        
                                                        var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                                        buffer_write(pak, buffer_u8, 0);
                                                        send_server_tcp(pak);
                                                        
                                                        obj_achivements.healthRestore++;
                                                        if(obj_achivements.healthRestore >= 3 && room != room_fartzone && !obj_achivements.achivements[16])
                                                        {
                                                                obj_achivements.mercoins += 100;
                                                                obj_achivements.save();
                                                                
                                                                obj_achivements.achivements[16] = true;
                                                                obj_achivements.save();
                                                                obj_achivements.show();
                                                        }
                                                }
                                                else
                                                        audio_play_sound(snd_ring, 0, false);
                                                break;
                                        
                                        case 1: // escudo (burbuja de Sally — TODOS los personajes)
                                                // v71 FIX CRASH ("Variable obj_amy_canon.shieldTimer
                                                // not set before reading it"): solo obj_sally/
                                                // obj_sally_canon/obj_rouge declaran shieldTimer en su
                                                // Create; el resto NO la tiene. Mismo patrón del
                                                // eléctrico (case 3) y de las botas (case 4): guarda
                                                // variable_instance_exists; el dot-write de abajo crea
                                                // la variable en la instancia (lazy var, como siempre).
                                                if(!variable_instance_exists(global.player, "shieldTimer") || global.player.shieldTimer <= 0)
                                                {
                                                        global.player.shieldTimer = ITEMBOX_SHIELD_TIME;
                                                        audio_play_sound(snd_sally_shield, 0, false);
                                                }
                                                break;
                                        
                                        case 2: // invencibilidad
                                                // v75 FIX (bug de la duena): si el jugador
                                                // ya tenia una inmunidad (de otra caja
                                                // invulnerable o de los i-frames del golpe)
                                                // la caja nueva NO refrescaba la duracion
                                                // — se gastaba en vacio. Ahora SIEMPRE
                                                // reinicia la duracion al maximo.
                                                global.player.hurttime = ITEMBOX_INVULN_TIME;
                                                audio_play_sound(snd_heal, 0, false);
                                                break;
                                        
                                        case 3: // escudo electrico (Eggman +1 s)
                                                if(!variable_instance_exists(global.player, "electricShieldTimer") || global.player.electricShieldTimer <= 0)
                                                {
                                                        global.player.electricShieldTimer = ITEMBOX_ELECTRIC_TIME;
                                                        audio_play_sound(snd_egg_shield, 0, false);
                                                }
                                                break;
                                        
                                        case 4: // botas de velocidad (Sonic clasico)
                                                if(!variable_instance_exists(global.player, "bootsTimer") || global.player.bootsTimer <= 0)
                                                {
                                                        global.player.bootsTimer = ITEMBOX_BOOTS_TIME;
                                                        
                                                        // v69 (BOTAS CON MUSICA) — RESTAURADO EN v72: loop
                                                        // snd_speedboost durante el efecto y la musica del
                                                        // nivel se calla (metodo anti-camping: duck). Este
                                                        // bloque se perdio al integrar v69 a mano: los
                                                        // end-paths de scr_move_basic/scr_player_hurt si
                                                        // entraron, la activacion no — quedaba el snd_spring
                                                        // viejo y el duck jamas se llamaba (la musica de las
                                                        // botas nunca sonaba). El audio dura 32.8 s y sobra
                                                        // para ITEMBOX_BOOTS_TIME: se apaga al expirar.
                                                        audio_play_sound(snd_speedboost, 0, true);
                                                        scr_music_duck();
                                                }
                                                break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_NAPBALL_STATE:
                {                       
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _nid = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state == 0)
                        {
                                var _dir = buffer_read_s(rbuff, buffer_s8);
                                
                                with(obj_nap_snowball_waypoint)
                                {
                                        if(nid != _nid)
                                                continue;
                                        
                                        if(wid != 0)
                                                continue;
                                        
                                        var snb = instance_create_depth(x+32, y+64, 0, obj_nap_snowball);
                                        snb.nid = _nid;
                                        snb.image_xscale = _dir;
                                        break;
                                }
                        }
                        else if(_state == 2)
                        {
                                with(obj_nap_snowball)
                                {
                                        if(nid == _nid)
                                        {
                                                var dir = (nid == 4 || nid == 1) ? 1 : -1;
                                                
                                                var ran = irandom_range(0, 2)
                                                for(var i = ran; i < ran + 2; i++)
                                                {
                                                        var part = instance_create_depth(x, y-48, 0, obj_nap_snowball_part);
                                                        part.y += random_range(-1.5, 1.5) * 24;
                                                        part.image_index = i;
                                                        
                                                        part.xspd = (7 + random_range(-2, 2)) * dir;
                                                        part.yspd = (-4 + random_range(-2, 2));
                                                }
                                                
                                                for(var i = 0; i < irandom_range(3, 6); i++)
                                                {
                                                        var part = instance_create_depth(x, y-48, 0, obj_nap_snowball_part);
                                                        part.y += random_range(-1, 1) * 24;
                                                        part.image_index = irandom_range(4, 9);
                                                        
                                                        part.xspd = (4 + random_range(-2, 2)) * dir;
                                                        part.yspd = (-4 + random_range(-2, 2));
                                                }
                                                
                                                sndid = scr_audio_play_3d(emitter, snd_snowball_break, 0, false);
                                                doDestroy = true;
                                                visible = false;
                                        }
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_NAPICE_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _nid = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state == 0)
                        {
                                with(obj_nap_iceblock)
                                {
                                        if(nid != _nid)
                                                continue;
                                                
                                        visible = false;
                                        sprite_index = spr_nap_iceblock3;
                                        
                                        scr_audio_play_3d(emitter, snd_ice_break, false, 0);
                                        
                                        for(var i = 0; i < 2; i++)
                                        {
                                                var inst = instance_create_depth(x + 20, y + i * 20, -20, obj_nap_iceblock_part);
                                                inst.xspd = 1 - i;
                                                inst.yspd = -3;
                                                inst.dir = -1;
                                        }
                                        
                                        for(var i = 0; i < 2; i++)
                                        {
                                                var inst = instance_create_depth(x + 20, y + i * 20, -20, obj_nap_iceblock_part);
                                                inst.xspd = 1 + i;
                                                inst.yspd = -3;
                                                inst.dir = 1;
                                        }
                                        
                                        break;
                                }
                        }
                        else if(_state == 1)
                        {
                                with(obj_nap_iceblock)
                                {
                                        if(nid != _nid)
                                                continue;
                                                
                                        scr_audio_play_3d(emitter, snd_ice_spawn, false, 0);
                                        sprite_index = spr_nap_iceblock2;
                                        image_index = 0;
                                        visible = true;
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.CLIENT_SPRING_USE:
                {                               
                        var _nid = buffer_read_s(rbuff, buffer_u16);
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        if(!instance_exists(global.player))
                                break;
                        
                        if(room != room_hideandseek2)
                                break;
                        
                        if(global.character != CHARACTER_EXE)
                                break;
                                
                        with(obj_exe_sprindicator)
                        {
                                spring = true;
                                sprX = _x;
                                sprY = _y;
                                
                                alarm[0] = 60 * 2;
                        }
                        
                        if(point_distance(obj_camera.x, obj_camera.y, _x, _y) >  600)
                                audio_play_sound_at(snd_spring_reverb, _x, _y, 0, 250, 500, 1, false, 0);
                                
                        break;
                }
                
                case PacketType.SERVER_PFLIFT_STATE:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _id = buffer_read_s(rbuff, buffer_u8);
                                
                        if(!instance_exists(obj_pf_lift))
                                break;
                                
                        var inst = noone;
                        with(obj_pf_lift)
                        {
                                if(nid != _id)
                                        continue;
                                
                                inst = self;
                                break;
                        }
                        
                        if(inst == noone)
                                break;
                        
                        if(_state == 0)
                        {
                                var _pid = buffer_read_s(rbuff, buffer_u16);
                                inst.activated = true;
                                inst.pid = _pid;
                                
                                if(obj_netclient.nid == _pid)
                                {
                                        if(!instance_exists(global.player))
                                                break;
                                        
                                        global.playerControls = false;
                                        global.player.x = inst.x;
                                        global.player.y = inst.y;
                                }
                        }
                        else if(_state == 2)
                        {
                                var _pid = buffer_read_s(rbuff, buffer_u16);
                                var _y = buffer_read_s(rbuff, buffer_u16);
                                
                                inst.activated = false;
                                inst.shouldFade = true;
                                inst.pid = 0;
                                inst.y = _y;
                                
                                with(obj_pf_lift)
                                        scr_audio_play_3d(emitter, snd_lift, 0, false);
                                
                                if(obj_netclient.nid == _pid)
                                {
                                        if(!instance_exists(global.player))
                                                break;
                                        
                                        if(!obj_netclient.gameEnds)
                                                global.playerControls = true;
                                        
                                        global.player.x = inst.x;
                                        global.player.y = inst.y;
                                        global.player.yspd = -3;
                                }
                        }
                        else if(_state == 3)
                        {
                                var _sY = buffer_read_s(rbuff, buffer_u16);
                                inst.activated = false;
                                inst.shouldFade = false;
                                inst.pid = 0;
                                inst.y = _sY;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_BRING_STATE:
                {                       
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _id = buffer_read_s(rbuff, buffer_u16);
                        
                        if(_state == 0)
                        {
                                var _spawn = instance_find(obj_blackring_spawner, _id-1);
                                
                                if(!instance_exists(_spawn))
                                        break;
                                
                                var _inst = instance_create_depth(_spawn.x, _spawn.y, 0, obj_blackring);
                                _inst.nid = _id;
                        }
                        else if(_state == 1)
                        {
                                if(!instance_exists(obj_blackring))
                                        break;
                                        
                                with(obj_blackring)
                                {
                                        if(nid != _id)
                                                continue;
                                                
                                        var _target = noone;
                                        var _pur = false;
                        
                                        if(global.character != CHARACTER_EXE)
                                        {
                                                if(!instance_exists(obj_player_puppet))
                                                        return;
                                
                                                var _tg = noone;
                                                with(obj_player_puppet)
                                                {
                                                        if(character != CHARACTER_EXE)
                                                                continue;
                                                
                                                        _tg = self;
                                                }
                                
                                                _target = _tg;
                                        }
                                        else
                                        {
                                                if(global.palleteName == "menace")
                                                        _pur = true;
                                        }
                        
                                        if(_target != noone)
                                        {
                                                if(_target.palleteName == "menace")
                                                        _pur = true;
                                        }
                        
                                        scr_effect_quick(x, y, _pur ? spr_blackring_sparkle_purple : spr_blackring_sparkle);
                                        instance_destroy();
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.CLIENT_RING_BROKE:
                {
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        var _xspd = buffer_read_s(rbuff, buffer_f16);
                        var _depth = (instance_exists(global.player) ? global.player.depth : obj_player_puppet.depth) - 1;
                        
                        for(var i = 0; i < 4; i++)
                        {               
                                switch(i)
                                {
                                        case 0:
                                                var _part = instance_create_depth(_x+16-4, _y+4, _depth, obj_ringpart);
                                                _part.xspd = 1 + _xspd;
                                                _part.yspd = irandom_range(-4, -2);
                                                _part.sprite_index = spr_ringpart;
                                                break;
                
                                        case 1:
                                                _part = instance_create_depth(_x, _y+16-4, _depth, obj_ringpart);
                                                _part.xspd = -1 + _xspd;
                                                _part.yspd = irandom_range(1, 2);
                                                _part.sprite_index = spr_ringpart2;
                                                break;
                
                                        case 2:
                                                _part = instance_create_depth(_x+4, _y+4, _depth, obj_ringpart);
                                                _part.xspd = -1 + _xspd;
                                                _part.yspd = irandom_range(-4, -2);
                                                _part.sprite_index = spr_ringpart3;
                                                break;
                
                                        case 3:
                                                _part = instance_create_depth(_x+16-4, _y+16-4, _depth, obj_ringpart);
                                                _part.xspd = 1 + _xspd;
                                                _part.yspd = irandom_range(1, 2);
                                                _part.sprite_index = spr_ringpart4;
                                                break;
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_BRING_COLLECTED:
                {       
                        if(isPasstrough)
                                break;
                                
                        if(!instance_exists(global.player))
                                return;
                        
                        // v17 (NEGAGEN): el NEGA recoge un ANILLO NEGRO y recupera
                        // TODA su vida, en silencio. Para el resto del bando EXE
                        // (exe y esbirros comunes) y los supervivientes el anillo
                        // negro sigue siendo el de siempre: los negas jamás caen
                        // en el código de daño de abajo (obj_blackring solo manda
                        // el paquete para el nega HERIDO, así que "no lastima a los
                        // nega" y si va con la vida llena ni lo gasta).
                        if(global.player.revivalTimes >= 2)
                        {
                                if(scr_negatouch_is(global.player)
                                && global.player.hp > 0 && global.player.hp < scr_player_maxhp(global.character)) // v13: max
                                        global.player.hp = scr_player_maxhp(global.character); // v13: cura COMPLETA = vida total
                                
                                break;
                        }
                        
                        obj_achivements.wasHurt = true;
                        if(global.player.rings >= 5)
                        {
                                global.player.rings -= 5;
                                
                                audio_play_sound(snd_ringabsorb, 0, false);
                                net_sound_emit(snd_ringabsorb);
                                return;
                        }
                                
                        if(global.player.rings < 10)
                        {
                                global.player.hp -= 20;
                                
                                var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(pak, buffer_u8, 3);
                                buffer_write(pak, buffer_u8, 20);
                                send_server_tcp(pak);
                                
                                if(global.player.hp <= 0)
                                {
                                        global.player.hp = 0;
                                        scr_player_instakill();
                                }
                        }
                        else
                        {
                                global.player.rings -= 10;
                        }
                        
                        obj_level.bloodFade = 0.4;
                        
                        net_sound_emit(snd_blackring);
                        audio_play_sound(snd_blackring, 0, false);
                        break;
                }
        
                case PacketType.CLIENT_PLAYER_HURT:
                {                               
                        var pid = buffer_read_s(rbuff, buffer_u16);
                        var xx = buffer_read_s(rbuff, buffer_u16);
                        var yy = buffer_read_s(rbuff, buffer_u16);
                        
                        if(pid == obj_netclient.nid)
                        {
                                if(!instance_exists(global.player))
                                        break;
                                
                                // v46 (LOVE de Kris): este CLIENT_PLAYER_HURT
                                // lo emite el cliente de la victima con el nid del
                                // ATACANTE en pid - pid == mi nid = mi espada calo
                                // en SU pantalla (alli la autoridad). Cuchillazo
                                // acertado: sube el nivel de violencia.
                                if(global.character == CHARACTER_KRIS)
                                        scr_kris_love_event(1);
                                
                                scr_camera_shake(20, 2, 0.2);
                        }
                        
                        break;
                }
                
                case PacketType.CLIENT_SOUND_EMIT:
                {                               
                        var pid = buffer_read_s(rbuff, buffer_u16);
                        var sid = buffer_read_s(rbuff, buffer_u8);
                        var shouldPlay = buffer_read_s(rbuff, buffer_bool);
                        
                        if(sid >= array_length(global.net_snds))
                                break;
                        
                        if(shouldPlay && pid == obj_netclient.nid)
                        {
                                // PARRY DE SONIC (v3.4): el "ting" del parry suena EN MI nid
                                // solo cuando mi ventana nego un golpe en la maquina de la
                                // victima (yo mismo o un aliado del aura: scr_parry_negate_hit
                                // / scr_parry_try_stun_attacker). En el caso del ALIADO esa es
                                // la SENAL de exito que faltaba: el contacto alli solo es
                                // exacto en el cliente de la victima y scr_parry_detect nunca
                                // lo ve en el de Sonic. scr_parry_ting_play suena (deduplica
                                // el audio a 200ms) y ademas dispara la animacion de exito.
                                if(global.net_snds[sid] == snd_parry)
                                        scr_parry_ting_play();
                                else if(global.net_snds[sid] == snd_metal_stun)
                                {
                                        // v62 ITEM BOX v2 — ESCUDO ELECTRICO de la caja:
                                        // esta senal (shouldPlay=true a MI nid) la emite la
                                        // VICTIMA cuando mi ataque acaba de golpear su
                                        // escudo electrico (scr_player_hurt). El contacto
                                        // exacto golpe-a-escudo solo existe en el cliente
                                        // de la victima; aqui me aplico el choque yo mismo
                                        // (la autoridad de siempre). Mismo patron que el
                                        // snd_exe_stun del parry de Sonic.
                                        // v92 (duena: "que ahora podra stunear, tipo
                                        // ataque jina — si se parte el stun le stuneara,
                                        // sin importar la distancia si detecta quien la
                                        // rompio"): se RETIRA el gate de "seguir atacando
                                        // al LLEGAR la senal" — con el lag de red mi
                                        // ataque ya habia terminado hace rato en MI
                                        // cliente y el stun se perdia (el "castigo gratis"
                                        // ya no aplica: la victima SI vio mi ataque
                                        // activo cuando rompio su escudo, su emisor lo
                                        // garantiza). Y el stun pasa de 60f (1 s) a 3 s
                                        // TIPO ATAQUE (ITEMBOX_ELECTRIC_STUN: mismo tiempo
                                        // que el golpe X del exe — "tipo ataque jina").
                                        if(instance_exists(global.player)
                                        && (global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
                                        && !global.player.isDead
                                        && global.player.shockedTimer <= 0)
                                        {
                                                global.player.isAttacking = false;
                                                global.player.isSpinCharging = false;
                                                global.player.spinCharge = 0;
                                                global.player.shockedTimer = ITEMBOX_ELECTRIC_STUN;
                                                global.player.xspd = -global.player.image_xscale * 3;
                                                global.player.yspd = -2;
                                                global.player.isGrounded = false;
                                                
                                                net_quick_effect(global.player.x, global.player.y, spr_shockparticle, false, 1, 0, 0, 0.75);
                                                audio_play_sound(snd_exe_stun, 0, false);
                                        }
                                }
                                else if(global.net_snds[sid] == snd_exe_stun)
                                {
                                        // PARRY DE SONIC (v3.5): snd_exe_stun posicionado EN
                                        // MI nid (shouldPlay=true) solo lo emite la NEGACION de
                                        // la victima (scr_parry_negate_hit) cuando MI golpe melee
                                        // acaba de ser parreado por un Sonic. El contacto exacto
                                        // golpe-a-cuerpo solo existe en el cliente de la victima;
                                        // cuando el golpe iba dirigido al PROPIO Sonic, el auto-stun
                                        // local (scr_parry_try_stun_attacker) no siempre se disparaba
                                        // en esta maquina (lag del puppet / mascara de solo-garras del
                                        // ataque) y el exe quedaba sin stun aunque el dano si fue
                                        // negado. Esta senal lo corrige: me aturdo a mi mismo con
                                        // las mismas reglas (scr_parry_stun_signal; deduplica con
                                        // shockedTimer contra el auto-stun local y otros stuns).
                                        // El sonido lo aplica el propio stun (no aqui): ya viajo
                                        // en este paquete para los demas clientes en 3D.
                                        scr_parry_stun_signal();
                                }
                                else if(global.net_snds[sid] == snd_snap)
                                {
                                        // CARRY (v1): un snap SENALADO a mi nid (shouldPlay=true)
                                        // solo lo emite el PORTADOR (Tails/Cream) al pulsar la V
                                        // para soltarme: suelta al que cuelga con saltito
                                        // (scr_carry_drop_signal). El snap del AGARRE (tirolina y
                                        // carry) viaja con shouldPlay=false y nunca entra aqui.
                                        scr_carry_drop_signal();
                                }
                                else if(global.net_snds[sid] == snd_nono)
                                {
                                        // VANILLA V2 (CHOCOLA): senal de stun GRANDE — la emite el
                                        // cliente de Vanilla cuando su Chocola llega al exe durante
                                        // la PACIENCIA: 5 segundos de stun (la caza grande la ven
                                        // todos los clientes porque el lanzamiento viajo como
                                        // snd_mermer broadcast).
                                        scr_chocola_stun_signal(VANILLA_CHOCOLA_PACIENCIA_STUN);
                                }
                                else if(global.net_snds[sid] == snd_vasebreak)
                                {
                                        // VANILLA V2 (CHOCOLA): senal de stun CORTO — la emite el
                                        // roll del ataque cercano (33% con el objetivo a menos de
                                        // 90 px, y no si tiene i-frames). v2.11: la mini-embestida
                                        // tambien apunta a ESBIRROS demonizados y el RECEPTOR decide
                                        // su propia duracion: 2.5 s si este cliente es el EXE,
                                        // 3.5 s si es un esbirro (la ventana del rescate de
                                        // Vanilla: scr_survivor_revive + CLIENT_VANILLA_DEDEMONIZE_PROGRESS).
                                        scr_chocola_stun_signal(global.character == CHARACTER_EXE ? VANILLA_CHOCOLA_ATTACK_STUN : VANILLA_CHOCOLA_MINION_STUN);
                                }
                                else if(global.net_snds[sid] == snd_dash)
                                {
                                        // LSA (Amy Canon v6.0): senal de GOLPE — la emite el
                                        // cliente de Amy cuando su Light Speed Attack llega
                                        // hasta ESTE jugador del bando EXE (exe o esbirro
                                        // demonizado). Mismo modelo de confianza que el parry
                                        // y Chocola: la victima se aturde a si misma
                                        // (scr_lsa_stun_signal, con dedup y sonidos propios).
                                        // OJO: el snd_dash BROADCAST (shouldPlay=false) del
                                        // arranque del rayo jamas entra por esta rama.
                                        scr_lsa_stun_signal();
                                }
                                else if(global.net_snds[sid] == snd_none)
                                {
                                        // v52 (SUPER AMY): senal del golpe del HAMMER THROW —
                                        // la emite el cliente de Amy cuando su martillo lanzado
                                        // llega hasta ESTE jugador del bando EXE (exe o esbirro
                                        // demonizado). Mismo modelo de confianza que el LSA y
                                        // Chocola: la victima se aturde a si misma con
                                        // scr_amy_super_hammer_signal (3.5 s, IGNORA i-frames).
                                        // snd_none = senal SILENTI (0 frames): nada suena aqui y
                                        // nada choca — el snd_none BROADCAST de Kris viaja con
                                        // shouldPlay=false y jamas entra por esta rama.
                                        scr_amy_super_hammer_signal();
                                }
                                else
                                        audio_play_sound(global.net_snds[sid], false, 0);
                        }
                        
                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(master_id != pid)
                                                continue;
                                                
                                        // VANILLA V2 (CHOCOLA): los eventos de Chocola viajan
                                        // como sonidos broadcast desde el cliente de Vanilla (o de
                                        // Cream, en la custodia cumplida). Cada cliente actualiza
                                        // SU simulacion local de Chocola (misma tecnica que las
                                        // senales del parry/carry). El de SUPPORT se deriva del
                                        // snd_creamring que Vanilla ya emite al invocar anillos.
                                        // v84: cada senal lleva ahora el gate del personaje del puppet EMISOR
                                        // (mermer/ready/npteleport = Vanilla; achivement = Cream; dive = Vanilla
                                        // o Cream): un sonido igual emitido por otro personaje ya no dispara
                                        // eventos de Chocola en las pantallas ajenas (el sonido en si sigue
                                        // sonando igual).
                                        if(global.net_snds[sid] == snd_mermer && character == CHARACTER_VANILLA)
                                                scr_chocola_net_event(CHOCOLA_NET_HUNT, master_id);
                                        else if(global.net_snds[sid] == snd_ready && character == CHARACTER_VANILLA)
                                                scr_chocola_net_event(CHOCOLA_NET_GO_CREAM, master_id);
                                        else if(global.net_snds[sid] == snd_npteleport && character == CHARACTER_VANILLA)
                                                scr_chocola_net_event(CHOCOLA_NET_RECALL, master_id);
                                        else if(global.net_snds[sid] == snd_achivement && character == CHARACTER_CREAM)
                                                scr_chocola_net_event(CHOCOLA_NET_DUTY_DONE, master_id);
                                        else if(global.net_snds[sid] == snd_creamring && character == CHARACTER_VANILLA)
                                                scr_chocola_net_event(CHOCOLA_NET_SUPPORT, master_id);
                                        else if(global.net_snds[sid] == snd_chocola_dive && (character == CHARACTER_VANILLA || character == CHARACTER_CREAM))
                                                scr_chocola_net_event(CHOCOLA_NET_HUNT_SMALL, master_id);
                                        // v46 (LOVE de Kris): la SENAL SILENCIOSA de subida de
                                        // LV. La emite el cliente del propio Kris con
                                        // net_sound_emit(snd_none) - 0 frames: nada suena - y
                                        // aqui espeja su LV en su puppet con el gate de
                                        // personaje (los snd_none que Exeller emite hoy por red
                                        // con choose() en su clon nunca tocan esta rama: su
                                        // puppet no es Kris). Con krisLvNet el Step_0 del
                                        // puppet escala su stun con la autoridad de siempre:
                                        // la victima se lo aplica a si misma.
                                        else if(global.net_snds[sid] == snd_none && character == CHARACTER_KRIS)
                                        {
                                                if(variable_instance_exists(id, "krisLvNet"))
                                                        krisLvNet = min(krisLvNet + 1, KRIS_LV_MAX);
                                                else
                                                        krisLvNet = 2;
                                        }
                                        // v95 (KRIS LV 20): DANO REAL AL ASESINO. La emite el
                                        // CLIENTE DEL EXE (scr_kris_exe_hp_signal) cada vez que
                                        // la espada de un Kris con LV maximo le baja
                                        // KRIS_EXE_DAMAGE de vida al pool. Este puppet es el del
                                        // EXE (emisor = pid): espejo el -35 en MI
                                        // global.exeHpPool local. SOLO KRIS lo dibuja (la barra
                                        // del asesino en obj_playerui/Draw_64); mantenerlo en
                                        // todos los clientes es gratis y lo deja listo para
                                        // cualquiera que lo quiera leer. El REFILL no viaja: se
                                        // DERIVA del mismo evento en los dos lados (TCP
                                        // ordenado: los dos espejos aplican la misma secuencia
                                        // de -35 desde KRIS_EXE_MAXHP y llegan a 0 juntos) —
                                        // al tocar 0 el pool vuelve a su tope y la pelea puede
                                        // repetirse (el knockdown del exe lo aplica SU cliente,
                                        // la autoridad).
                                        else if(global.net_snds[sid] == snd_kris_lvup && character == CHARACTER_EXE)
                                        {
                                                global.exeHpPool = max(global.exeHpPool - KRIS_EXE_DAMAGE, 0);

                                                if(global.exeHpPool <= 0)
                                                        global.exeHpPool = KRIS_EXE_MAXHP;
                                        }

                                        // v95: la senal del dano al asesino NUNCA suena — es un
                                        // DATO, no un sonido (y sonarla regalaria la posicion
                                        // del exe invisible: el emisor crudo pasa el gate de
                                        // invisibilidad a proposito, el audio no debe
                                        // deshacerlo).
                                        if(global.net_snds[sid] != snd_kris_lvup)
                                                scr_audio_play_3d(emitter, global.net_snds[sid], false, 0);
                                        break;
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_TPROJECTILE_STATE:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state == 0) // Spawn
                        {       
                                // Dont spawn again
                                if(instance_exists(obj_tails_projectile))
                                        break;
                                        
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                                var _owner = buffer_read_s(rbuff, buffer_u16);
                                var _dir = buffer_read_s(rbuff, buffer_s8);
                                var _dmg = buffer_read_s(rbuff, buffer_u8);
                                var _exe = buffer_read_s(rbuff, buffer_bool);
                                var _charge = buffer_read_s(rbuff, buffer_u8);
                                
                                var inst = instance_create_depth(_xx, _yy, 0, obj_tails_projectile);
                                inst.image_index = _charge;
                                inst.image_xscale = _dir;
                                inst.charge = _charge;
                                inst.dir = _dir;
                                inst.dmg = _dmg;
                                inst.isExe = _exe;
                                inst.isOwner = _owner == obj_netclient.nid;
                        }
                        else if(_state == 2) //Destroy
                        {
                                if(!instance_exists(obj_tails_projectile))
                                        break;
                                        
                                with(obj_tails_projectile)
                                        _destroy();
                        }
                        else if(_state == 3) // Deflect (PARRY DE SONIC): el laser pasa al lado de Sonic
                        {
                                if(!instance_exists(obj_tails_projectile))
                                        break;
                                
                                var _ddir = buffer_read_s(rbuff, buffer_s8);
                                
                                // Struct access (como el spawn original): 'dir' a secas dentro de un with
                                // colisionaria con la var local 'dir' del case del snowball de este script
                                var _laser = instance_find(obj_tails_projectile, 0);
                                if(!_laser.isBreaking)
                                {
                                        _laser.isExe = false;
                                        _laser.dir = _ddir;
                                        _laser.image_xscale = _ddir;
                                        _laser.dmg = min(_laser.dmg, SONIC_PARRY_LASER_MAXDMG); // el stun al tocar al EXE queda en max 3s
                                        _laser.image_blend = SONIC_PB_COLOR; // cian Frontiers: reconocible que ya no es dañino para nosotros
                                }
                        }
                        break;
                }
                
                case PacketType.SERVER_RING_STATE:
                {                       
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        if(_state == 0)
                        {
                                var _id = buffer_read_s(rbuff, buffer_u8);
                                var _uid = buffer_read_s(rbuff, buffer_u16);
                                var _redRing = buffer_read_s(rbuff, buffer_bool);
                                
                                var _inst = instance_find(obj_ring_spawner, _id);
                                
                                if(_inst == noone)
                                        break;
                                
                                _inst.iid = _id;
                                
                                var inst = instance_create_depth(_inst.x, _inst.y, 0, _redRing ? obj_redring : obj_ring);
                                inst.iid = _id;
                                inst.nid = _uid;
                        }
                        else if(_state == 1)
                        {
                                var _id = buffer_read_s(rbuff, buffer_u8);
                                var _uid = buffer_read_s(rbuff, buffer_u16);
                                
                                // v14 (CAZADORA): higiene del registro de anillos
                                // GENERADOS (los del _state 2) — el server lo retiro.
                                if(variable_global_exists("genRingNids"))
                                        ds_map_delete(global.genRingNids, _uid);
                                
                                with(obj_ring)
                                {
                                        if(nid != _uid)
                                                continue;
                                        
                                        if(global.character != CHARACTER_EXE)
                                                scr_effect_quick(x, y, spr_ring_sparkle).depth = depth;
        
                                        instance_destroy();
                                        break;
                                }
                        }
                        else if(_state == 2)
                        {
                                var _x = buffer_read_s(rbuff, buffer_s16);
                                var _y = buffer_read_s(rbuff, buffer_s16);
                                var _id = buffer_read_s(rbuff, buffer_u8);
                                var _uid = buffer_read_s(rbuff, buffer_u16);
                                var _redRing = buffer_read_s(rbuff, buffer_bool);
                                
                                var inst = instance_create_depth(_x, _y, 0, _redRing ? obj_redring : obj_ring);
                                inst.nid = _uid;
                                inst.iid = _id;
                                
                                // v14 (CAZADORA DE TESOROS, Rouge): estos anillos de
                                // _state 2 son los GENERADOS por Cream/Vanilla/Amy
                                // Canon (CLIENT_CREAM_SPAWN_RINGS del server). Su nid
                                // queda apuntado: la pasiva de Rouge (50% de x2 en
                                // SERVER_RING_COLLECTED) NO les aplica.
                                if(!variable_global_exists("genRingNids"))
                                        global.genRingNids = ds_map_create();
                                
                                global.genRingNids[? _uid] = true;
                        }
                        break;
                }
                
                case PacketType.SERVER_RING_COLLECTED:
                {                               
                        if(isPasstrough)
                                break;
                                
                        if(!instance_exists(global.player))
                                break;
                                
                        if(global.character == CHARACTER_EXE)
                                break;
                                
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _eid = buffer_read_s(rbuff, buffer_u16);
                        var _redRing = buffer_read_s(rbuff, buffer_bool);
                        var _canHeal = buffer_read_s(rbuff, buffer_bool);
                        var _worth = buffer_read_s(rbuff, buffer_u8); // v1.2: anillos de Vanilla valen 3 (servers viejos: -1)
                        
                        // v17 (NEGAGEN): el NEGA recoge un ANILLO ROJO para CURARSE:
                        // +JINNA_NEGA_REDHEAL (10) de vida, SIN NINGÚN sonido (ni el
                        // del anillo ni el del mindfuck: cura sigilosa) y SIN el debuff
                        // de la pantalla roja — para el nega el anillo rojo dejó de ser
                        // una trampa del exe y pasó a ser su botiquín. El anillo normal
                        // no lo recoge (obj_ring lo bloquea) y con la vida llena el
                        // anillo ni se gastó (obj_redring no lo manda).
                        if(global.player.revivalTimes >= 2)
                        {
                                if(_redRing && scr_negatouch_is(global.player)
                                && global.player.hp > 0 && global.player.hp < scr_player_maxhp(global.character)) // v13: max
                                        global.player.hp = min(scr_player_maxhp(global.character), global.player.hp + JINNA_NEGA_REDHEAL); // v13: max
                                
                                break;
                        }
                        
                        if(_redRing)
                        {
                                // v14 (CAZADORA): higiene — un anillo rojo GENERADO
                                // (_state 2) tambien sale del registro al recogerse.
                                if(variable_global_exists("genRingNids"))
                                        ds_map_delete(global.genRingNids, _eid);
                                
                                // PASIVA 1 (Amy Canon): el anillo rojo no puede silenciar sus habilidades
                                // v4.4 «Ciega» (Amelia): ciega = sin alucinaciones — lo recoge igual
                                // (el anillo desaparece y el EXE pierde esa trampa) pero sin musica,
                                // sin velo y sin silencio de habilidades. Mismo patron que Amy Canon.
                                if(global.character == CHARACTER_AMY_CANON || global.character == CHARACTER_AMELIA)
                                        break;
                                
                                if(global.player.redRingTimer > 0)
                                        break;
                                        
                                audio_play_sound(snd_redring, 0, false);
                                net_sound_emit(snd_redring);
                                
                                audio_play_sound(mus_mindfuck, 0, false);
                                instance_create_depth(0, 0, -100, obj_redring_screen);
                                global.player.redRingTimer = 60 * 10;
                        }
                        else
                        {                                               
                                // v14 — PASIVA «CAZADORA DE TESOROS» (Rouge): 50%
                                // (ROUGE_TREASURE_CHANCE) de que un anillo NORMAL cuente
                                // por 2. Los GENERADOS (Cream/Vanilla/Amy Canon: nid
                                // apuntado en genRingNids por el _state 2 de
                                // SERVER_RING_STATE) y los de worth propio (los de
                                // Vanilla valen 3 en servers nuevos) quedan FUERA.
                                // Puro conteo local: ni server ni paquetes nuevos.
                                var _gen = variable_global_exists("genRingNids") && ds_map_exists(global.genRingNids, _eid);
                                var _gain = (_worth > 0) ? _worth : 1;
                                
                                if(global.character == CHARACTER_ROUGE && !_gen && _gain == 1 && random(100) < ROUGE_TREASURE_CHANCE)
                                        _gain = 2;
                                
                                if(_gen && variable_global_exists("genRingNids"))
                                        ds_map_delete(global.genRingNids, _eid); // higiene
                                
                                //Hp regen
                                // v14: techo de la casa (119) respetado tambien con la
                                // pasiva — el anticheat del server desconecta con 120+.
                                global.player.rings = min(global.player.rings + _gain, 119);
                                if(global.player.redRingTimer >= 60)
                                {
                                        var cnt = ((global.timeMinutes <= 0 && global.timeSeconds <  60) ? 2 : 0.5) * 60;
                                        
                                        global.player.redRingTimer = max(global.player.redRingTimer - cnt, 60);
                                }
                                
                                if(global.player.rings >= 10 && global.player.hp < scr_player_maxhp(global.character) && _canHeal) // v13: max por personaje
                                {
                                        global.player.rings -= 10;
                                        global.player.hp = min(scr_player_maxhp(global.character), global.player.hp + 20); // v13: max por personaje
                                        audio_play_sound(snd_heal, 0, false);
                                        net_sound_emit(snd_heal);
                                        
                                        var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                        buffer_write(pak, buffer_u8, 0);
                                        send_server_tcp(pak);
                                        
                                        obj_achivements.healthRestore++;
                                        if(obj_achivements.healthRestore >= 3 && room != room_fartzone && !obj_achivements.achivements[16])
                                        {
                                                obj_achivements.mercoins += 100;
                                                obj_achivements.save();
                                                
                                                obj_achivements.achivements[16] = true;
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }
                                }
                                else
                                {
                                        audio_play_sound(snd_ring, 0, false);
                                        net_sound_emit(snd_ring);
                                }
                        }
                        
                        break;
                }
                
                case PacketType.CLIENT_SPAWN_EFFECT:
                {                               
                        var xx = buffer_read_s(rbuff, buffer_u16);
                        var yy = buffer_read_s(rbuff, buffer_u16);
                        var fade = buffer_read_s(rbuff, buffer_bool);
                        var dir = buffer_read_s(rbuff, buffer_s8);
                        var spr = buffer_read_s(rbuff, buffer_u8);
                        var xspd = buffer_read_s(rbuff, buffer_s8);
                        var yspd = buffer_read_s(rbuff, buffer_s8);
                        var spd = buffer_read_s(rbuff, buffer_f32);
                        
                        if(spr >= array_length(global.net_effs))
                                break;
                        
                        var inst = scr_effect_quick(xx, yy, global.net_effs[spr], spd, fade, xspd, yspd);
                        inst.image_xscale = dir;
                        
                        break;
                }
                
                case PacketType.SERVER_RMZSLIME_STATE:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var type = buffer_read_s(rbuff, buffer_u8);
                        
                        if(type == 0) //Spawn
                        {
                                var _uid = buffer_read_s(rbuff, buffer_u16);
                                var _xx = buffer_read_s(rbuff, buffer_u16);
                                var _yy = buffer_read_s(rbuff, buffer_u16);
                                var _state = buffer_read_s(rbuff, buffer_u8);
                                
                                var inst = instance_create_depth(_xx, _yy, 0, obj_rmzsonic);
                                inst.x = _xx;
                                inst.y = _yy;
                                inst.state = _state;
                                inst.nid = _uid;
                        }
                        else if(type == 2) //Despawn
                        {
                                var _uid = buffer_read_s(rbuff, buffer_u8);
                                
                                if(!instance_exists(obj_rmzsonic))
                                        break;
                                        
                                with(obj_rmzsonic)
                                {
                                        if(nid != _uid)
                                                continue;
                                        
                                        destroy();
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_RMZSLIME_RINGBONUS:
                {
                        if(isPasstrough)
                                break;
                                
                        var _isRed = buffer_read_s(rbuff, buffer_u8);
                        var _canHeal = buffer_read_s(rbuff, buffer_bool);
                        
                        if(!instance_exists(global.player))
                                break;
                                
                        if(global.player.isDead)
                                break;
                                
                        if(global.player.revivalTimes >= 2)
                                break;
                                
                        if(global.character == CHARACTER_EXE)
                                break;
                                
                        if(_isRed && global.player.redRingTimer <= 0)
                        {
                                // PASIVA 1 (Amy Canon): el anillo rojo no puede silenciar sus habilidades
                                // v4.4 «Ciega» (Amelia): misma exemption que en SERVER_RING_COLLECTED
                                // — ciega = sin alucinaciones; recoge el anillo sin efecto alguno.
                                if(global.character == CHARACTER_AMY_CANON || global.character == CHARACTER_AMELIA)
                                        break;
                                
                                audio_play_sound(mus_mindfuck, 0, false);
                                audio_play_sound(snd_redring, 0, false);
                                net_sound_emit(snd_redring);
                                net_quick_effect(x, y-10, spr_ring_sparkle);
                                instance_create_depth(0, 0, -100, obj_redring_screen);
                                global.player.redRingTimer = 60 * 10;
                        }
                        else if(!_isRed)
                        {
                                net_quick_effect(x, y-10, spr_ring_sparkle);
                                
                                global.player.rings++;
                                
                                if(global.player.redRingTimer >= 60)
                                {
                                        var cnt = ((global.timeMinutes <= 0 && global.timeSeconds <  60) ? 2 : 0.5) * 60;
                                        
                                        global.player.redRingTimer = max(global.player.redRingTimer - cnt, 60);
                                }
                                
                                if(global.player.rings >= 10 && global.player.hp < scr_player_maxhp(global.character) && _canHeal) // v13: max por personaje
                                {
                                        global.player.rings -= 10;
                                        global.player.hp = min(scr_player_maxhp(global.character), global.player.hp + 20); // v13: max por personaje
                                        audio_play_sound(snd_heal, 0, false);
                                        net_sound_emit(snd_heal);
                                        
                                        var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                        buffer_write(pak, buffer_u8, 0);
                                        send_server_tcp(pak);
                                        
                                        obj_achivements.healthRestore++;
                                        if(obj_achivements.healthRestore >= 3 && room != room_fartzone && !obj_achivements.achivements[16])
                                        {
                                                obj_achivements.mercoins += 100;
                                                obj_achivements.save();
                                                
                                                obj_achivements.achivements[16] = true;
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }
                                }
                                else
                                {
                                        audio_play_sound(snd_ring, 0, false);
                                        net_sound_emit(snd_ring);
                                }
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_FORCE_DAMAGE:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var dmg = buffer_read_s(rbuff, buffer_u8);
                        var dirX = buffer_read_s(rbuff, buffer_s8);
                        var dirY = buffer_read_s(rbuff, buffer_s8);
                        
                        scr_player_hurt(dmg, dirX, dirY);                               
                        break;
                }
                
                case PacketType.SERVER_ETRACKER_STATE:
                {                       
                        if(isPasstrough)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state == 0)
                        {
                                var _id = buffer_read_s(rbuff, buffer_u16);
                                var _x = buffer_read_s(rbuff, buffer_u16);
                                var _y = buffer_read_s(rbuff, buffer_u16);

                                var inst = instance_create_depth(_x, _y, 0, obj_eggtrack);
                                inst.nid = _id;
                                inst.x = _x;
                                inst.y = _y;
                        }
                        else if(_state == 2)
                        {
                                // v3.0 («GENIO MALVADO» de Eggman): el sensor esta
                                // MEJORADO (3 anillos del Dr.): el slow dura +25%
                                // (lo aplica su Step al pisarlo) y luce el CONTORNO
                                // DORADO (Draw_0 con spr_eggtrack_gold). Mismo
                                // layout de campos que el spawn (id + x + y).
                                // v3.1 (estilo RESCATE): se completa con la BARRA —
                                // cierre de barra + pago del Eggman con el lock
                                // (patron dedemonTarget) + efectos SOLO para el bando
                                // superviviente (el exe no ve cual sensor se mejoro).
                                var _id = buffer_read_s(rbuff, buffer_u16);
                                var _x = buffer_read_s(rbuff, buffer_u16);
                                var _y = buffer_read_s(rbuff, buffer_u16);

                                with(obj_eggtrack)
                                {
                                        if(nid != _id)
                                                continue;

                                        upgraded = true;
                                        upgShow = false;
                                        upgProg = 0;
                                        break;
                                }

                                if(global.character == CHARACTER_EGGMAN && instance_exists(global.player)
                                && global.player.geniusTarget == _id && global.player.geniusTargetType == 0)
                                {
                                        global.player.rings = max(0, global.player.rings - EGG_GENIUS_SENSOR_COST);
                                        global.player.geniusTarget = -1;
                                        global.player.geniusTargetType = -1;
                                }

                                if(instance_exists(global.player) && global.character != CHARACTER_EXE
                                && global.player.revivalTimes < 2)
                                {
                                        repeat(6)
                                                scr_effect_quick(_x + random_range(-14, 14), _y - random_range(0, 20), spr_shockparticle, 1, false, 0, 0);

                                        audio_play_sound(snd_heal, 0, false);
                                }
                        }
                        else
                        {                                               
                                if(!instance_exists(obj_eggtrack))
                                        break;
                                        
                                var _id = buffer_read_s(rbuff, buffer_u16);
                                var _pid = buffer_read_s(rbuff, buffer_u16);
                                
                                with(obj_eggtrack)
                                {
                                        if(nid != _id)
                                                continue;
                                                
                                        image_index = 0;
                                        sprite_index = spr_eggtrack_destroy;
                                        activated = true;
                                        break;
                                }
                                                                
                                if(!instance_exists(obj_player_puppet))
                                        break;
                                
                                var target = noone;
                                with(obj_player_puppet)
                                {
                                        if(master_id != _pid)
                                                continue;
                                        
                                        target = self;
                                }
                                
                                if(!instance_exists(obj_surv_indicator))
                                        break;
                                        
                                if(!instance_exists(global.player))
                                        break;
                                        
                                if(global.character == CHARACTER_EGGMAN)
                                {
                                        if(global.player.revivalTimes <= 2 && _pid == obj_netclient.exeId)
                                                obj_achivements.rEggTrack++;
                                        else
                                                obj_achivements.rExeEggTrack++;
                                                
                                        if(obj_achivements.rEggTrack >= 4 && room != room_fartzone && !obj_achivements.achivements[26])
                                        {
                                                obj_achivements.achivements[26] = true;
                                                obj_achivements.show();
                                                obj_achivements.save();
                                                
                                                obj_achivements.mercoins += 100;
                                                obj_achivements.save();
                                        }
                                        
                                        if(obj_achivements.rExeEggTrack >= 3 && room != room_fartzone && !obj_achivements.achivements[27])
                                        {
                                                obj_achivements.achivements[27] = true;
                                                obj_achivements.show();
                                                obj_achivements.save();
                                                
                                                obj_achivements.mercoins += 75;
                                                obj_achivements.save();
                                        }
                                }
                                
                                var isDemon = false;
                                if(global.character == CHARACTER_EGGMAN)
                                {
                                        isDemon = global.player.revivalTimes >= 2;                                      
                                }
                                else
                                {
                                        with(obj_player_puppet)
                                        {
                                                if(character != CHARACTER_EGGMAN)
                                                        continue;
                                                        
                                                isDemon = isDemonized;
                                        }
                                }
                                
                                if(isDemon && (global.player.revivalTimes < 2 && global.character != CHARACTER_EXE))
                                        break;
                                        
                                if(!isDemon && (global.player.revivalTimes >= 2 || global.character == CHARACTER_EXE))
                                        break;
                                
                                obj_surv_indicator.target = target;
                                obj_surv_indicator.alarm[0] = 60 * 3;
                        }
                        break;
                }

                case PacketType.SERVER_TRACKER_PING:
                {
                        // v3.0 («GENIO MALVADO»): cayo una TRAMPA DE AMELIA
                        // MEJORADA pisada por el bando EXE — el server
                        // ejecuta el RASTREADOR (lo que suele hacer el sensor
                        // de Eggman): la posicion de la VICTIMA se revela a
                        // TODOS los supervivientes 3 s. Mismo indicador
                        // (obj_surv_indicator) y mismo filtro de bando que el
                        // SERVER_ETRACKER_STATE de arriba; el sonido suena
                        // local en cada cliente superviviente.
                        if(isPasstrough)
                                break;

                        var _pid = buffer_read_s(rbuff, buffer_u16);

                        // solo el bando SUPERVIVIENTE ve el rastro
                        if(global.character == CHARACTER_EXE || (instance_exists(global.player) && global.player.revivalTimes >= 2))
                                break;

                        var _pingTarget = noone;
                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(master_id != _pid)
                                                continue;

                                        _pingTarget = self;
                                        break;
                                }
                        }

                        if(_pingTarget != noone && instance_exists(obj_surv_indicator) && instance_exists(global.player))
                        {
                                obj_surv_indicator.target = _pingTarget;
                                obj_surv_indicator.alarm[0] = 60 * 3;

                                audio_play_sound(snd_egg_tracker_activate, 0, false);
                        }
                        break;
                }

                case PacketType.SERVER_GAME_TIME_SYNC:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _timer = buffer_read_s(rbuff, buffer_u16);
                        if(instance_exists(obj_level))
                        {
                                global.timeMinutes = ceil((_timer+1) / 3600) - 1;
                                global.timeSeconds = ceil(_timer /  60) %  60;
                        }
                        
                        if(!instance_exists(obj_level))
                                break;
                                
                        obj_level.timeFrame++;
                        // v5.0 LMS: durante el show no sale el banner/estinuendo de la
                        // muerte subita (la cancion manda); la demonizacion de los caidos
                        // la sigue haciendo el server igual que siempre.
                        if(global.timeMinutes == 2 && global.timeSeconds == 1 && !global.lmsActive)
                                instance_create_depth(0, 0, 0, obj_suddendeath);
                                
                        if(global.timeMinutes == 0 && global.timeSeconds <= 10)
                                audio_play_sound(snd_clock, 1, false);
                        
                        break;
                }
                
                case PacketType.SERVER_GAME_LMS:
                {                               
                        if(isPasstrough)
                                break;
                        
                        if(!instance_exists(obj_level) || gameEnds)
                                break;
                        
                        // v5.3 — «EL SHOW FUERTE» por personaje: el server dice
                        // QUE personaje quedo como ULTIMO SUPERVIVIENTE y QUE
                        // cancion de su lista eligio (u8 + u8). Todos los clientes
                        // oyen la misma cancion y ven el banner; al personaje del
                        // show ademas le sube la vida (LMS_HP). Si su personaje no
                        // esta en la lista del show, el server ya no habria
                        // disparado nada. El reloj extendido llega solo, con el
                        // TIME_SYNC del siguiente segundo.
                        global.lmsActive = true;
                        
                        // v5.3: personaje del show + indice de SU cancion.
                        // Servers VIEJOS: v5.0 no mandaba payload (-1/-1) y
                        // v5.1 mandaba SOLO el indice de la cancion (que
                        // caeria en el hueco del personaje): en ambos casos
                        // el show era de SONIC, asi que se reconstruye asi.
                        var _lmsChar = buffer_read_s(rbuff, buffer_u8);
                        var _lmsSong = buffer_read_s(rbuff, buffer_u8);
                        if(_lmsSong < 0)
                        {
                                _lmsSong = _lmsChar;    // v5.1: eso era la cancion
                                _lmsChar = CHARACTER_SONIC;
                        }
                        else if(_lmsChar < 0)
                                _lmsChar = CHARACTER_SONIC;    // v5.0: sin payload
                        
                        // FIX LMS musica de mapa (v1): "...", Wood Zone y Act9
                        // tocan su musica por FUERA de global.music; sin esto
                        // seguia sonando la del mapa ENCIMA de la del show
                        // (dos canciones a la vez). Vale igual para el
                        // broadcast y para el re-envio al que se reconecta.
                        scr_stop_map_music();

                        // v69 (BOTAS) — RESTAURADO EN v72: corte de seguridad —
                        // si llegan botas activas al show, apagar el loop
                        // snd_speedboost y devolverle el volumen a la musica
                        // ANTES de la cancion del show (mismo espiritu que el
                        // scr_stop_map_music de arriba). El efecto (velocidad)
                        // sigue corriendo: solo se corta el audio.
                        audio_stop_sound(snd_speedboost);
                        scr_music_unduck();

                        scr_lms_play_song(_lmsChar, _lmsSong);
                        instance_create_depth(0, 0, 0, obj_lms_banner);
                        
                        if(global.character == _lmsChar && instance_exists(global.player) && !global.player.isDead)
                        {
                                // v24 (FIX LMS, pedido de la duena): antes ponia
                                // hp = LMS_HP (100) DIRECTO — a Rouge (vida total
                                // 125) y a Metal (150) el show les BAJABA la vida
                                // al arrancarlo (quedaban en 100 en vez de su
                                // maximo). El show ahora CURA hasta la vida MAXIMA
                                // del personaje (curar y anadir hasta el tope,
                                // nunca ajustar a un numero fijo): el que llega
                                // por debajo sube al maximo; el que ya estaba al
                                // maximo no baja. Para el resto (max 100) es el
                                // mismo resultado de siempre.
                                global.player.hp = max(global.player.hp, scr_player_maxhp(global.character));

                                audio_play_sound(snd_heal, 0, false);
                                net_sound_emit(snd_heal);
                                net_quick_effect(global.player.x, global.player.y, spr_ring_sparkle);
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_GAME_DEATHTIMER_TICK:
                {
                        var _exeNear = buffer_read_s(rbuff, buffer_u8);
                        var _id = buffer_read_s(rbuff, buffer_u16);
                        var _timer = buffer_read_s(rbuff, buffer_u8);
                        
                        if(obj_netclient.nid == _id)
                        {
                                if(!instance_exists(global.player))
                                        break;
                                        
                                global.player.deadTimer = _timer;
                                global.player.deadColor = _exeNear ? c_red : c_white;
                                break;
                        }
                        
                        if(!instance_exists(obj_player_puppet))
                                break;
                                
                        with(obj_player_puppet)
                        {
                                if(master_id != _id)
                                        continue;
                                        
                                deadTimer = _timer;
                                deadColor = _exeNear ? c_red : c_white;
                                break;
                        }
                        break;
                }
                
                case PacketType.SERVER_GAME_DEATHTIMER_END:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var demonize = buffer_read_s(rbuff, buffer_bool);
                        
                        if(!instance_exists(global.player))
                                break;
                        
                        if(!demonize)
                        { 
                                global.player.deadTimer = 31;
                                global.player.revivalTimes = 1;
                                break;
                        }
                        
                        if(instance_exists(obj_deserttown_i))
                                with(obj_deserttown_i)
                                        show = true;
                        
                        instance_create_depth(global.player.x, global.player.y, 0, obj_demon_indicator);
                        net_quick_effect(global.player.x, global.player.y + 32, spr_ring_teleport, false, 1, 0, 0, 2);
                        audio_play_sound(snd_demonization, 0, false);
                        
                        switch(global.character)
                        {
                                case CHARACTER_TAILS:
                                        global.player.attackTimer = 0;
                                        global.player.flyTimer = -420;
                                        break;
                                        
                                case CHARACTER_KNUX:
                                        global.player.attackTimer = 0;
                                        global.player.glideTimer = 0;
                                        break;
                                        
                                case CHARACTER_EGGMAN:
                                        global.player.djumpRecharge = 0;
                                        global.player.trackerRecharge = 0;
                                        global.player.shieldRechrage = 0;               
                                        break;
                                        
                                case CHARACTER_AMY:
                                        
                                case CHARACTER_AMY_CANON:
                                        global.player.attackTimer = 0;
                                        global.player.hjumpTimer = 0;
                                        global.player.dashTimer = 0; // ATAQUE 3: acometida lista al empezar la partida
                                        break;
                                        
                                case CHARACTER_VANILLA: // mismas habilidades que Cream
                                        
                                case CHARACTER_CREAM:
                                        global.player.flyTimer = 0;
                                        global.player.dashTimer = 0;
                                        global.player.ringsTimer = 0;
                                        break;
                                        
                                case CHARACTER_SALLY:
                                
                                case CHARACTER_SALLY_CANON: // defensivo: el server jamas la demoniza
                                        global.player.attackTimer = 0;
                                        global.player.shieldTimer = 0;
                                        global.player.shieldRechrage = 0;               
                                        break;
                                        
                                        // v2.2 (TTB): cooldowns de los rescatados
                                case CHARACTER_METAL:
                                        global.player.metalDashing = 0;
                                        global.player.isElectro = 0;
                                        global.player.dashTimer = 0;
                                        global.player.electroTimer = 0;
                                        break;
                                        
                                case CHARACTER_AMELIA:
                                        global.player.bananaTimer = 0;
                                        global.player.trapTimer = 0;
                                        global.player.isSpinCharging = false;
                                        global.player.spinCharge = 0;
                                        break;
                                        
                                case CHARACTER_BLAZE:
                                        global.player.djumpRecharge = 0;
                                        global.player.fireballTimer = 0;
                                        global.player.burningTimer = 0;
                                        global.player.burning = 0;
                                        global.player.shootPose = 0;
                                        break;
                                                }
                        
                        var table = obj_unlockables.palettes[? global.character + PALETTE_DEMON];
                        
                        global.palleteFrom = table.from;
                        global.palleteTo = table.to;
                        global.palleteName = table.name;
                        net_send_palette();
                        
                        obj_achivements.alarm[1] = 60 * 5;
                        obj_achivements.demonLast = true;
                        
                        global.player.hp = 100;
                        global.player.isDead = false;
                        global.player.revivalTimes = 2;
                        global.player.isMinion = false; // v6: esbirro COMUN (demonizacion normal): sin vida real
                        global.player.isNegatouch = false; // v7: demonizacion normal = ya NO es un negativo
                        
                        with(global.player.reviveObj)
                                instance_destroy();
                        
                        global.player.reviveObj = noone;
                        global.player.hurttime = 60 * 2;
                        global.cameraMode = 0;
                        break;
                }
                
                case PacketType.SERVER_VANILLA_DEDEMONIZE:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _dnid = buffer_read_s(rbuff, buffer_u16);
                        
                        // v2.11: si YO soy la Vanilla que estaba rescatando a este
                        // esbirro, pago los 15 anillos AL COMPLETAR (cobrar aqui y no
                        // al empezar hace que soltar el ABAJO a mitad no tire el
                        // dinero: el progreso hecho se conserva en el server, igual
                        // que el revive del caido conserva su barra)
                        if(global.character == CHARACTER_VANILLA && instance_exists(global.player) && global.player.dedemonTarget == _dnid)
                        {
                                global.player.rings = max(0, global.player.rings - VANILLA_DEDEMON_COST);
                                global.player.dedemonTarget = -1;
                        }
                        
                        // efecto + sonido en el puppet del esbirro (lo crean
                        // TODOS los clientes al recibir este paquete)
                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(master_id != _dnid)
                                                continue;
                                        
                                        scr_effect_quick(x, y, spr_ring_teleport, 1, false, 0, 0);
                                        audio_play_sound(snd_heal, false, 0);
                                        break;
                                }
                        }
                        
                        // el OBJETIVO des-demoniza a SU jugador local: vuelve a
                        // "1 caida mas para re-demonizarse" (revivalTimes 1),
                        // paleta normal y 2 s de i-frames
                        if(_dnid == obj_netclient.nid && instance_exists(global.player))
                        {
                                // v17 (RESCATE DE LOS CAÍDOS): si el objetivo venía
                                // MUERTO (el milagro de Vanilla con los caídos), se
                                // restauran también el estado de muerte que el
                                // esbirro nunca tuvo: contador de agonia, color de
                                // muerte, cámara de espectador y la barrita de
                                // revive. Para el esbirro/nega rescatado nada de
                                // esto cambia (no estaba muerto).
                                var _wasDead = global.player.isDead;
                                
                                global.player.revivalTimes = 1;
                                global.player.hp = scr_player_maxhp(global.character); // v13: revivir = vida COMPLETA del personaje
                                global.player.isDead = false;
                                global.player.hurttime = 60 * 2;
                                global.player.isMinion = false; // v6: si era minion, ya no lo es
                                global.player.isNegatouch = false; // v7: si era un negativo, ya no lo es

                                // v7: la carga negativa se purga al ser rescatado
                                if(variable_instance_exists(global.player.id, "jinnaNegaCharge"))
                                        global.player.jinnaNegaCharge = 0;
                                
                                if(_wasDead)
                                {
                                        global.player.deadTimer = 31;
                                        global.player.deadColor = c_white;
                                        global.player.shockedTimer = 0;
                                        global.player.isHurt = false;
                                        global.cameraMode = 0; // vuelve de la cámara de espectador
                                        
                                        with(global.player.reviveObj)
                                                instance_destroy();
                                        
                                        global.player.reviveObj = noone;
                                }
                                
                                var _dtable = obj_unlockables.palettes[? global.character];
                                
                                global.palleteFrom = _dtable.from;
                                global.palleteTo = _dtable.to;
                                global.palleteName = _dtable.name;
                                net_send_palette();
                                
                                with(obj_demon_indicator)
                                        instance_destroy();
                                
                                // cooldowns listos (misericordia materna)
                                global.player.flyTimer = 0;
                                global.player.dashTimer = 0;
                                global.player.ringsTimer = 0;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_GAME_PLAYER_ESCAPED:
                {                               
                        var pid = buffer_read_s(rbuff, buffer_u16);
                        
                        obj_achivements.rPlayersEscaped++;
                        
                        if(!instance_exists(obj_player_puppet))
                                break;
                        
                        with(obj_player_puppet)
                        {
                                if(pid == master_id)
                                {
                                        if(obj_camera.spectatingObj == self)
                                                obj_camera.spectatingObj = noone;
                                                
                                        instance_destroy();
                                        break;
                                }
                        }
                        
                        audio_play_sound(snd_teleport, 0, false);
                        
                        if(!instance_exists(obj_bigring))
                                break;
                        
                        instance_create_depth(obj_bigring.x, obj_bigring.y, -100, obj_bigring_teleport);
                        break;
                }
                
                case PacketType.SERVER_GAME_SPAWN_RING:
                {
                        if(isPasstrough)
                                break;
                                
                        var type = buffer_read_s(rbuff, buffer_bool);
                        
                        if(gameEnds)
                                break;
                        
                        if(!type)
                        {
                                if(instance_exists(obj_bigring))
                                {
                                        with(obj_bigring)
                                                sprite_index = spr_bigring;
                                        break;
                                }
                                
                                // v5.0 LMS: durante el show la musica es Undefeatable hasta
                                // el final — la musica de persecucion del anillo NO la
                                // reemplaza (el anillo sigue apareciendo normal).
                                if(!global.lmsActive)
                                {
                                        // FIX LMS musica de mapa (v1): Wood Zone tambien suena
                                        // con las layers de mus_dotdotdot (monta obj_dotdotdot_i),
                                        // asi que entra en la misma rama: se paran igual y su
                                        // persecucion es la de SU entrada de levels.
                                        if(room == room_dotdotdot || room == room_woodzone)
                                        {
                                                audio_stop_sound(mus_dotdotdot);
                                                audio_stop_sound(mus_dotdotdot2);
                                                
                                                scr_play_music(room == room_dotdotdot ? mus_dotdotdot_chase : global.levels[lvlId].chaseMusic);
                                        }
                                        else if(room == room_act9)
                                        {
                                                audio_sound_gain(mus_act9, 0, 1000);
                                                audio_sound_gain(mus_act9_chase, obj_config.musicVolume * 0.1, 1000); // v1 OPTIONS MORE
                                        }
                                        else
                                                scr_play_music(global.levels[lvlId].chaseMusic);
                                }
                                
                                var ind = buffer_read_s(rbuff, buffer_u8); 
                                var inst = instance_find(obj_ringspawn, ind % (instance_number(obj_ringspawn)));
                                
                                instance_create_depth(inst.x, inst.y, 0, obj_bigring);
                                                        
                                with(obj_level)
                                        state = 1;
                                        
                                if(room == room_notperfect)
                                {
                                        with(obj_npring)
                                                visible = true;
                                }
                        }
                        else
                        {
                                if(!instance_exists(obj_bigring))
                                        break;
                                        
                                with(obj_bigring)
                                        sprite_index = spr_bigring_ready;
                        }
                                
                        break;
                }
                
                case PacketType.SERVER_GAME_EXE_WINS:
                {                               
                        if(isPasstrough)
                                break;
                                
                        var _achiv = buffer_read_s(rbuff, buffer_bool);
                                
                        gameEnds = true;
                        if(instance_exists(obj_deserttown_i))
                                with(obj_deserttown_i)
                                        show = false;
                                
                        // v1 (D.I.B.): si la killer es Jinna, su victoria suena
                        // con su risa (snd_jina_laugh) en vez del jingle generico
                        // de exe. Mismo patron que la risa de inicio de partida
                        // (net_state_charselect): exe local via global.exeCharacter,
                        // exe remoto via su entrada del players map.
                        var _exeChar = -1;
                        if(global.character == CHARACTER_EXE)
                                _exeChar = global.exeCharacter;
                        else if(ds_map_exists(players, exeId))
                                _exeChar = players[? exeId].exeCharacter;
                        
                        audio_play_sound(_exeChar == EXE_JINNA ? snd_jina_laugh : snd_exe_wins, 0, false);
                        var inst = instance_create_depth(0, 0, -9999, obj_ending);
                        
                        if(global.character == CHARACTER_EXE)
                        {
                                inst.sprite_index = spr_youkilledeveryone;
                                
                                if(room != room_fartzone && _achiv)
                                {
                                        obj_achivements.exeWins++;

                                        var map = room_get_name(room);
                                        if(!array_contains(obj_achivements.maps, map))
                                                array_push(obj_achivements.maps, map);
                                                
                                        if(array_length(obj_achivements.maps) >= 20 && room != room_fartzone && !obj_achivements.achivements[49])
                                        {
                                                obj_achivements.achivements[49] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.show();
                                        }
                                        
                                        obj_achivements.save();
                                }
                                
                                if(_achiv)
                                {
                                        switch(global.exeCharacter)
                                        {
                                                case EXE_ORIGINAL: obj_achivements.exe = true; break;
                                                case EXE_CHAOS: obj_achivements.chaos = true; break;
                                                case EXE_EXETIOR: obj_achivements.exetior = true; break;
                                                case EXE_EXELLER: obj_achivements.exeller = true; break;
                                        }
                                
                                        with(obj_achivements)
                                        {
                                                if(!achivements[19] && exe && chaos && exetior && exeller)
                                                {
                                                        obj_achivements.achivements[19] = true;
                                                        obj_achivements.mercoins += 100;
                                        
                                                        obj_achivements.show();
                                                }
                                        }
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 10 && room != room_fartzone && !obj_achivements.achivements[0])
                                        {
                                                obj_achivements.achivements[0] = true;
                                                obj_achivements.mercoins += 50;
                                        
                                                obj_achivements.show();
                                        }
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 50 && room != room_fartzone && !obj_achivements.achivements[1])
                                        {
                                                obj_achivements.achivements[1] = true;
                                                obj_achivements.mercoins += 250;
                                        
                                                obj_achivements.show();
                                        }       
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 100 && room != room_fartzone && !obj_achivements.achivements[2])
                                        {
                                                obj_achivements.achivements[2] = true;
                                                obj_achivements.mercoins += 500;
                                        
                                                obj_achivements.show();
                                        }
                                
                                        if(ds_exists(obj_netclient.players, ds_type_map))
                                        {
                                                var dick = ds_map_size(obj_netclient.players);
                                        
                                                if(dick > 0)
                                                        obj_achivements.mercoins += (dick - 1) * 2;
                                        }
                                }
                        }
                        else if(instance_exists(global.player) && global.player.revivalTimes >= 2)
                                inst.sprite_index = spr_youkilledeveryone;
                        else
                                inst.sprite_index = spr_gameover;
                        
                        obj_achivements.save();
                        obj_achivements.save();
                                
                        if(!instance_exists(obj_level))
                        {
                                audio_stop_all();
                                global.ringId = 0;
                                global.player = noone;
                                global.character = -1;
                                global.exeCharacter = -1;
                                global.playerControls = true;
                                ds_map_destroy(players);
                                players = ds_map_create();
                                exeId = -1;
                                
                                // Slots de personajes: se dimensionan solos
                                // (ver scr_characters / scr_avchars_reset)
                                avCharacters = scr_avchars_reset();
                                
                                gameEnds = false;
                                state = STATE_LOBBY;
                                room_goto(room_lobby);
                                
                                var buffer = cpacket_tcp(PacketType.CLIENT_LOBBY_PLAYERS_REQUEST, false);
                                send_server_tcp(buffer);
                                return true;
                        }
                        
                        with(obj_level)
                                alarm[1] = 60 * 3;
                        
                        if(instance_exists(obj_bigring))
                                with(obj_bigring)
                                        instance_destroy();
                        
                        with(obj_player_puppet)
                        {
                                if(master_id != obj_netclient.exeId)
                                        continue;
                                        
                                global.cameraMode = 2;
                                obj_camera.spectatingObj = self;
                                obj_camera.locked = true;
                                break;
                        }
                                
                        if(!instance_exists(global.player))
                                break;
                                
                        if(global.character == CHARACTER_EXE)
                        {
                                global.player.won = true;
                                global.playerControls = false;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_GAME_TIME_OVER:
                {                       
                        if(isPasstrough)
                                break;
                        
                        var _achiv = buffer_read_s(rbuff, buffer_bool);
                                
                        gameEnds = true;
                        if(instance_exists(obj_deserttown_i))
                                with(obj_deserttown_i)
                                        show = false;
                                
                        global.playerControls = false;
                        
                        // v1 (D.I.B.): igual que en EXE_WINS — si la killer es
                        // Jinna, la victoria por tiempo suena con su risa.
                        var _exeChar = -1;
                        if(global.character == CHARACTER_EXE)
                                _exeChar = global.exeCharacter;
                        else if(ds_map_exists(players, exeId))
                                _exeChar = players[? exeId].exeCharacter;
                        
                        audio_play_sound(_exeChar == EXE_JINNA ? snd_jina_laugh : snd_exe_wins, 0, false);
                        var inst = instance_create_depth(0, 0, -9999, obj_ending);
                        inst.sprite_index = spr_timeover;
                                                
                        if(global.character == CHARACTER_EXE)
                        {
                                if(room != room_fartzone && _achiv)
                                {
                                        obj_achivements.exeWins++;
                                        
                                        var map = room_get_name(room);
                                        if(!array_contains(obj_achivements.maps, map))
                                                array_push(obj_achivements.maps, map);
                                                
                                        if(array_length(obj_achivements.maps) >= 18 && room != room_fartzone && !obj_achivements.achivements[49])
                                        {
                                                obj_achivements.achivements[49] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.show();
                                        }
                                }
                                
                                if(_achiv)
                                {
                                        switch(global.exeCharacter)
                                        {
                                                case EXE_ORIGINAL: obj_achivements.exe = true; break;
                                                case EXE_CHAOS: obj_achivements.chaos = true; break;
                                                case EXE_EXETIOR: obj_achivements.exetior = true; break;
                                                case EXE_EXELLER: obj_achivements.exeller = true; break;
                                        }
                                
                                        with(obj_achivements)
                                        {
                                                if(!achivements[19] && exe && chaos && exetior && exeller)
                                                {
                                                        obj_achivements.achivements[19] = true;
                                                        obj_achivements.mercoins += 100;
                                        
                                                        obj_achivements.show();
                                                }
                                        }
                                        
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 10 && room != room_fartzone && !obj_achivements.achivements[0])
                                        {
                                                obj_achivements.achivements[0] = true;
                                                obj_achivements.mercoins += 50;
                                        
                                                obj_achivements.show();
                                        }
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 50 && room != room_fartzone && !obj_achivements.achivements[1])
                                        {
                                                obj_achivements.achivements[1] = true;
                                                obj_achivements.mercoins += 250;
                                        
                                                obj_achivements.show();
                                        }       
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 100 && room != room_fartzone && !obj_achivements.achivements[2])
                                        {
                                                obj_achivements.achivements[2] = true;
                                                obj_achivements.mercoins += 500;
                                        
                                                obj_achivements.show();
                                        }
                                
                                        if(ds_exists(obj_netclient.players, ds_type_map))
                                        {
                                                var dick = ds_map_size(obj_netclient.players);
                                        
                                                if(dick > 0)
                                                        obj_achivements.mercoins += (dick - 1) * 2;
                                        }
                                
                                        if(obj_achivements.mercoins <= 0)
                                                obj_achivements.mercoins = 0;
                                }
                        }
                        
                        obj_achivements.save();
                        obj_achivements.save();
                        
                        if(!instance_exists(obj_level))
                        {
                                audio_stop_all();
                                global.ringId = 0;
                                global.player = noone;
                                global.character = -1;
                                global.exeCharacter = -1;
                                global.playerControls = true;
                                ds_map_destroy(players);
                                players = ds_map_create();
                                exeId = -1;
                                
                                // Slots de personajes: se dimensionan solos
                                // (ver scr_characters / scr_avchars_reset)
                                avCharacters = scr_avchars_reset();
                                
                                gameEnds = false;
                                state = STATE_LOBBY;
                                room_goto(room_lobby);
                                
                                var buffer = cpacket_tcp(PacketType.CLIENT_LOBBY_PLAYERS_REQUEST, false);
                                send_server_tcp(buffer);
                                return true;
                        }
                        
                        with(obj_level)
                                alarm[1] = 60 * 3;
                        
                        if(instance_exists(obj_bigring))
                                with(obj_bigring)
                                        instance_destroy();
                        
                        with(obj_player_puppet)
                        {
                                if(master_id != obj_netclient.exeId)
                                        continue;
                                        
                                global.cameraMode = 2;
                                obj_camera.spectatingObj = self;
                                obj_camera.locked = true;
                                break;
                        }
                                
                        if(!instance_exists(global.player))
                                break;
                                
                        if(global.character == CHARACTER_EXE)
                        {
                                global.player.won = true;
                                global.playerControls = false;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_GAME_PLAYERS_READY:
                {
                        if(isPasstrough)
                                break;
                                
                        isServerReady = true;
                        net_send_palette();
                        break;
                }
                
                case PacketType.CLIENT_PET_PALETTE:
                {
                        var _type = buffer_read_s(rbuff, buffer_bool);
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        var _size = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_player_puppet))
                                break;
                        
                        with(obj_player_puppet)
                        {
                                if(master_id != _pid)
                                        continue;
                                
                                if(_type)
                                {
                                        petFromPallete = array_create(_size, 0);
                                        
                                        for(var i = 0; i < _size; i++)
                                                petFromPallete[i] = buffer_read_s(rbuff, buffer_u8) / 255.0;
                                }
                                else
                                {
                                        petToPallete = array_create(_size, 0);
                                        
                                        for(var i = 0; i < _size; i++)
                                                petToPallete[i] = buffer_read_s(rbuff, buffer_u8) / 255.0;
                                }
                                break;
                        }
                        
                        
                        break;
                }
                
                case PacketType.SERVER_MJCRYSTAL_STATE:
                {
                        if(isPasstrough)
                                 break;
                                 
                        var _state = buffer_read_s(rbuff, buffer_bool);
                        if(!instance_exists(obj_marijuna_crystal))
                                break;
                                
                        with(obj_marijuna_crystal)
                        {
                                activated = _state;
                                
                                if(activated)
                                        audio_play_sound_on(emitter, snd_destiny, false, 0);
                        }
                        break;
                }
                
                case PacketType.SERVER_MJJUDGER_STATE:
                {
                        if(isPasstrough)
                                 break;
                                 
                        var _state = buffer_read_s(rbuff, buffer_bool);
                        if(!instance_exists(obj_marijuna_judger))
                                break;
                                
                        with(obj_marijuna_judger)
                        {                                       
                                state = _state;
                                
                                if(state == 1)
                                        audio_play_sound_on(emitter, snd_judger, false, 0);
                        }
                        
                        break;
                }
                
                case PacketType.CLIENT_PLAYER_PALETTE:
                {
                        var _type = buffer_read_s(rbuff, buffer_bool);
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        var _name = buffer_read_s(rbuff, buffer_string);
                        var _size = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_player_puppet))
                                break;
                                
                        with(obj_player_puppet)
                        {
                                if(master_id != _pid)
                                        continue;
                                
                                palleteName = _name;
                                
                                if(_type)
                                {
                                        fromPallete = array_create(_size, 0);
                                        
                                        for(var i = 0; i < _size; i++)
                                                fromPallete[i] = buffer_read_s(rbuff, buffer_u8) / 255.0;
                                }
                                else
                                {
                                        toPallete = array_create(_size, 0);
                                        
                                        for(var i = 0; i < _size; i++)
                                        {                                               
                                                toPallete[i] = buffer_read_s(rbuff, buffer_u8) / 255.0;
                                        }
                                }
                                        
                                break;
                        }
                        
                        var _pur = false;
                        var _target = noone;
                        
                        if(global.character != CHARACTER_EXE)
                        {
                                if(!instance_exists(obj_player_puppet))
                                        return;
                                
                                var _tg = noone;
                                with(obj_player_puppet)
                                {
                                        if(character != CHARACTER_EXE)
                                                continue;
                                                
                                        _tg = self;
                                }
                                
                                _target = _tg;
                        }
                        else
                        {
                                if(global.palleteName == "menace")
                                        _pur = true;
                        }
                        
                        if(_target != noone)
                        {
                                if(_target.palleteName == "menace")
                                        _pur = true;
                        }
                        
                        if(_pur)
                        {
                                if(!instance_exists(obj_blackring))
                                        break;
                                        
                                with(obj_blackring)
                                        sprite_index = spr_blackring_purple;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_GAME_SURVIVOR_WIN:
                {                       
                        if(isPasstrough)
                                break;
                                
                        var _achiv = buffer_read_s(rbuff, buffer_bool);
                                
                        gameEnds = true;
                        if(instance_exists(obj_deserttown_i))
                                with(obj_deserttown_i)
                                        show = false;
                        
                        global.playerControls = false;
                        
                        audio_play_sound(snd_survivor_win, 0, false);
                        var inst = instance_create_depth(0, 0, -9999, obj_ending);
                        
                        if(global.character == CHARACTER_EXE || (instance_exists(global.player) && (global.player.revivalTimes >= 2 || global.player.hp <= 0)))
                                inst.sprite_index = spr_gameover;
                        else
                        {
                                if(room != room_fartzone && _achiv)
                                {
                                        obj_achivements.survWins++;
                                
                                        var map = room_get_name(room);
                                        if(!array_contains(obj_achivements.maps, map))
                                                array_push(obj_achivements.maps, map);
                                                
                                        if(array_length(obj_achivements.maps) >= 18 && !obj_achivements.achivements[49])
                                        {
                                                obj_achivements.achivements[49] = true;
                                                obj_achivements.mercoins += 100;
                                                
                                                obj_achivements.show();
                                        }
                                        
                                        obj_achivements.save();
                                }
                                
                                if(_achiv)
                                {
                                        switch(global.character)
                                        {
                                                case CHARACTER_TAILS: obj_achivements.tails = true; break;
                                                case CHARACTER_KNUX: obj_achivements.knux = true; break;
                                                case CHARACTER_EGGMAN: obj_achivements.eggman = true; break;
                                                case CHARACTER_AMY: obj_achivements.amy = true; break;
                                                case CHARACTER_CREAM: obj_achivements.cream = true; break;
                                                case CHARACTER_SALLY: obj_achivements.sally = true; break;
                                        }
                                
                                        if(room != room_fartzone && room == room_pricelessfreedom && !obj_achivements.achivements[47] && obj_achivements.rBlackRings == 0)
                                        {
                                                obj_achivements.mercoins += 25;
                                                obj_achivements.save();
                                        
                                                obj_achivements.achivements[47] = true;
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }
                                
                                        if(room != room_fartzone && !obj_achivements.achivements[48] && obj_achivements.rShardsCollected >= 6)
                                        {
                                                obj_achivements.mercoins += 25;
                                                obj_achivements.save();
                                        
                                                obj_achivements.achivements[48] = true;
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }
                                
                                        if(room != room_fartzone && !obj_achivements.achivements[28] && (global.character == CHARACTER_AMY || global.character == CHARACTER_AMY_CANON) && obj_achivements.rAmyStuns == 0)
                                        {
                                                obj_achivements.mercoins += 75;
                                                obj_achivements.save();
                                        
                                                obj_achivements.achivements[28] = true;
                                                obj_achivements.save();
                                                obj_achivements.show();
                                        }
                                
                                        if(!obj_achivements.wasHurt && room != room_fartzone && !obj_achivements.achivements[11])
                                        {
                                                obj_achivements.achivements[11] = true;
                                        
                                                obj_achivements.mercoins += 50;
                                                obj_achivements.show();
                                        }
                                
                                        with(obj_achivements)
                                        {
                                                switch(room)
                                                {
                                                        case room_hideandseek2:
                                                        case room_angelisland:
                                                                if(global.character == CHARACTER_TAILS)
                                                                {
                                                                        if(!achivements[38])
                                                                        {
                                                                                obj_achivements.mercoins += 25;
                                                                                obj_achivements.save();
                                                                        
                                                                                achivements[38] = true;
                                                                                save();
                                                                                show();
                                                                        }
                                                                }
                                                                break;
                                                
                                                        case room_youcantrun:
                                                                if(global.character == CHARACTER_KNUX)
                                                                {
                                                                        if(!achivements[39])
                                                                        {
                                                                                obj_achivements.mercoins += 25;
                                                                                obj_achivements.save();
                                                                        
                                                                                achivements[39] = true;
                                                                                save();
                                                                                show();
                                                                        }
                                                                }
                                                                break;
                                                        
                                                        case room_dotdotdot:
                                                                if(global.character == CHARACTER_EGGMAN)
                                                                {
                                                                        if(!achivements[40])
                                                                        {
                                                                                obj_achivements.mercoins += 25;
                                                                                obj_achivements.save();
                                                                        
                                                                                achivements[40] = true;
                                                                                save();
                                                                                show();
                                                                        }
                                                                }
                                                                break;
                                                        
                                                        case room_notperfect:
                                                                if((global.character == CHARACTER_AMY || global.character == CHARACTER_AMY_CANON))
                                                                {
                                                                        if(!achivements[41])
                                                                        {
                                                                                obj_achivements.mercoins += 25;
                                                                                obj_achivements.save();
                                                                        
                                                                                achivements[41] = true;
                                                                                save();
                                                                                show();
                                                                        }
                                                                }
                                                                break;
                                                        
                                                        case room_kindandfair:
                                                                if(global.character == CHARACTER_CREAM)
                                                                {
                                                                        if(!achivements[42])
                                                                        {
                                                                                obj_achivements.mercoins += 25;
                                                                                obj_achivements.save();
                                                                        
                                                                                achivements[42] = true;
                                                                                save();
                                                                                show();
                                                                        }
                                                                }
                                                                break;
                                                                
                                                        case room_act9:
                                                                if(global.character == CHARACTER_SALLY)
                                                                {
                                                                        if(!achivements[43])
                                                                        {
                                                                                obj_achivements.mercoins += 25;
                                                                                obj_achivements.save();
                                                                        
                                                                                achivements[43] = true;
                                                                                save();
                                                                                show();
                                                                        }
                                                                }
                                                                break;
                                                        
                                                        case room_torturecave:
                                                                if(global.character == CHARACTER_TAILS)
                                                                {
                                                                        var exeChar = 0;
                                                                
                                                                        if(instance_exists(obj_player_puppet))
                                                                        {
                                                                                with(obj_player_puppet)
                                                                                {
                                                                                        if(character != CHARACTER_EXE)
                                                                                                continue;
                                                                                        
                                                                                        exeChar = exeCharacter;
                                                                                        break;
                                                                                }
                                                                        }
                                                                
                                                                        if(exeChar == EXE_CHAOS)
                                                                        {
                                                                                if(!achivements[44])
                                                                                {
                                                                                        obj_achivements.mercoins += 25;
                                                                                        obj_achivements.save();
                                                                                
                                                                                        achivements[44] = true;
                                                                                        save();
                                                                                        show();
                                                                                }
                                                                        }
                                                                }
                                                                break;
                                                        
                                                        case room_limpcity:
                                                                if(global.character == CHARACTER_SALLY)
                                                                {
                                                                        var exeChar = 0;
                                                                
                                                                        if(instance_exists(obj_player_puppet))
                                                                        {
                                                                                with(obj_player_puppet)
                                                                                {
                                                                                        if(character != CHARACTER_EXE)
                                                                                                continue;
                                                                                        
                                                                                        exeChar = exeCharacter;
                                                                                        break;
                                                                                }
                                                                        }
                                                                
                                                                        if(exeChar == EXE_EXELLER)
                                                                        {
                                                                                if(!achivements[46])
                                                                                {
                                                                                        obj_achivements.mercoins += 25;
                                                                                        obj_achivements.save();
                                                                                
                                                                                        achivements[46] = true;
                                                                                        save();
                                                                                        show();
                                                                                }
                                                                        }
                                                                }
                                                                break;
                                                        
                                                        case room_nastyparadise:
                                                                if(global.character == CHARACTER_CREAM)
                                                                {
                                                                        var exeChar = 0;
                                                                
                                                                        if(instance_exists(obj_player_puppet))
                                                                        {
                                                                                with(obj_player_puppet)
                                                                                {
                                                                                        if(character != CHARACTER_EXE)
                                                                                                continue;
                                                                                        
                                                                                        exeChar = exeCharacter;
                                                                                        break;
                                                                                }
                                                                        }
                                                                
                                                                        if(exeChar == EXE_EXETIOR)
                                                                        {
                                                                                if(!achivements[45])
                                                                                {
                                                                                        obj_achivements.mercoins += 25;
                                                                                        obj_achivements.save();
                                                                                
                                                                                        achivements[45] = true;
                                                                                        save();
                                                                                        show();
                                                                                }
                                                                        }
                                                                }
                                                                break;
                                                }
                                
                                                if(!achivements[18] && tails && knux && eggman && amy && cream && sally)
                                                {
                                                        obj_achivements.mercoins += 100;
                                                        obj_achivements.save();
                                                
                                                        achivements[18] = true;
                                                        save();
                                                        show();
                                                }
                                        
                                                if(!achivements[20] && rPlayersEscaped >= 5)
                                                {
                                                        obj_achivements.mercoins += 50;
                                                
                                                        achivements[20] = true;
                                                        show();
                                                }
                                        }
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 10 && room != room_fartzone && !obj_achivements.achivements[0])
                                        {
                                                obj_achivements.achivements[0] = true;
                                                obj_achivements.mercoins += 50;
                                        
                                                obj_achivements.show();
                                        }
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 50 && room != room_fartzone && !obj_achivements.achivements[1])
                                        {
                                                obj_achivements.achivements[1] = true;
                                                obj_achivements.mercoins += 250;
                                        
                                                obj_achivements.show();
                                        }       
                                
                                        if(obj_achivements.survWins + obj_achivements.exeWins >= 100 && room != room_fartzone && !obj_achivements.achivements[2])
                                        {
                                                obj_achivements.achivements[2] = true;
                                                obj_achivements.mercoins += 500;
                                        
                                                obj_achivements.show();
                                        }
                                }
                                
                                inst.sprite_index = spr_survivorsescaped;
                        }
                        
                        obj_achivements.save();
                        obj_achivements.save();
                        
                        if(!instance_exists(obj_level))
                        {
                                audio_stop_all();
                                global.ringId = 0;
                                global.player = noone;
                                global.character = -1;
                                global.exeCharacter = -1;
                                global.playerControls = true;
                                ds_map_destroy(players);
                                players = ds_map_create();
                                exeId = -1;
                                
                                // Slots de personajes: se dimensionan solos
                                // (ver scr_characters / scr_avchars_reset)
                                avCharacters = scr_avchars_reset();
                                
                                gameEnds = false;
                                state = STATE_LOBBY;
                                room_goto(room_lobby);
                                
                                var buffer = cpacket_tcp(PacketType.CLIENT_LOBBY_PLAYERS_REQUEST, false);
                                send_server_tcp(buffer);
                                return true;
                        }
                        
                        with(obj_level)
                                alarm[1] = 60 * 3;
                        
                        with(obj_player_puppet)
                        {
                                if(master_id != obj_netclient.exeId)
                                        continue;
                                        
                                global.cameraMode = 2;
                                obj_camera.spectatingObj = self;
                                obj_camera.locked = true;
                                break;
                        }
                        
                        if(!instance_exists(global.player))
                                break;
                                
                        if(global.character == CHARACTER_EXE)
                        {
                                global.player.lost = true;
                                global.playerControls = false;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_REVIVAL_REVIVED:
                {
                        if(isPasstrough)
                                break;
                                
                        if(!instance_exists(global.player))
                                return;
                        
                        if(global.player.revivalTimes >= 2)
                                return;
                                
                        var packet = cpacket_tcp(PacketType.CLIENT_PLAYER_DEATH_STATE);
                        buffer_write(packet, buffer_bool, false);
                        buffer_write(packet, buffer_u8, global.player.revivalTimes);
                        send_server_tcp(packet);
                        
                        if(instance_exists(obj_deserttown_i))
                                with(obj_deserttown_i)
                                        show = true;
                        
                        global.player.hp = 40;
                        global.player.isDead = false;
                        global.player.revivalTimes++;
                        
                        with(global.player.reviveObj)
                                instance_destroy();
                                
                        global.player.reviveObj = noone;
                        // SONIC: revive con POWERBOOST (fase 2): 6 segundos de inmunidad
                        // (el revive estandar da 4) y los efectos del boost NO se apagan
                        // al acabar la inmunidad: esa es su fase 2 persistente (solo la
                        // apaga morir de verdad o demonizarse; ver obj_sonic Step_0).
                        if(global.character == CHARACTER_SONIC)
                        {
                                global.player.hurttime = SONIC_REVIVEBOOST_INVULN;
                                global.player.reviveBoost = true;
                                global.player.pbTime = 0;
                                global.player.pbFlash = SONIC_PB_FLASH_FRAMES;
                                
                                audio_play_sound(snd_dash, 0, false);
                                net_quick_effect(global.player.x, global.player.y, spr_shockparticle, false, 1, 0, 0, 1);
                        }
                        else
                                global.player.hurttime = 60 * 4;
                        
                        global.cameraMode = 0;
                        break;
                }
                
                case PacketType.CLIENT_PLAYER_HEAL_PART:
                {
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        instance_create_depth(_x, _y, -10, obj_heal_particle);
                        break;
                }
                
                case PacketType.CLIENT_PLAYER_HEAL:
                {
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        
                        if(obj_netclient.nid != _pid)
                                break;
                        
                        if(!instance_exists(global.player))
                                 break;
                                 
                        if(global.player.hp >= scr_player_maxhp(global.character)) // v13: max por personaje
                                return;
                        
                        audio_play_sound(snd_heal, 0, false);
                        net_sound_emit(snd_heal);
                        
                        global.player.hp = min(scr_player_maxhp(global.character), global.player.hp + 20); // v13: max por personaje
                        break;
                }
                
                case PacketType.SERVER_REVIVAL_RINGSUB:
                {
                        if(isPasstrough)
                                break;
                        
                        if(!instance_exists(global.player))
                                 break;
                                
                        global.player.rings = 0;
                        obj_achivements.revivals++;
                        
                        if(obj_achivements.revivalLast && room != room_fartzone && !obj_achivements.achivements[5])
                        {
                                obj_achivements.achivements[5] = true;
                                obj_achivements.mercoins += 100;
                                obj_achivements.save();
                                obj_achivements.save();
                                
                                obj_achivements.show();
                        }
                        
                        obj_achivements.alarm[0] = 60;
                        obj_achivements.revivalLast = true;
                        
                        if(obj_achivements.revivals >= 1 && room != room_fartzone && !obj_achivements.achivements[3])
                        {
                                obj_achivements.achivements[3] = true;
                                obj_achivements.mercoins += 25;
                                obj_achivements.save();
                                obj_achivements.save();
                                
                                obj_achivements.show();
                        }
                        
                        if(obj_achivements.revivals >= 2 && room != room_fartzone && !obj_achivements.achivements[4])
                        {
                                obj_achivements.achivements[4] = true;
                                obj_achivements.mercoins += 50;
                                obj_achivements.save();
                                obj_achivements.save();
                                
                                obj_achivements.show();
                        }
                        
                        if(obj_achivements.revivals >= 3 && room != room_fartzone && !obj_achivements.achivements[6])
                        {
                                obj_achivements.achivements[6] = true;
                                obj_achivements.mercoins += 200;
                                obj_achivements.save();
                                obj_achivements.save();
                                
                                obj_achivements.show();
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_REVIVAL_STATUS:
                {
                        if(isPasstrough)
                                break;

                        var _status = buffer_read_s(rbuff, buffer_bool);
                        var _pid = buffer_read_s(rbuff, buffer_u16);

                        with(obj_revival_puppet)
                        {
                                if(master_id != _pid)
                                        continue;

                                show = _status;
                                break;
                        }

                        break;
                }

                case PacketType.SERVER_EGG_UPGRADE_STATUS:
                {
                        // v3.1 («Genio Malvado» estilo rescate): abre/cierra la
                        // BARRA de mejora de una trampa (0 sensor / 1 trampa de
                        // Amelia). Mismo papel que SERVER_REVIVAL_STATUS para el
                        // revive; la barra la dibuja la propia trampa (Draw_0,
                        // solo para el bando superviviente).
                        if(isPasstrough)
                                break;

                        var _gshow = buffer_read_s(rbuff, buffer_bool);
                        var _gtype = buffer_read_s(rbuff, buffer_u8);
                        var _gnid = buffer_read_s(rbuff, buffer_u16);

                        with(_gtype == 1 ? obj_amelia_trap : obj_eggtrack)
                        {
                                if(nid != _gnid)
                                        continue;

                                upgShow = _gshow;

                                if(!_gshow)
                                        upgProg = 0;

                                break;
                        }

                        break;
                }
                
                case PacketType.SERVER_PLAYER_DEATH_STATE:
                {
                        if(isPasstrough)
                                break;
                                
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        var _dead = buffer_read_s(rbuff, buffer_bool);
                        var _revTimes = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!_dead)
                                break;
                        
                        if(!instance_exists(obj_player_puppet))
                                break;
                                
                        if(_pid == obj_netclient.nid)
                        {
                                if(!instance_exists(global.player))
                                        break;
                        
                                global.player.revivalTimes = _revTimes;         
                                global.player.shards = 0;
                                obj_achivements.rShardsCollected = 0;
                                break;
                        }
                        
                        with(obj_player_puppet)
                        {
                                if(master_id != _pid)
                                        continue;
                                        
                                shards = 0;
                                break;
                        }
                        break;
                }
                
                case PacketType.SERVER_RESULTS:
                {
                        lvlId = buffer_read_s(rbuff, buffer_u8);
                        
                        // FIX LMS musica de mapa (v1): en "...", Wood Zone y
                        // Act9 la musica del mapa es un loop directo que no
                        // se muere solo con el cambio de room — sin esto se
                        // colaba ENCIMA de la musica del ending.
                        scr_stop_map_music();
                        
                        // v69 (BOTAS) — RESTAURADO EN v72: mismo corte antes de
                        // ir a la room de resultados (que pone su musica de
                        // ending): apagar el loop de botas y devolver el
                        // volumen de la musica.
                        audio_stop_sound(snd_speedboost);
                        scr_music_unduck();
                        
                        gameEnds = true;
                        isReady = true;
                        state = STATE_RESULTS;

                        // v14 (NEGAGEN, RESULTADOS): fotografia del "quien es
                        // NEGA" justo antes de salir de la sala. El server
                        // reporta a los subditos negativos como demonizados
                        // (PLRSTATE 1: revivalTimes >= 2) y el paquete de
                        // resultados NO lleva la marca negatouch — sin esta
                        // foto pintarian con el retrato demon de scr_hud_demon
                        // ("aparecian como si fueran exes"). Los puppets y el
                        // global.player aun existen AQUI (la sala muere al
                        // final del evento, con el room_goto de abajo): se
                        // vuelvan sus nicks a una lista GLOBAL y la consulta
                        // net_state_results en la sala nueva.
                        // v16 (FIX CRASH): el mismo is_ds_list invalido de v14
                        // estaba AQUI arriba: en la SEGUNDA ronda de la misma
                        // sesion la lista ya existe (!= noone), el cortocircuito
                        // no salva y el runtime revienta al leer la "variable"
                        // is_ds_list. Check correcto: ds_exists (patron de
                        // obj_netclient.players con ds_type_map, linea ~3824).
                        if(variable_global_exists("resultsNegaNicks")
                        && global.resultsNegaNicks != noone
                        && ds_exists(global.resultsNegaNicks, ds_type_list))
                                ds_list_destroy(global.resultsNegaNicks);

                        global.resultsNegaNicks = ds_list_create();

                        // el jugador LOCAL (su propia marca negatouch; el nick
                        // es el MISMO string que envia el server en resultados)
                        if(instance_exists(global.player)
                        && variable_instance_exists(global.player.id, "isNegatouch")
                        && global.player.isNegatouch)
                        {
                                // v15 (FIX): el server JAMAS manda la entrada del
                                // jugador LOCAL a su propio mapa players
                                // (CLIENT_LOBBY_PLAYERS_REQUEST se salta al peer
                                // propio y SERVER_PLAYER_JOINED se emite con
                                // broadcast_ex ignorandolo), asi que el lookup de
                                // abajo era SIEMPRE falso y el negativo local no
                                // entraba en la lista: en SU pantalla su propia
                                // fila pintaba con el retrato demon. El nick
                                // correcto es global.nickname — el MISMO string
                                // que este cliente mando en el paquete de
                                // identidad y que el server devuelve en resultados.
                                var _ownNick = "";
                                if(variable_global_exists("nickname") && global.nickname != "")
                                        _ownNick = global.nickname;

                                // red de seguridad por si un futuro server si
                                // reflejara la entrada propia (prioridad al map)
                                if(_ownNick == "" && ds_map_exists(obj_netclient.players, obj_netclient.nid))
                                {
                                        var _own = obj_netclient.players[? obj_netclient.nid];
                                        if(!is_undefined(_own) && variable_struct_exists(_own, "nickname"))
                                                _ownNick = _own.nickname;
                                }

                                if(_ownNick != "")
                                        ds_list_add(global.resultsNegaNicks, _ownNick);
                        }

                        // el resto: cada puppet de ESTE cliente lleva la marca
                        // (la conversion/invocacion la escribio por broadcast)
                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(variable_instance_exists(id, "isNegatouch")
                                        && isNegatouch && nickname != "")
                                                ds_list_add(global.resultsNegaNicks, nickname);
                                }
                        }

                        room_goto(room_results);
                        return true;
                }
                
                case PacketType.CLIENT_CHAT_MESSAGE:
                {
                        // [v1.2 IN-GAME CHAT] chat dentro de la partida, SOLO
                        // supervivientes: el server (Game.c, mod v1.2)
                        // reenvia cada mensaje a los jugadores de la ronda
                        // MENOS al emisor (eco local) y MENOS al EXE (no
                        // ve el chat). Mismo payload que el lobby (u16
                        // nid + string msg). El HUD solo existe en los
                        // clientes supervivientes (obj_level/Create v1.2).
                        if(isPasstrough)
                                break;
                        
                        var _cid = buffer_read_s(rbuff, buffer_u16);
                        var _cmsg = buffer_read_s(rbuff, buffer_string);
                        
                        if(!instance_exists(obj_game_chat))
                                break;
                        
                        if(_cid == 0)
                        {
                                with(obj_game_chat)
                                        addMsg("(server)", _cmsg);
                                break;
                        }
                        
                        // [v1.2] el propio mensaje no se pinta aqui: el
                        // emisor ya tiene su eco local (chatClose). Defensa
                        // por si un server viejo reenvia al emisor.
                        if(_cid == obj_netclient.nid)
                                break;
                        
                        if(!ds_map_exists(players, _cid))
                                break;
                        
                        var _cnick = players[? _cid].nickname;
                        
                        // el EXE en rojo (codigo de color de scr_text_spr).
                        // Inalcanzable de normal: el server v1.2 rechaza al
                        // EXE como emisor. Queda por si se reactiva el chat
                        // del EXE mas adelante ("por ahora") o cliente mod.
                        if(_cid == exeId)
                                _cnick = "\\" + _cnick + "~";
                        
                        with(obj_game_chat)
                                addMsg(_cnick, _cmsg);
                        
                        break;
                }
        }
        
        return false;
}