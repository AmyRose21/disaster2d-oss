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
        {
                // v4.1 — EMPUJON DE SALIDA: al soltarla, la victima sale
                // lanzada en la direccion del agarre (image_xscale = dir
                // que viajo en el paquete). Antes la dejabamos parada en
                // el mismo sitio; el lock frena cada frame, asi que el
                // shove SOLO puede vivir aqui, al terminar el bloqueo
                // (mismo impulso estandar de la casa: xpw 4 / ypw -6).
                with(global.player)
                {
                        xspd = 4 * other.image_xscale;
                        yspd = -6;
                        isGrounded = false;
                }

                release_control();
        }
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
