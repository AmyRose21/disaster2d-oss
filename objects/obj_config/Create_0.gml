randomize();

_buffer = {
	screenMode: 0,
	nickname: $"\\player /{irandom_range(0, 9999)}",
	ip: "localhost",
	showFps: false,
	showPing: true,
	
	// v1 OPTIONS MORE: ajustes de la pestana More. Los valores por defecto
	// conservan la experiencia original del juego (todo visible, volumen
	// al maximo, camara sin look-ahead ni lag); los cambia el usuario desde
	// Options > More y se guardan aqui igual que el resto.
	optBackgrounds: true,
	optParallax: true,
	optEffects: true,
	optWeather: true,
	optOverlays: true,
	optPerf: false,
	musicVolume: 10,
	soundVolume: 10,
	lookAhead: 0,    // 0 = off; 1-10 = 5%-50% de la mitad de la vista
	lookAheadBy: 0,  // 0 = facing, 1 = speed
	turnSpeed: 3,    // 1-5 (solo aplica con look-ahead activo)
	cameraLag: 0,    // 0 = off, 1 = low, 2 = medium, 3 = high
	
	left: vk_left,
	right: vk_right,
	up: vk_up,
	down: vk_down,
	a: ord("Z"),
	b: ord("X"),
	c: ord("C"),
	v: ord("V"),
	em1: ord("A"),
	em2: ord("S"),
	em3: ord("D"),
	hide: vk_lcontrol,
	plist: vk_tab,
	idle: ord("W"),
	
	gampadTouch: {
		xx: 68,
		yy: 187,
		scale: 1,
		opacity: 0.6
	},
	
	zTouch: {
		xx: 378,
		yy: 221,
		scale: 1,
		opacity: 0.6
	},
	
	xTouch: {
		xx: 416,
		yy: 187-10,
		scale: 1,
		opacity: 0.6
	},
	
	cTouch: {
		xx: 452,
		yy: 221,
		scale: 1,
		opacity: 0.6
	},		
	
	aTouch: {
		xx: 466,
		yy: 48,
		scale: 1,
		opacity: 0.6
	},
	
	sTouch: {
		xx: 466,
		yy: 80,
		scale: 1,
		opacity: 0.6
	},
	
	dTouch: {
		xx: 466,
		yy: 112,
		scale: 1,
		opacity: 0.6
	},
	
	wTouch: {
		xx: 466,
		yy: 112+32,
		scale: 1,
		opacity: 0.6
	},
	
	vTouch: {
		xx: 466,
		yy: 112+32+32,
		scale: 1,
		opacity: 0.6
	},
	
	// [v1.4 IN-GAME CHAT] boton tactil de chat (centro xx/yy, como el
	// resto). Se arrastra en partida (obj_game_chat/Step) y la posicion
	// se persiste aqui igual que los demas botones.
	chatTouch: {
		xx: 473,
		yy: 144
	},
	
	gTouch: {
		xx: 23,
		yy: 36+15+30,
		scale: 1,
		opacity: 0.6
	},
};

screenMode = _buffer.screenMode;
nickname = string_copy(_buffer.nickname, 0, 15);
ip = _buffer.ip;
showFps = _buffer.showFps;
showPing = _buffer.showPing;

// v1 OPTIONS MORE
optBackgrounds = _buffer.optBackgrounds;
optParallax = _buffer.optParallax;
optEffects = _buffer.optEffects;
optWeather = _buffer.optWeather;
optOverlays = _buffer.optOverlays;
optPerf = _buffer.optPerf;
musicVolume = _buffer.musicVolume;
soundVolume = _buffer.soundVolume;
lookAhead = _buffer.lookAhead;
lookAheadBy = _buffer.lookAheadBy;
turnSpeed = _buffer.turnSpeed;
cameraLag = _buffer.cameraLag;

