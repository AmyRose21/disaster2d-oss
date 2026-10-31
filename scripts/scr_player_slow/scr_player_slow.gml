function scr_player_slow(time)
{
        if(!instance_exists(global.player))
                return;
                
        switch(global.character)
        {
                case CHARACTER_EXE:
                        global.player.isSlow = true;
                        global.player.acc = (EXE_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (EXE_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;
                        
                case CHARACTER_TAILS:
                        global.player.isSlow = true;
                        global.player.acc = (TAILS_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (TAILS_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;
                        
                        
                case CHARACTER_KNUX:
                        global.player.isSlow = true;
                        global.player.acc = (KNUX_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (KNUX_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;
                        
                        
                case CHARACTER_EGGMAN:
                        global.player.isSlow = true;
                        global.player.acc = (EGGMAN_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (EGGMAN_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;
                        
                case CHARACTER_AMY:
                        
                case CHARACTER_AMY_CANON:
                        global.player.isSlow = true;
                        global.player.acc = (AMY_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (AMY_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;
                        
                case CHARACTER_SALLY:
                
                case CHARACTER_SALLY_CANON:
                        global.player.isSlow = true;
                        global.player.acc = (SALLY_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (SALLY_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;
                        
                case CHARACTER_CREAM:

                case CHARACTER_VANILLA: // mismas stats que Cream
                        global.player.isSlow = true;
                        global.player.acc = (CREAM_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (CREAM_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;

                // v2.4: faltaba Sonic desde siempre (la trampa de Amelia
                // y el eggtrack no le aplicaban slow a un Sonic demonizado)
                case CHARACTER_SONIC:
                        global.player.isSlow = true;
                        global.player.acc = (SONIC_ACC * (100-40)) / 100;
                        global.player.maxHSpeed = (SONIC_MAXSPEED * (100-40)) / 100;
                        global.player.alarm[4] = 60 * time;
                        
                        break;
                        
                        // v2.2 (TTB): stats de los rescatados
                        case CHARACTER_METAL:
                                global.player.isSlow = true;
                                global.player.acc = (METAL_ACC * (100-40)) / 100;
                                global.player.maxHSpeed = (METAL_MAXSPEED * (100-40)) / 100;
                                global.player.alarm[4] = 60 * time;
                                break;
                        
                        case CHARACTER_AMELIA:
                                global.player.isSlow = true;
                                global.player.acc = (AMELIA_ACC * (100-40)) / 100;
                                global.player.maxHSpeed = (AMELIA_MAXSPEED * (100-40)) / 100;
                                global.player.alarm[4] = 60 * time;
                                break;
                        
                        case CHARACTER_BLAZE:
                                global.player.isSlow = true;
                                global.player.acc = (BLAZE_ACC * (100-40)) / 100;
                                global.player.maxHSpeed = (BLAZE_MAXSPEED * (100-40)) / 100;
                                global.player.alarm[4] = 60 * time;
                                break;
        }
}