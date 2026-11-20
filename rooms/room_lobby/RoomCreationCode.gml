// v41 (MUSICA LOBBY): mus_lobby_1 -> lobby_force (nueva musica del lobby;
// suena al entrar al lobby y al volver a el tras una partida, porque la room
// se recrea en cada vuelta — net_state_game / net_tcpprocess / net_state_pending).
scr_play_music(lobby_force);
global.palleteFrom = [ #000000 ];
global.palleteTo = [ #000000 ];