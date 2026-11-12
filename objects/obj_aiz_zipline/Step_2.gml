if(timeout > 0)
	timeout--;

if(zstart == noone)
{
	var _inst = self;
	with(obj_aiz_zipline_start)
	{
		if(gid != _inst.gid)
			continue;
			
		_inst.zstart = self;
	}
}

if(zend == noone)
{
	var _inst = self;
	with(obj_aiz_zipline_end)
	{
		if(gid != _inst.gid)
			continue;
			
		_inst.zend = self;
	}
}

if(zstart == noone || zend == noone)
	return;

if(instance_exists(global.player) && global.player.hp > 0)
{
	if(place_meeting(x, y, global.player) && !global.player.isGrounded && !hasPlayer && progress <= 0 && timeout <= 0)
	{
		// CARRY (v2): un jugador colgado de un Tails/Cream volando viaja
		// con isZipline = true, igual que el que viaja en esta tirolina.
		// Sin este guard la tirolina lo agarraba al pasar sobre su punto
		// de inicio y se lo quedaba. Un solo check sirve para TODOS los
		// personajes (presentes y futuros): los 14 checks por personaje
		// que habia aqui decian exactamente esto, porque un estado
		// *_ZIPLINE solo es alcanzable a traves de isZipline.
		if(global.player.isZipline)
			return;
			
		audio_play_sound(snd_snap, 0, false);
		net_sound_emit(snd_snap);
		hasPlayer = true;
		progress = 0;
		zspeed = 0.001;
		zvspeed = 0;
		
		global.player.x = x + 12;
		global.player.y = y + 16;
		
		with(obj_camera)
		{
			x = floor(global.player.x) - 240;
			y = floor(global.player.y) - 135;
			dist = 0;
		}
	}
}

if(hasPlayer && progress < 1)
{
	x = zstart.x + floor((zend.x - zstart.x) * progress);
	y = zstart.y + floor((zend.y - zstart.y) * progress);
	
	global.player.x = x + 12;
	switch(global.character)
	{
		case CHARACTER_EXE:
			global.player.y = y + 22;
			break;
			
		case CHARACTER_TAILS:
			global.player.y = y + 11;
			global.player.isFlying = false;
			break;
			
		case CHARACTER_KNUX:
			global.player.y = y + 22;
			global.player.isGliding = false;

			if(global.player.isStuck)
			{
				global.player.canMove = true;
				global.player.isStuck = false;
			}
			break;

		// v4.4: Rouge cuelga igual que Knuckles (su sprite de tirolina
		// mide casi igual) y la tirolina le corta el planeo/agarre.
		case CHARACTER_ROUGE:
			global.player.y = y + 22;
			global.player.isGliding = false;

			if(global.player.isStuck)
			{
				global.player.canMove = true;
				global.player.isStuck = false;
			}
			break;
			
		case CHARACTER_EGGMAN:
			global.player.y = y + 25;
			break;
			
		case CHARACTER_AMY:
			
		case CHARACTER_AMY_CANON:
			global.player.y = y + 21;
			global.player.isHJ = false;
			break;
			
		case CHARACTER_CREAM:
			global.player.y = y + 8;
			global.player.isFlying = false;
			break;
			
		case CHARACTER_SALLY:
			global.player.y = y + 18;
			break;
			
		// v3 (bug de la tirolina de Angel Island): estos personajes no
		// tenian case, asi que su "y" nunca se reiniciaba y el
		// "+= sprite_height" de abajo los hundia 19 px POR FRAME hasta
		// el suelo: colgados de la liana sobre el abismo recibian dano
		// sin poder soltarse. Offsets = yorigin del sprite de tirolina
		// - 7, la misma regla que siguen los cases de arriba (el 22 de
		// SONIC es el que ya usaba el puppet para dibujar el carrito).
		case CHARACTER_SONIC:
			global.player.y = y + 22;
			break;
			
		case CHARACTER_SALLY_CANON:
			global.player.y = y + 23;
			break;
			
		case CHARACTER_VANILLA:
			global.player.y = y + 16;
			global.player.isFlying = false; // igual que Tails/Cream: su vuelo pisa el estado de tirolina
			break;
			
		case CHARACTER_METAL:
			global.player.y = y + 17;
			break;
			
		case CHARACTER_AMELIA:
			global.player.y = y + 22;
			break;
			
		case CHARACTER_BLAZE:
			global.player.y = y + 19;
			break;
			
		case CHARACTER_FLEETWAY_AMY:
			global.player.y = y + 21;
			break;
			
		default:
			// Personaje futuro sin offset afinado: cuelga a la
			// altura estandar en vez de hundirse en el suelo.
			global.player.y = y + 20;
			break;
	}
	
	global.player.y += sprite_height;
	
	if(global.player.isDead || global.player.hp <= 0 || (progress >= 0.1 && keyboard_check_pressed(global.KeyA)) || !instance_exists(global.player))
	{
		keyboard_key_release(global.KeyA);
		global.player.isZipline = false;
		progress = 1;
	}
	else
		_holdPlayer();
	
	if(zspeed < 0.016)
		zspeed += 0.0001;
		
	progress += zspeed;
	if(progress >= 1)
	{
		camY = obj_camera.y;
		global.player.xspd = sign(zend.x - zstart.x) * zspeed * 150;
	}
}

if(progress >= 1)
{
	zvspeed += 0.32;
	timeout = 60 * 3;
	y += zvspeed;
	
	if(y >= camY + 480)
	{
		x = zstart.x;
		y = zstart.y;
		progress = 0;
		zspeed = 0.001;
		zvspeed = 0;
	}
	
	if(!obj_netclient.gameEnds)
		global.playerControls = true;
	
	hasPlayer = false;
}