// Keys
global.KeyLeft = _buffer.left;
global.KeyRight = _buffer.right;
global.KeyUp = _buffer.up
global.KeyDown = _buffer.down;
global.KeyA = _buffer.a;
global.KeyB = _buffer.b;
global.KeyC = _buffer.c;
global.KeyV = _buffer.v;
global.KeyEm1 = _buffer.em1;
global.KeyEm2 = _buffer.em2;
global.KeyEm3 = _buffer.em3;
global.KeyHide = _buffer.hide;
global.KeyPList = _buffer.plist;
global.KeyIdle = _buffer.idle;

dpadX = _buffer.gampadTouch.xx;
dpadY = _buffer.gampadTouch.yy;
jScale = _buffer.gampadTouch.scale;
jOpacity = _buffer.gampadTouch.opacity;

bAX = _buffer.zTouch.xx;
bAY = _buffer.zTouch.yy;
bAScale =  _buffer.zTouch.scale;
bAOpacity =  _buffer.zTouch.opacity;

bBX = _buffer.xTouch.xx;
bBY = _buffer.xTouch.yy;
bBScale = _buffer.xTouch.scale;
bBOpacity = _buffer.xTouch.opacity;

bCX = _buffer.cTouch.xx;
bCY = _buffer.cTouch.yy;
bCScale = _buffer.cTouch.scale;
bCOpacity = _buffer.cTouch.opacity;

bDX = _buffer.aTouch.xx;
bDY = _buffer.aTouch.yy;
bDScale = _buffer.aTouch.scale;
bDOpacity = _buffer.aTouch.opacity;

bEX = _buffer.sTouch.xx;
bEY = _buffer.sTouch.yy;
bEScale = _buffer.sTouch.scale;
bEOpacity = _buffer.sTouch.opacity;

bFX = _buffer.dTouch.xx;
bFY = _buffer.dTouch.yy;
bFScale = _buffer.dTouch.scale;
bFOpacity = _buffer.dTouch.opacity;

bGX = _buffer.gTouch.xx;
bGY = _buffer.gTouch.yy;
bGScale = _buffer.gTouch.scale;
bGOpacity = _buffer.gTouch.opacity;

bWX = _buffer.wTouch.xx;
bWY = _buffer.wTouch.yy;
bWScale = _buffer.wTouch.scale;
bWOpacity = _buffer.wTouch.opacity;

bVX = _buffer.vTouch.xx;
bVY = _buffer.vTouch.yy;
bVScale = _buffer.vTouch.scale;
bVOpacity = _buffer.vTouch.opacity;

// [v1.4 IN-GAME CHAT] centro del boton de chat (por defecto: hueco entre
// F y V en la columna derecha - ver obj_game_chat/Create)
bChatX = _buffer.chatTouch.xx;
bChatY = _buffer.chatTouch.yy;

global.nickname = scr_nickname_validate(nickname);

