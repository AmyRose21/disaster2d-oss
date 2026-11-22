// v63 ITEM BOX v3 — estado base. Clon del convenio obj_kaf_speedboobster
// (nid/isBroken/emitter con falloff 250-500) mas el byte de tipo que
// difunde el servidor. La posicion la marca el paquete de spawn (el
// servidor es la unica verdad de posicion — nada de instance_find).
// v63 GRAVEDAD: la caja nace CAYENDO (grounded=false) y el Step la
// clava al suelo (regla de la duena: como los juegos clasicos). Los 9
// spawners nuevos estan a <=32px del suelo asi que la caida es un
// micro-descenso visual, pero nunca vuelve a ver una caja flotando.
nid = 0;
type = 0;          // ITEMTYPE_* (0=ring,1=shield,2=invinc,3=lightning,4=boots)
isBroken = false;
grounded = false; // v63: false = cayendo (el Step la apoya y clava)
vspd = 0;         // v63: velocidad de caida (gravedad 0.2 de la casa)
reported = false; // v63: CLIENT_BOX_RELOCATE ya enviado (anti-spam 1x)

// v63 FIX RESIDUO GIGANTE: spr_boxused mide 64x64 con el contenido abajo
// (y 32-63) — dibujado tal cual se veia ENORME junto a la caja de 30x30.
// Escala 0.47: el contenido del residuo pasa a ~30x15 y el punto de
// apoyo queda en su sitio (origin 0). Aplica igual a la caja rota y al
// sprite del objeto (nunca cambia el tamano de la caja viva).
image_xscale = 0.47;
image_yscale = 0.47;

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