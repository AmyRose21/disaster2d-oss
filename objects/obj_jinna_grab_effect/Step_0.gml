if(locked && instance_exists(global.player))
{
        if(timer > 0)
        {
                timer--;

                // quitar el control UNA sola vez (si la ronda no lo habia
                // quitado ya: gameEnds / fin de ronda)
                if(!tookControl && global.playerControls && !obj_netclient.gameEnds)
                {
                        tookControl = true;
                        global.playerControls = false;
                }

                // ademas frenar en seco cada frame (por si venia con impulso)
                with(global.player)
                {
                        gspd = 0;
                        xspd = 0;
                        isJumping = false;
                        isAttacking = false;
                }
        }
        else
                release_control();
}

/// devuelve el control si lo retenemos nosotros (patron finishGrab)
function release_control()
{
        if(tookControl)
        {
                tookControl = false;

                if(!obj_netclient.gameEnds)
                        global.playerControls = true;
        }
}