load = function(filename)
{
	var _bfr = buffer_load(filename);
	var _tmp = buffer_create(buffer_get_size(_bfr), buffer_fixed, 1);
	
	for(var i = 0; i < buffer_get_size(_bfr); i++)
		buffer_write(_tmp, buffer_u8, (buffer_read(_bfr, buffer_u8) ^ 69));
	
	buffer_seek(_tmp, buffer_seek_start, 0);
	var _json = buffer_read(_tmp, buffer_string);
	_buffer = json_parse(_json);
	buffer_delete(_bfr);
	buffer_delete(_tmp);
	
	screenMode = _buffer.screenMode;
	nickname = string_copy(_buffer.nickname, 0, 15);
	ip = _buffer.ip;
	showFps = _buffer.showFps;
	showPing = _buffer.showPing;

	// v1 OPTIONS MORE: igual que KeyIdle mas arriba, cada campo nuevo se
	// lee con su propio try/catch para que un guardado viejo (sin la
	// pestana More) no rompa la carga: cae al valor por defecto.
	try { optBackgrounds = _buffer.optBackgrounds; } catch(ex) { optBackgrounds = true; _buffer.optBackgrounds = true; }
	try { optParallax = _buffer.optParallax; } catch(ex) { optParallax = true; _buffer.optParallax = true; }
	try { optEffects = _buffer.optEffects; } catch(ex) { optEffects = true; _buffer.optEffects = true; }
	try { optWeather = _buffer.optWeather; } catch(ex) { optWeather = true; _buffer.optWeather = true; }
	try { optOverlays = _buffer.optOverlays; } catch(ex) { optOverlays = true; _buffer.optOverlays = true; }
	try { optPerf = _buffer.optPerf; } catch(ex) { optPerf = false; _buffer.optPerf = false; }
	try { musicVolume = _buffer.musicVolume; } catch(ex) { musicVolume = 10; _buffer.musicVolume = 10; }
	try { soundVolume = _buffer.soundVolume; } catch(ex) { soundVolume = 10; _buffer.soundVolume = 10; }
	try { lookAhead = _buffer.lookAhead; } catch(ex) { lookAhead = 0; _buffer.lookAhead = 0; }
	try { lookAheadBy = _buffer.lookAheadBy; } catch(ex) { lookAheadBy = 0; _buffer.lookAheadBy = 0; }
	try { turnSpeed = _buffer.turnSpeed; } catch(ex) { turnSpeed = 3; _buffer.turnSpeed = 3; }
	try { cameraLag = _buffer.cameraLag; } catch(ex) { cameraLag = 0; _buffer.cameraLag = 0; }

	// Keys
	global.KeyLeft = _buffer.left;
	global.KeyRight = _buffer.right;
	global.KeyUp = _buffer.up
	global.KeyDown = _buffer.down;
	global.KeyA = _buffer.a;
	global.KeyB = _buffer.b;
	global.KeyC = _buffer.c;
	global.KeyEm1 = _buffer.em1;
	global.KeyEm2 = _buffer.em2;
	global.KeyEm3 = _buffer.em3;
	global.KeyHide = _buffer.hide;
	global.KeyPList = _buffer.plist;
	
	try
	{
		global.KeyIdle = _buffer.idle;
	}
	catch(ex) {
		_buffer.idle = ord("W");
		global.KeyIdle = _buffer.idle;
	}

	try
	{
		global.KeyV = _buffer.v;
	}
	catch(ex) {
		_buffer.v = ord("V");
		global.KeyV = _buffer.v;
	}

	dpadX = _buffer.gampadTouch.xx;
	dpadY = _buffer.gampadTouch.yy;
	jScale = _buffer.gampadTouch.scale;
	jOpacity = _buffer.gampadTouch.opacity;

	bAX = _buffer.zTouch.xx;
	bAY = _buffer.zTouch.yy;
	bAScale =  _buffer.zTouch.scale;
	bAOpacity =  _buffer.zTouch.opacity;

	bBX = _buffer.xTouch.xx;
	bBY = _buffer.xTouch.yy;
	bBScale = _buffer.xTouch.scale;
	bBOpacity = _buffer.xTouch.opacity;

	bCX = _buffer.cTouch.xx;
	bCY = _buffer.cTouch.yy;
	bCScale = _buffer.cTouch.scale;
	bCOpacity = _buffer.cTouch.opacity;

	bDX = _buffer.aTouch.xx;
	bDY = _buffer.aTouch.yy;
	bDScale = _buffer.aTouch.scale;
	bDOpacity = _buffer.aTouch.opacity;

	bEX = _buffer.sTouch.xx;
	bEY = _buffer.sTouch.yy;
	bEScale = _buffer.sTouch.scale;
	bEOpacity = _buffer.sTouch.opacity;

	bFX = _buffer.dTouch.xx;
	bFY = _buffer.dTouch.yy;
	bFScale = _buffer.dTouch.scale;
	bFOpacity = _buffer.dTouch.opacity;

	bGX = _buffer.gTouch.xx;
	bGY = _buffer.gTouch.yy;
	bGScale = _buffer.gTouch.scale;
	bGOpacity = _buffer.gTouch.opacity;
	
	try
	{
		bWX = _buffer.wTouch.xx;
		bWY = _buffer.wTouch.yy;
		bWScale = _buffer.wTouch.scale;
		bWOpacity = _buffer.wTouch.opacity;
	}
	catch(ex) 
	{
		_buffer.wTouch = {
			xx: 466,
			yy: 112+32,
			scale: 1,
			opacity: 0.6
		};
		
		bWX = _buffer.wTouch.xx;
		bWY = _buffer.wTouch.yy;
		bWScale = _buffer.wTouch.scale;
		bWOpacity = _buffer.wTouch.opacity;
	}

	try
	{
		bVX = _buffer.vTouch.xx;
		bVY = _buffer.vTouch.yy;
		bVScale = _buffer.vTouch.scale;
		bVOpacity = _buffer.vTouch.opacity;
	}
	catch(ex) 
	{
		_buffer.vTouch = {
			xx: 466,
			yy: 112+32+32,
			scale: 1,
			opacity: 0.6
		};
		
		bVX = _buffer.vTouch.xx;
		bVY = _buffer.vTouch.yy;
		bVScale = _buffer.vTouch.scale;
		bVOpacity = _buffer.vTouch.opacity;
	}

	// [v1.4 IN-GAME CHAT] guardados viejos (pre-chat) no traen la
	// entrada: cae al hueco por defecto entre F y V
	try
	{
		bChatX = _buffer.chatTouch.xx;
		bChatY = _buffer.chatTouch.yy;
	}
	catch(ex) 
	{
		_buffer.chatTouch = {
			xx: 473,
			yy: 144
		};
		
		bChatX = _buffer.chatTouch.xx;
		bChatY = _buffer.chatTouch.yy;
	}

	global.nickname = scr_nickname_validate(nickname);
}

