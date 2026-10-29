// CARRY (v1): controlador de la mecanica de LLEVAR ALIADOS VOLANDO
// (Tails/Cream con un compañero colgando, estilo liana/tirolina).
// No dibuja nada: solo corre la logica (scripts/scr_carry.gml) en su
// End Step. Lo crea obj_spawnpoint cada ronda en cada cliente
// superviviente, DESPUES de crear al jugador: asi su End Step corre
// despues del End Step del jugador y el snap al portador es la
// ultima palabra sobre la posicion del frame (igual que la tirolina).
carryInst = noone;
