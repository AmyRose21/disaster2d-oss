#macro BUILD_VER 1101

// Client stuff
isConnected = false;
isReady = false;
isServerReady = false;
nid = -1;

// Operador del server: lo setea el server al conectarte
// (SERVER_OPERATOR_STATE, ver net_tcpprocess) y al darte .op.
// Se resetea por conexion para no arrastrar el estado de otro
// server. Desbloquea a Sally Canon (ver scr_char_locked).
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

// v3/v4 (D.I.B.) — estado de JINNA (persistentes durante la partida; el
// reset por ronda lo hace obj_level/Create_0): la ventana de poder del
// teleport (frames) y el nivel de potenciacion del portal trampa.
// Se declaran aqui para que existan desde el arranque (antes del primer
// obj_level) en todos los clientes.
global.jinnaTelePower = 0;
global.jinnaCaughtTier = JINNA_CAUGHT_NONE; // v4: 0 = nadie / 1 = Amy Canon (mejoras arduas) / 2 = Vanilla (fuertes)

// Slots de personajes libres/ocupados. Se dimensiona SOLO segun
// los macros de personaje: ver scr_characters (scr_avchars_reset).
// Leer/escribir solo con scr_avchar_get / scr_avchar_set.
avCharacters = scr_avchars_reset();

depth = -9999999;