save = function()
{
	_buffer.screenMode = screenMode;
	_buffer.nickname = string_copy(global.nickname, 0, 15);
	_buffer.ip = ip;
	_buffer.showFps = showFps;
	_buffer.showPing = showPing;
	
	// v1 OPTIONS MORE
	_buffer.optBackgrounds = optBackgrounds;
	_buffer.optParallax = optParallax;
	_buffer.optEffects = optEffects;
	_buffer.optWeather = optWeather;
	_buffer.optOverlays = optOverlays;
	_buffer.optPerf = optPerf;
	_buffer.musicVolume = musicVolume;
	_buffer.soundVolume = soundVolume;
	_buffer.lookAhead = lookAhead;
	_buffer.lookAheadBy = lookAheadBy;
	_buffer.turnSpeed = turnSpeed;
	_buffer.cameraLag = cameraLag;
	
	_buffer.left = global.KeyLeft;
	_buffer.right = global.KeyRight;
	_buffer.up = global.KeyUp;
	_buffer.down = global.KeyDown;
	_buffer.a = global.KeyA;
	_buffer.b = global.KeyB;
	_buffer.c = global.KeyC;
	_buffer.v = global.KeyV;
	_buffer.em1 = global.KeyEm1;
	_buffer.em2 = global.KeyEm2;
	_buffer.em3 = global.KeyEm3;
	_buffer.hide = global.KeyHide;
	_buffer.plist = global.KeyPList;
	_buffer.idle = global.KeyIdle;
	
	_buffer.gampadTouch.xx = dpadX;
	_buffer.gampadTouch.yy = dpadY;
	_buffer.gampadTouch.scale = jScale;
	_buffer.gampadTouch.opacity = jOpacity;
	
	_buffer.zTouch.xx = bAX;
	_buffer.zTouch.yy = bAY;
	_buffer.zTouch.scale =  bAScale;
	_buffer.zTouch.opacity = bAOpacity;
	
	_buffer.xTouch.xx = bBX;
	_buffer.xTouch.yy = bBY;
	_buffer.xTouch.scale = bBScale;
	_buffer.xTouch.opacity = bBOpacity;
	
	_buffer.cTouch.xx = bCX;
	_buffer.cTouch.yy =	bCY;
	_buffer.cTouch.scale = bCScale;
	_buffer.cTouch.opacity = bCOpacity;
	
	_buffer.aTouch.xx = bDX;
	_buffer.aTouch.yy = bDY;
	_buffer.aTouch.scale = bDScale;
	_buffer.aTouch.opacity = bDOpacity;
	
	_buffer.sTouch.xx = bEX;
	_buffer.sTouch.yy = bEY;
	_buffer.sTouch.scale = bEScale;
	_buffer.sTouch.opacity = bEOpacity;
	
	_buffer.dTouch.xx = bFX;     
	_buffer.dTouch.yy = bFY;
	_buffer.dTouch.scale = bFScale;
	_buffer.dTouch.opacity = bFOpacity;
	
	_buffer.gTouch.xx = bGX;
	_buffer.gTouch.yy = bGY;
	_buffer.gTouch.scale = bGScale;
	_buffer.gTouch.opacity = bGOpacity;
	
	_buffer.wTouch.xx = bWX;
	_buffer.wTouch.yy = bWY;
	_buffer.wTouch.scale = bWScale;
	_buffer.wTouch.opacity = bWOpacity;
	
	_buffer.vTouch.xx = bVX;
	_buffer.vTouch.yy = bVY;
	_buffer.vTouch.scale = bVScale;
	_buffer.vTouch.opacity = bVOpacity;
	
	// [v1.4 IN-GAME CHAT]
	_buffer.chatTouch.xx = bChatX;
	_buffer.chatTouch.yy = bChatY;
	
	try
	{
		if(file_exists($"{game_save_id}/1.bson"))
			file_rename($"{game_save_id}/1.bson", $"{game_save_id}/1.bson.bak");
		
		var _json = json_stringify(_buffer, true);
		var _jsonLen = string_byte_length(_json);
		var _bfrIn = buffer_create(0, buffer_grow, 1);
	
		buffer_write(_bfrIn, buffer_string, _json);
		buffer_seek(_bfrIn, buffer_seek_start, 0);
	
		var _bfrOut = buffer_create(buffer_get_size(_bfrIn), buffer_fixed, 1);
		for(var i = 0; i < buffer_get_size(_bfrIn); i++)
			buffer_write(_bfrOut, buffer_u8, buffer_read(_bfrIn, buffer_u8) ^ 69);
	
		buffer_save(_bfrOut, $"{game_save_id}/1.bson");
		buffer_delete(_bfrIn);
		buffer_delete(_bfrOut);
	}
	catch(error)
	{
		show_message_async($"Failed to save file (1.bson) (report to dev):\n{error.longMessage}");
	}
}

