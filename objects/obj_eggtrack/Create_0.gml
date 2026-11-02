activated = false;
nid = 0;
state = 0;
upgraded = false; // v3.0 «Genio Malvado»: llega con el state 2 del server
// v3.1 (estilo RESCATE de Vanilla): barra de mejora del Genio —
// upgShow/upgProg llegan del server (SERVER_EGG_UPGRADE_STATUS /
// SERVER_EGG_UPGRADE_PROGRESS) y upgOver es el prompt para el Eggman
// local (1 = puede pagar, 0 = faltan anillos), patron reviveObj.
upgShow = false;
upgProg = 0;
upgOver = -1;

if(room == room_act9)
        image_blend = c_dkgray;
