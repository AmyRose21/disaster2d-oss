if(!instance_exists(global.player))
        return;
        
if(!global.player.isSlow)
{
        switch(global.character)
        {
                case CHARACTER_EXE:
                {
                        // FIX v4.8.1: cada asesino tiene SUS stats (Exetior 11,
                        // Metal Amy 13...): el case plano les devolvia a TODOS
                        // las del EXE original (12) al salir de la escalera.
                        switch(global.exeCharacter)
                        {
                                case EXE_ORIGINAL:
                                        global.player.maxHSpeed = EXE_MAXSPEED;
                                        global.player.acc = EXE_ACC;
                                        break;
                                        
                                case EXE_CHAOS:
                                        global.player.maxHSpeed = CHAOS_MAXSPEED;
                                        global.player.acc = CHAOS_ACC;
                                        break;
                                        
                                case EXE_EXETIOR:
                                        global.player.maxHSpeed = EXETIOR_MAXSPEED;
                                        global.player.acc = EXETIOR_ACC;
                                        break;
                                        
                                case EXE_EXELLER:
                                        global.player.maxHSpeed = EXELLER_MAXSPEED;
                                        global.player.acc = EXELLER_ACC;
                                        break;
                                        
                                case EXE_METALAMY:
                                        global.player.maxHSpeed = METALAMY_MAXSPEED;
                                        global.player.acc = METALAMY_ACC;
                                        break;
                        }
                        
                        break;
                }
                
                case CHARACTER_TAILS:
                {
                        global.player.maxHSpeed = TAILS_MAXSPEED;
                        global.player.acc = TAILS_ACC;
                        break;
                }
                
                case CHARACTER_KNUX:
                {
                        global.player.maxHSpeed = KNUX_MAXSPEED;
                        global.player.acc = KNUX_ACC;
                        break;
                }
                
                case CHARACTER_EGGMAN:
                {
                        global.player.maxHSpeed = EGGMAN_MAXSPEED;
                        global.player.acc = EGGMAN_ACC;
                        break;
                }
                
                case CHARACTER_AMY:
                
                case CHARACTER_AMY_CANON:
                {
                        global.player.maxHSpeed = AMY_MAXSPEED;
                        global.player.acc = AMY_ACC;
                        break;
                }
                
                case CHARACTER_SALLY:
                
                // FIX v4.8.1: mismos stats que Sally (patron de
                // scr_player_slow / Alarm_4 de obj_sally_canon)
                case CHARACTER_SALLY_CANON:
                {
                        global.player.maxHSpeed = SALLY_MAXSPEED;
                        global.player.acc = SALLY_ACC;
                        break;
                }
                
                case CHARACTER_CREAM:
                
                // FIX v4.8.1: vuela como Cream (su Alarm_4 restaura
                // CREAM_MAXSPEED/CREAM_ACC)
                case CHARACTER_VANILLA:
                {
                        global.player.maxHSpeed = CREAM_MAXSPEED;
                        global.player.acc = CREAM_ACC;
                        break;
                }
                
                // FIX v4.8.1 — EL BUG GORDO DEL MAPA: la escalera de esta
                // sala (obj_dotdotdot_shitladder) clava maxHSpeed = 7 al
                // tocarla, y ESTE switch era el unico que lo devolvia al
                // salir. Sin case, los 7 personajes anadidos (Sonic, Sally
                // Canon, Vanilla, Metal, Amelia, Blaze y Fleetway Amy)
                // se quedaban PERMANENTEMENTE a velocidad 7 (menos de la
                // mitad de su carrera) con solo rozar la escalera.
                case CHARACTER_SONIC:
                {
                        global.player.maxHSpeed = SONIC_MAXSPEED;
                        global.player.acc = SONIC_ACC;
                        break;
                }
                
                case CHARACTER_METAL:
                {
                        global.player.maxHSpeed = METAL_MAXSPEED;
                        global.player.acc = METAL_ACC;
                        break;
                }
                
                case CHARACTER_AMELIA:
                {
                        global.player.maxHSpeed = AMELIA_MAXSPEED;
                        global.player.acc = AMELIA_ACC;
                        break;
                }
                
                case CHARACTER_BLAZE:
                {
                        global.player.maxHSpeed = BLAZE_MAXSPEED;
                        global.player.acc = BLAZE_ACC;
                        break;
                }
                
                case CHARACTER_FLEETWAY_AMY:
                {
                        global.player.maxHSpeed = FW_MAXSPEED;
                        global.player.acc = FW_ACC;
                        break;
                }
        }
}