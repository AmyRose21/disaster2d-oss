// el efecto muere (fin natural o cambio de room): devolver el control
// si todavia lo retenemos (patron finishGrab del mod original)
if(tookControl && instance_exists(obj_netclient) && !obj_netclient.gameEnds)
        global.playerControls = true;
