if(!instance_exists(obj_menu))
	return;

// ============================================================================
// v4.2 - FIX DEL CRASH "Variable set failed text - read only variable?"
// ----------------------------------------------------------------------------
// Ese error salia en ESTE evento (linea de special3) cuando el
// room_menu.yy del proyecto no trae la fila SPECIAL 3 (le pasa a quien
// importa solo los .gml y no la room): findTextpanel("special3")
// devolvia noone y asignarle .text petaba. Aqui la fila se AUTO-CREA
// por codigo ANTES de leerla, colocada ABAJO DE SPECIAL 2 (pedido del
// usuario): la fila de HIDE GUI baja un puesto y SPECIAL 3 ocupa el
// suyo. Cubre los TRES estados posibles del proyecto:
//   * room sin la fila (la de ahora)  -> la crea completa
//   * room de la v4.1 (fila al final, debajo de HIDE GUI) -> la REORDENA
//   * room de la v4.2 (fila bien puesta) -> no toca nada
// ============================================================================
var _sp3 = obj_menu.findTextpanel("special3");

if(_sp3 == noone)
{
        // Room muy vieja sin la capa: se crea con su depth original (-1500),
        // oculta igual que como la deja el changeSubmenu del arranque
        if(!layer_exists("OptionsControls"))
        {
                var _l3 = layer_create(-1500, "OptionsControls");
                layer_set_visible(_l3, false);
        }

        // Panel de la tecla (mismo sitio que las demas filas de su columna)
        _sp3 = instance_create_layer(332, 104, "OptionsControls", obj_menu_textpanel);
        _sp3.tid = "special3";
}
else if(_sp3.y == 121)
{
        // room de la v4.1: la fila quedo debajo de HIDE GUI; sube un puesto
        _sp3.y = 104;
}

// Placa SPECIAL 3 (boton del bind): frame 67 de spr_menu_buttons. Si el
// sprite quedo viejo (67 frames), se cae al 20 ("SPECIAL 2") igual que
// el respaldo del frame 66 de obj_menu/Alarm_0: la fila nunca queda sin
// placa. Importa la carpeta del sprite para el label correcto.
var _bt3 = noone;
with(obj_menu_button)
{
        if(submenu == 3 && bcolumn == 2 && bid == 4)
        {
                _bt3 = self;
                break;
        }
}

if(_bt3 == noone)
{
        _bt3 = instance_create_layer(356, 111, "OptionsControls", obj_menu_button);
        _bt3.bid = 4;
        _bt3.bcolumn = 2;
        _bt3.submenu = 3; // SUBMENU_OPTIONSCONTROLS
        _bt3.image_speed = 0;
        _bt3.image_index = sprite_get_number(spr_menu_buttons) > 67 ? 67 : 20;
}
else if(_bt3.y == 128)
{
        // room de la v4.1: la placa quedo abajo; sube a su sitio
        _bt3.y = 111;
        _bt3.sY = 111;
}

// La fila HIDE GUI baja un puesto para hacerle sitio (y su boton
// con ella: sin tocar sY el Step del boton lo devolveria a su y original)
var _hg = obj_menu.findTextpanel("hidegui");
if(_hg != noone && _hg.y == 104)
        _hg.y = 121;

with(obj_menu_button)
{
        if(submenu == 3 && bcolumn == 1 && bid == 3 && y == 111)
        {
                y = 128;
                sY = 128;
        }
}

obj_menu.findButton("ping").state = showPing;
obj_menu.findButton("fps").state = showFps;
obj_menu.findTextbox("ip").text = ip;
obj_menu.findTextbox("ip_mobile").text = ip;
obj_menu.findTextbox("nickname").text = global.nickname;
obj_menu.findTextpanel("left").text = scr_controls_keycode_to_key(global.KeyLeft);
obj_menu.findTextpanel("right").text = scr_controls_keycode_to_key(global.KeyRight);
obj_menu.findTextpanel("up").text = scr_controls_keycode_to_key(global.KeyUp);
obj_menu.findTextpanel("down").text = scr_controls_keycode_to_key(global.KeyDown);
obj_menu.findTextpanel("jump").text = scr_controls_keycode_to_key(global.KeyA);
obj_menu.findTextpanel("special1").text = scr_controls_keycode_to_key(global.KeyB);
obj_menu.findTextpanel("special2").text = scr_controls_keycode_to_key(global.KeyC);
obj_menu.findTextpanel("special3").text = scr_controls_keycode_to_key(global.KeyV);
obj_menu.findTextpanel("playerlist").text = scr_controls_keycode_to_key(global.KeyPList);
obj_menu.findTextpanel("emotion1").text = scr_controls_keycode_to_key(global.KeyEm1);
obj_menu.findTextpanel("emotion2").text = scr_controls_keycode_to_key(global.KeyEm2);
obj_menu.findTextpanel("emotion3").text = scr_controls_keycode_to_key(global.KeyEm3);
obj_menu.findTextpanel("emotion4").text = scr_controls_keycode_to_key(global.KeyIdle);
obj_menu.findTextpanel("hidegui").text = scr_controls_keycode_to_key(global.KeyHide);
