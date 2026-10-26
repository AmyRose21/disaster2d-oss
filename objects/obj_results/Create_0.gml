timeMin = 0;
timeSec = 0;
index = 0;
showBlack = true;
result = 0;

// Endings por cantidad de escapados (estilo TD original):
// net_state_results cuenta 1 entrada por jugador; type 4 = ESCAPADO,
// type 1/2/3 = demonizado/muerto/vivo (todos cuentan como superviviente).
escapedCnt = 0;
survTotal = 0;

var packet = cpacket_tcp(PacketType.CLIENT_RESULTS_REQUEST);
send_server_tcp(packet);

audio_stop_all();