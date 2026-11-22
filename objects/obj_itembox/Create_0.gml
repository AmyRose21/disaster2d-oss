// v63 ITEM BOX v3 — estado base. Clon del convenio obj_kaf_speedboobster
// (nid/isBroken/emitter con falloff 250-500) mas el byte de tipo que
// difunde el servidor. La posicion la marca el paquete de spawn (el
// servidor es la unica verdad de posicion — nada de instance_find).
// v63 GRAVEDAD: la caja nace CAYENDO (grounded=false) y el Step la
// clava al suelo (regla de la duena: como los juegos clasicos). Los
// spawners v64 nacen APOYADOS (y = top del suelo - 30): la caida es un
// micro-descenso de cortesia, pero nunca vuelve a ver una caja flotando.
nid = 0;
type = 0;          // ITEMTYPE_* (0=ring,1=shield,2=invinc,3=lightning,4=boots)
isBroken = false;
grounded = false; // v63: false = cayendo (el Step la apoya y clava)
vspd = 0;         // v63: velocidad de caida (gravedad 0.2 de la casa)
reported = false; // v63: CLIENT_BOX_RELOCATE ya enviado (anti-spam 1x)

// v64 FIX DIMINUTA: la escala 0.47 del v63 se aplicaba AQUI (a la caja
// VIVA tambien) — por eso se veia diminuta en pantalla (VLM la midio
// ~16px contra los ~24-30 que debe medir). La caja viva va SIEMPRE a
// escala 1.0; el 0.47 es cosa del ESTADO 2 (net_state_game) cuando la
// caja se rompe y su sprite pasa a spr_boxused (64x64 con el contenido
// abajo): ahi si, el residuo a 0.47 ocupa ~30px como la caja viva.
image_xscale = 1;
image_yscale = 1;

// v63: reporte de relocalizacion (trampolin/abismo) — patron del paquete
// del juego (cpacket_tcp + send_server_tcp). UNA sola vez (reported).
report_relocate = function()
{
	reported = true;

	var pack = cpacket_tcp(PacketType.CLIENT_BOX_RELOCATE);
	buffer_write(pack, buffer_u8, nid);
	send_server_tcp(pack);

	// esconder YA la instancia local: el server difundira el despawn
	// (state 4) y el re-spawn en otro punto; mientras tanto no se ve
	// una caja cayendo al vacio en bucle.
	visible = false;
};

emitter = audio_emitter_create();
audio_emitter_falloff(emitter, 250, 500, 1);