if(!file_exists($"{game_save_id}/1.bson"))
{
	save();
}
else
{
	try
	{
		load($"{game_save_id}/1.bson");
	}
	catch(error)
	{
		show_message_async($"Save file (1.bson) appears to be corrupted (due to blackout or game's crash)\nThe game will now load a backup save.");
	
		try
		{
			if(file_exists($"{game_save_id}/1.bson.bak"))
			{
				load($"{game_save_id}/1.bson.bak");
				save();
			}
		}
		catch(error2)
		{
			show_message_async($"Backup file (1.bson.bak) seems to be corrupted too. Loading default configuration then!");
		}
	}
}

applyRes = function()
{
	switch(obj_config.screenMode)
	{
		case 0:
		{
			window_set_fullscreen(false);
			window_set_size(480, 270);
			window_center();
			break;
		}
		
		case 1:
		{
			window_set_fullscreen(false);
			window_set_size(480*2, 270*2);
			window_center();
			break;
		}
		
		case 2:
		{
			window_set_fullscreen(false);
			window_set_size(480*3, 270*3);
			window_center();
			break;
		}
		
		case 3:
		{
			window_set_fullscreen(true);
			break;
		}
	}
	
}

if(!global.configInit)
{
	global.configInit = true;
	applyRes();
}

// v1 OPTIONS MORE: fija el gain por asset de musica/sonido segun la
// config cargada (o los valores por defecto). audio_sound_gain con el
// ID del asset afecta a las instancias sonando ahora Y a las futuras,
// asi que con esto basta y no hay que tocar ningun audio_play_sound.
scr_menu_more_apply_volumes();