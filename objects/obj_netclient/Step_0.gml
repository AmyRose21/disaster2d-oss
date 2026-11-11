if(!isConnected)
        return;

if(!instance_exists(obj_level) || gameEnds || !isServerReady)
{
        udp_timeout = 60 * 5;
        return;
}

// v3 (D.I.B.): ventana de poder del teleport de JINNA (3 s tras
// aterrizar): corre en TODOS los clientes (la abren los portales del
// server) y aqui baja un frame por paso. El reset de ronda lo hace
// obj_level/Create_0.
if(global.jinnaTelePower > 0)
        global.jinnaTelePower--;

if(udp_timeout-- <= 0)
{
        if(gameEnds)
                return;
        
        global.errorCode = 4;
        room_goto(room_message);
}