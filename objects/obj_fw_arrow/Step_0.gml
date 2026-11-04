// v2.15 («La Torre»): vida de la plataforma. El despawn autoritativo
// es el server (arrowDrop via SERVER_FWBOLT_STATE 2); el timer local
// cubre un paquete perdido. Al caer: se desprende con un quickeffect
// para que no desaparezca de golpe.
if(arrowDrop)
{
        arrowTimer -= 6;
}
else
{
        arrowTimer--;
}

if(arrowTimer <= 0)
{
        net_quick_effect(x, y, spr_dust, false, 1, 0, -1);
        instance_destroy();
}
