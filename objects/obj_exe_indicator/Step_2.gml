if(!instance_exists(global.player))
        return;

target = noone;
redRings = false;
scanCount = 0;

if(instance_exists(obj_player_puppet))
{
        var dist = 999999999;
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
                var inst = instance_find(obj_player_puppet, i);
                
                if(inst.hp <= 0 || inst.revivalTimes >= 2)
                        continue;
                        
                // v2.13 (LUNA de Sol y Luna): velo de gracia de Amelia oculta.
                // Durante los primeros 3 s tras ocultarse, ni el indicador ni los
                // sensores del EXE la marcan (como si se hubiera esfumado); pasado
                // el velo vuelve a ser indicable (su cuerpo jamas: invisible EXE).
                if(inst.character == CHARACTER_AMELIA && inst.isHiding && inst.lunaGrace > 0)
                        continue;
                
                if(inst.hasRedRing && (global.character != CHARACTER_EXE || global.player.invisTimer <= 0))
                {
                        redRings = true;
                        target = inst;
                        break;
                } 
                
                if(dist > point_distance(global.player.x, global.player.y, inst.x, inst.y))
                {
                        dist = point_distance(global.player.x, global.player.y, inst.x, inst.y);
                        target = inst;
                }
        }
        
        if(target != noone)
                image_angle = point_direction(global.player.x, global.player.y, target.x, target.y);
}

// FIX SCAN v4.9: la condicion de la AGUJA (invisibilidad del EXE /
// anillo rojo / slime de Chaos) pasa a la bandera propia `needle`. Antes
// vivia en `visible`, la variable del MOTOR, y ahi estaba el bug del scan:
// el indicador nace visible:false (el .yy) y para Metal Amy esta linea daba
// false SIEMPRE (es el bando EXE, no usa invisibilidad, no es Chaos, sin
// anillo rojo) — y una instancia invisible NO ejecuta su Draw GUI en este
// runtime, asi que las siluetas del scan nunca se dibujaban (la v4.8.1
// arreglo el gate que llena la lista, pero el evento de dibujo segua sin
// correr). `visible` ahora solo es el interruptor del MOTOR y la enciende
// el final del Step_2 con la aguja O el scan activo.
needle = (global.character != CHARACTER_EXE || global.player.invisTimer > 0 || (global.exeCharacter == 1 && global.player.slimeTimer > 0)) || redRings;

// v4.8 (SCAN de Metal Amy): mientras dura el revelado, UNA referencia por
// cada superviviente VIVO (la aguja normal de arriba solo marca al mas
// cercano o al del anillo rojo). Mismos filtros que arriba: muertos y
// esbirros fuera, y el velo de gracia de Amelia tambien esconde aqui.
// Solo corre en el cliente del Metal Amy (la instancia la crea su
// Create_0) y es TODO local: los puppets ya viajan sincronizados, cero
// paquetes nuevos. El Draw_64 dibuja cada silueta A TRAVES de paredes y
// escondites — «vision de supervivientes», no agujas indicadoras — y las
// que caen fuera de la vista quedan fijadas al borde de la pantalla.
// FIX v4.8.1: el viejo variable_instance_exists(global.player, "scanTimer")
// recibia el INDICE del objeto (global.player = obj_metalamy) en vez del
// id de la instancia: esa funcion SOLO acepta ids de instancia (por eso
// obj_ghz_water usa global.player.id), asi que devolvia false SIEMPRE y
// la lista nunca se llenaba -> el scan no se veia ni con la V ni con la
// pasiva de la cazadora. El gate de exeCharacter ya garantiza que el
// jugador es obj_metalamy (su Create_0 define scanTimer): basta
// instance_exists, que si acepta el indice del objeto.
if(global.character == CHARACTER_EXE
&& global.exeCharacter == EXE_METALAMY
&& instance_exists(global.player)
&& instance_exists(obj_player_puppet)
&& global.player.scanTimer > 0)
{
        with(obj_player_puppet)
        {
                // FIX v4.8.1: tambien fuera los desconectados (isInactive):
                // su puppet se queda congelado con la ultima hp viva y
                // ensuciaba el revelado (y el conteo de la cazadora).
                if(isInactive || hp <= 0 || revivalTimes >= 2)
                        continue;

                if(character == CHARACTER_AMELIA && isHiding && lunaGrace > 0)
                        continue;

                other.scanList[other.scanCount] = id;
                other.scanCount++;
        }
}

// FIX SCAN v4.9 — EL INTERRUPTOR DEL MOTOR: mientras haya aguja que
// senalar O revelado que dibujar, la instancia se hace VISIBLE para que
// el motor corra su Draw GUI (la aguja la dibuja el bloque de abajo del
// Draw_64 con su propia bandera `needle`, asi el scan no arrastra la
// flecha consigo). Sin aguja y sin scan vuelve a false y el evento
// deja de correr: cero costo en el frame comun.
visible = needle || scanCount > 0;