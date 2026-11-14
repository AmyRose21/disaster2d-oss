visible = false;
image_angle = 0;
image_speed = 0.2;

if(!instance_exists(obj_tails))
{
        instance_destroy();
        return;
}

x = obj_tails.x;
y = obj_tails.y;
depth = obj_tails.depth+1;

// v20 (portales de Jinna): al ser ABSORBIDA la victima su cuerpo se
// oculta (obj_jinna_absorb / SERVER_JINNA_MINION_DOWN ponen
// obj_tails.visible = false), pero las colas son un objeto APARTE y
// seguian dibujandose flotando en el punto de la captura. Se esconden
// junto con el cuerpo.
if(!obj_tails.visible)
        return;

// v20: el sprite de HURT del nega es spr_tailsnega_hurt — sin este
// check las colas se quedaban puestas durante el hurt del subdito
// negativo (el check solo conocia el del superviviente y el del demon).
if(obj_tails.sprite_index == spr_tails_hurt || obj_tails.sprite_index == spr_tailsnega_hurt)
        return;

if(obj_tails.sprite_index == spr_etails_hurt)
        return;

if(obj_tails.state == BALANCING)
{
        image_xscale = obj_tails.edgeDir;
        x += image_xscale * 4;
        y += 8;

        visible = true;
        // v20 (3 formas): 1 normal / 2 NEGA / 3 demonizada. Antes la eleccion
        // solo miraba revivalTimes >= 2 (vivo/muerto) y el nega heredaba las
        // colas DEMON del esbirro comun.
        sprite_index = scr_negatouch_is(obj_tails) ? spr_tailsnega_tail1 : (obj_tails.revivalTimes >= 2 ? spr_etails_tail1 : spr_tails_tail1);
        return;
}

if(obj_tails.state == IDLE || obj_tails.emotion || obj_tails.state == LOOKDOWN ||obj_tails.state == LOOKUP)
{
        image_xscale = obj_tails.image_xscale;

        x += image_xscale * 2;
        y += 4;

        visible = true;
        sprite_index = scr_negatouch_is(obj_tails) ? spr_tailsnega_tail2 : (obj_tails.revivalTimes >= 2 ? spr_etails_tail2 : spr_tails_tail2);
        return;
}

if(obj_tails.state == JUMP || obj_tails.state == SPIN)
{
        y += 6;
        image_xscale = 1;
        visible = true;
        image_angle = -radtodeg(arctan2(obj_tails.yspd, obj_tails.isGrounded ? obj_tails.gspd : obj_tails.xspd));
        sprite_index = scr_negatouch_is(obj_tails) ? spr_tailsnega_tail1 : (obj_tails.revivalTimes >= 2 ? spr_etails_tail1 : spr_tails_tail1);
}
