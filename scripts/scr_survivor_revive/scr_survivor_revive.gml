function scr_survivor_revive()
{
        if(!instance_exists(global.player))
                return;
                
        // BURBUJA DE SECUESTRO (Amy Canon): mientras esta secuestrada NO
        // se muestra el prompt de revivir ni se envian paquetes de revive.
        // Ella no esta muerta (se salto la agonia): esta atrapada, y se
        // libera tocandola un companero, no reviviendola con anillos.
        if(character == CHARACTER_AMY_CANON)
        {
                if(state >= AMY_CANON_CAPTURE && state <= AMY_CANON_CAPTURE_R)
                {
                        reviveObj.over = -1;
                        reviveObj.show = false;
                        return;
                }
        }
                
        if(hp > 0)
        {
                reviveObj.over = -1;
                reviveObj.show = false;
                return;
        }
        
        if(revivalTimes != 0 || isDemonized)
        {
                reviveObj.over = -1;
                reviveObj.show = false;
                return;
        }
        
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
        {
                reviveObj.over = -1;
                return;
        }
        
        if(global.player.hp <= 0)
        {
                reviveObj.over = -1;
                return;
        }
        
        if(place_meeting(x, y, global.player))
        {       
                reviveObj.over = global.player.rings >= 3 ? 1 : 0;
                        
                if(global.playerControls && global.player.isLookingDown)
                {
                        if(global.player.rings >= 3)
                        {
                                var pak = cpacket_tcp(PacketType.CLIENT_REVIVAL_PROGRESS, false);
                                buffer_write(pak, buffer_u16, master_id);
                                buffer_write(pak, buffer_u8, global.player.rings - 3);
                                send_server_tcp(pak);   
                        }
                }
        }
        else 
                reviveObj.over = -1;
}