#macro BUILD_VER 1101

// Client stuff
isConnected = false;
isReady = false;
isServerReady = false;
nid = -1;

// Operador del server: lo setea el server al conectarte
// (SERVER_OPERATOR_STATE, ver net_tcpprocess) y al darte .op.
// Se resetea por conexion para no arrastrar el estado de otro
// server. Desbloquea Sonic y Sally Canon (ver scr_char_locked).
global.isOperator = false;
frame = 0;
gameEnds = false;
reconnAttempts = 0;
want_lobby = -1;

buffer = buffer_create(256, buffer_fixed, 1);
ip = "";
port = 8606;
// The port typed in the join box, remembered so that a reconnect or a
// lobby change goes back to the same server rather than to the default.
base_port = 8606;
ping = 0;
udp_timeout = 60 * 5;

state = STATE_PENDING;
sendTimeout = 60;
isInit = false;

// Lobby
exeId = 0;
chance = 0;

// Game
lvlId = -1;
pings = ds_map_create();

players = ds_map_create();
avCharacters = 
[ 
        false, //0 (exe) (cannot)
        true,  //1 (tails)
        true,
        true,
        true,
        true,
        true,
        true,  //7 (amy canon)
        true,  //8 (sonic)
        true   //9 (sally canon)
];

depth = -9999999;