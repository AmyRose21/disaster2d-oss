// =====================================================================
//  v52 — SUPER AMY CANON: HAMMER THROW (el martillo lanzado, tecla C
//  EN TIERRA con la super activa). Este objeto es el PROYECTIL: vuela
//  RECTO hacia adelante con el SPRITEROLL (image_angle: el martillo
//  rueda sobre si mismo durante todo el vuelo, como debe hacer cualquier
//  martillo lanzado) y se retira al tocar un muro o el borde del mapa.
//
//  SCOPE (prueba local de la v51): la super forma TODAVIA no viaja por
//  red — el martillo vive SOLO en el cliente de Amy (nadie mas lo ve
//  volar). Cuando la super sincronice (su ronda), el martillo viajara
//  con ella. Lo que SI llega a todos HOY es el GOLPE: al tocar a un
//  puppet del bando EXE (exe real o esbirro demonizado) se manda la
//  SENAL de stun como snd_none posicionado EN el nid de la victima
//  (net_sound_emit_at — la rama shouldPlay del CLIENT_SOUND_EMIT la
//  traduce en SU cliente a scr_amy_super_hammer_signal: el modelo de
//  confianza del parry / Chocola / LSA, cero paquetes nuevos). El stun
//  dura 3.5 s (AMY_SUPER_HTHROW_STUN) e IGNORA i-frames: aunque el
//  objetivo ya este inmune o aturdido, el martillo lo aturde igual
//  (mismo criterio que la patada duelista de Sally Canon).
//
//  Macros ajustables en obj_amy_canon/Create_0.gml:
//  AMY_SUPER_HTHROW_SPEED (velocidad), _SPIN (giro), _STUN (duracion).
// =====================================================================
dir = 1;             // 1 = vuela a la DERECHA, -1 = a la izquierda (lo fija el lanzador)
life = 240;          // failsafe de vuelo maximo (4 s a 60 fps)

sprite_index = spr_martillo_de_amy;
image_speed = 0;     // 1 frame: el giro es image_angle (el spriteroll), no frames
image_xscale = 1;    // SIEMPRE tal cual: el sprite RUEDA, nunca se espeja
image_angle = 0;