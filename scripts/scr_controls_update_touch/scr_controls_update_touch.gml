function scr_controls_update_touch()
{
	if(!isMobile)
		return;
		
	if(keyboard_check(ord("H")) || keyboard_check(ord("h")))
	{
		isMobile = false;
		return;
	}
	
	if(keyboard_virtual_status())
	{
		if(kbdTimer++ >= 60 * .1 && mouse_check_button(mb_any))
			keyboard_virtual_hide();
	}
	else 
		kbdTimer = 0;
	
	for (var i = 0; i < 24; i++)
	{
		var _x = device_mouse_x_to_gui(i);
		var _y = device_mouse_y_to_gui(i);
		var _state = device_mouse_check_button(i, mb_left); 
		// v80i SLOT-SANITIZE: un slot con _state true pero coordenadas todavia
		// undefined (frame en que se presiono, o mouse fisico sin datos de
		// touch) se trata como no-tocado: sin coords no hay hit-test posible
		// y _state sola no alcanza (era el unico caso que el V-GUARD v80h2
		// no cubria: crasheaba el dpad, linea 26). Cubre dpad + A..W + V.
		if(_state && (is_undefined(_x) || is_undefined(_y)))
			_state = false;
		
		if(_state && point_in_circle(_x, _y, obj_config.dpadX, obj_config.dpadY, 160) && jTouchId == -1)
			jTouchId = i;
			
		if(!jUse)
			jTouchId = -1;
		
		if(!bUse)
		{
			ATouchId = -1;
			BTouchId = -1;
			CTouchId = -1;
			DTouchId = -1;
			ETouchId = -1;
			FTouchId = -1;
			GTouchId = -1;
			WTouchId = -1;
			VTouchId = -1;
			return;
		}
		
		// A
		if(_state && point_in_circle(_x, _y, obj_config.bAX, obj_config.bAY, 40 * obj_config.bAScale))
		{
			if(ATouchId == -1)
			{
				ATouchId = i;
				APressed(true);
			}
		}
		else if(ATouchId == i)
		{
			APressed(false);
			ATouchId = -1;
		}
		
		if(!_state && ATouchId == i)
		{
			APressed(false);
			ATouchId = -1;
		}
		
		// B
		if(_state && point_in_circle(_x, _y, obj_config.bBX, obj_config.bBY, 40 * obj_config.bBScale))
		{			
			if(BTouchId == -1)
			{
				BTouchId = i;
				BPressed(true);
			}
		}
		else if(BTouchId == i)
		{
			BPressed(false);
			BTouchId = -1;
		}
		
		if(!_state && BTouchId == i)
		{
			BPressed(false);
			BTouchId = -1;
		}
		
		
		// C
		if(_state && point_in_circle(_x, _y, obj_config.bCX, obj_config.bCY, 40 * obj_config.bCScale))
		{			
			if(CTouchId == -1)
			{
				CTouchId = i;
				CPressed(true);
			}
		}
		else if(CTouchId == i)
		{
			CPressed(false);
			CTouchId = -1;
		}
		
		if(!_state && CTouchId == i)
		{
			CPressed(false);
			CTouchId = -1;
		}
		
		// D
		if(_state && point_in_circle(_x, _y, obj_config.bDX, obj_config.bDY, 22 * obj_config.bDScale))
		{			
			if(DTouchId == -1)
			{
				DTouchId = i;
				DPressed(true);
			}
		}
		else if(DTouchId == i)
		{
			DPressed(false);
			DTouchId = -1;
		}
		
		if(!_state && DTouchId == i)
		{
			DPressed(false);
			DTouchId = -1;
		}
		
		// E
		if(_state && point_in_circle(_x, _y, obj_config.bEX, obj_config.bEY, 22 * obj_config.bEScale))
		{			
			if(ETouchId == -1)
			{
				ETouchId = i;
				EPressed(true);
			}
		}
		else if(ETouchId == i)
		{
			EPressed(false);
			ETouchId = -1;
		}
		
		if(!_state && ETouchId == i)
		{
			EPressed(false);
			ETouchId = -1;
		}
		
		// F
		if(_state && point_in_circle(_x, _y, obj_config.bFX, obj_config.bFY, 22 * obj_config.bFScale))
		{			
			if(FTouchId == -1)
			{
				FTouchId = i;
				FPressed(true);
			}
		}
		else if(FTouchId == i)
		{
			FPressed(false);
			FTouchId = -1;
		}
		
		if(!_state && FTouchId == i)
		{
			FPressed(false);
			FTouchId = -1;
		}
		
		// G
		if(_state && point_in_circle(_x, _y, obj_config.bGX, obj_config.bGY, 22 * obj_config.bGScale))
		{			
			if(GTouchId == -1)
			{
				GTouchId = i;
				GPressed(true);
			}
		}
		else if(GTouchId == i)
		{
			GPressed(false);
			GTouchId = -1;
		}
		
		if(!_state && GTouchId == i)
		{
			GPressed(false);
			GTouchId = -1;
		}
		
		// W
		if(_state && point_in_circle(_x, _y, obj_config.bWX, obj_config.bWY, 22 * obj_config.bWScale))
		{
			if(WTouchId == -1)
			{
				WTouchId = i;
				WPressed(true);
			}
		}
		else if(WTouchId == i)
		{
			WPressed(false);
			WTouchId = -1;
		}
		
		if(!_state && WTouchId == i)
		{
			WPressed(false);
			WTouchId = -1;
		}

		// V (v4.0: parry de Amy Canon, boton pequeno de la columna de emotes
		// + v78: BOTON PRINCIPAL del cluster A/B/C, frames 6/7). Ambos tocan
		// la MISMA global.KeyV con un solo VTouchId: prende dentro de
		// CUALQUIERA de los dos circulos y suelta fuera de los DOS (un dedo
		// que deslice entre ellos mantiene la tecla, sin re-disparar ni
		// soltar a mitad). El principal solo responde en partida (jUse: en
		// lobby/menu no se dibuja y no se toca — ahi la V no hace nada,
		// igual que antes).
		// v80h2 V-GUARD: _state PRIMERO (patron casa, como los otros 10
		// botones). En movil device_mouse_*_to_gui solo se actualiza MIENTRAS
		// se toca: leer un slot sin dedo podia devolver undefined y el bloque
		// v78 era el unico de los 11 point_in_circle del loop SIN esta guarda
		// => crash 'argument 1 incorrect type (undefined)' al arrancar en
		// Android sin tocar nada. El is_undefined blinda bVX/bV2* por si un
		// 1.bson corrupto trajera el campo a medias (json_parse NO lanza
		// excepcion al faltar un campo, el try/catch del load() no lo cubre).
		var _inV = _state
			&& !is_undefined(obj_config.bVX) && !is_undefined(obj_config.bVY) && !is_undefined(obj_config.bVScale)
			&& point_in_circle(_x, _y, obj_config.bVX, obj_config.bVY, 22 * obj_config.bVScale)
			|| (_state && jUse && !is_undefined(obj_config.bV2X) && !is_undefined(obj_config.bV2Y) && !is_undefined(obj_config.bV2Scale)
			&& point_in_circle(_x, _y, obj_config.bV2X, obj_config.bV2Y, 40 * obj_config.bV2Scale));

		if(_state && _inV)
		{
			if(VTouchId == -1)
			{
				VTouchId = i;
				VPressed(true);
			}
		}
		else if(VTouchId == i)
		{
			VPressed(false);
			VTouchId = -1;
		}

		if(!_state && VTouchId == i)
		{
			VPressed(false);
			VTouchId = -1;
		}
	}
	
	// Joystick
	if(jTouchId != -1 && GTouchId == -1)
	{
		if(!device_mouse_check_button(jTouchId, mb_left))
		{
			jTouchId = -1;
		}
		else
		{
			var _x = device_mouse_x_to_gui(jTouchId);
			var _y = device_mouse_y_to_gui(jTouchId);
			// v80i: coords del dedo del joystick undefined => tratarlas como
			// el centro del pad (dirX/dirY = 0: suelta las 4 direcciones, sin
			// tocar jTouchId ni re-disparar nada)
			if(is_undefined(_x))
				_x = obj_config.dpadX;
			if(is_undefined(_y))
				_y = obj_config.dpadY;
			var dirX = _x - obj_config.dpadX;
			var dirY = _y - obj_config.dpadY;
			
			if(dirY > 16 * obj_config.jScale)
			{
				keyboard_key_press(vk_down);
				jDir = 4;
			}
			else if(dirY < -16 * obj_config.jScale)
			{
				keyboard_key_press(vk_up);
				jDir = 3;
			}
			else
			{
				keyboard_key_release(vk_up);
				keyboard_key_release(vk_down);
			}
			
			if(dirX > 16 * obj_config.jScale)
			{
				keyboard_key_press(vk_right);
				jDir = 2;
			}
			else if(dirX < -16 * obj_config.jScale)
			{
				keyboard_key_press(vk_left);
				jDir = 1;
			}
			else
			{
				keyboard_key_release(vk_right);
				keyboard_key_release(vk_left);
			}
		}
	}
	
	if(jTouchId == -1 || GTouchId != -1)
	{
		keyboard_key_release(vk_left);
		keyboard_key_release(vk_right);
		keyboard_key_release(vk_up);
		keyboard_key_release(vk_down);
		jDir = 0;
	}
}