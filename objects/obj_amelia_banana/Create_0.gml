// =====================================================================
//  v2.2 — AMELIA: BANANA (trampa-resorte, cliente). En TTB era
//  obj_amelia_banana con parent obj_spring_parent y sprite
//  spr_spring_up: literalmente un resorte colocable. El rebote lo
//  aplica el sistema de resortes estandar (scr_collision_objects_
//  after) sobre el jugador LOCAL de cada cliente: quien la pise
//  (killer incluido) sale disparado hacia arriba en su propio
//  cliente y su posicion se sincroniza sola.
//  La entidad vive en el SERVER (entities/AmeliaBanana.c): a los 12 s
//  la retira y avisa con SERVER_AMELIA_BANANA_STATE 1.
// =====================================================================
xdir = 0;
ydir = -12;
image_speed = 0;
