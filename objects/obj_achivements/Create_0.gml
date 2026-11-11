depth = -9999;

// [WELCOME PACK v1] Paquete de bienvenida (SOLO Android). Al reinstalar
// el APK (o cambiar de telefono) Android borra /data y con el el guardado
// 3.bin: el jugador volvia a empezar con 0 monedas. Una instalacion LIMPIA
// (sin 3.bin) arranca ahora con este pack para no empezar de cero.
// - PC sigue arrancando en 0: su guardado sobrevive a reinstalaciones.
// - Instalar ENCIMA (actualizar) no da el pack: el 3.bin viejo existe y
//   manda. Lo mismo si Android Auto Backup (v1.4 del chat) restauro el
//   guardado: vuelve tu progreso real, mejor que cualquier pack.
// - Monto: 500 mercoins (~varias partidas de recompensas; iconos 25-75).
//   Para cambiarlo, edita solo esta linea.
// - OJO: es un regalo LOCAL; bucle desinstalar->reinstalar (o borrar
//   datos de la app) lo farmea. La version a prueba de farmeo seria
//   concederlo por cuenta en el server (uid); dime si la quieres.
welcomePack = (os_type == os_android ? 500 : 0);
welcomeTimer = 0; // frames restantes del popup (ver Draw_64)

mercoins = 0;
exeWins = 0;
survWins = 0;
exeKills = 0;
tails = false;
knux = false;
eggman = false;
amy = false;
cream = false;
sally = false;
exe = false;
chaos = false;
exetior = false;
exeller = false;
achivements = array_create(50, false);
prevAchivements = array_create(50, false);
changed = [];
maps = [];

show = function()
{
	audio_play_sound(snd_achivement, 0, false);
	
	boxSide = true;
	alarm[2] = 60 * 4;
}

load = function(filename)
{
	var _buffer = buffer_load(filename);

	mercoins = buffer_read(_buffer, buffer_u64);
	survWins = buffer_read(_buffer, buffer_u32);
	exeWins = buffer_read(_buffer, buffer_u32);
	survStuns = buffer_read(_buffer, buffer_u32);
	exeKills = buffer_read(_buffer, buffer_u32);

	tails = buffer_read(_buffer, buffer_bool);
	knux = buffer_read(_buffer, buffer_bool);
	eggman = buffer_read(_buffer, buffer_bool);
	amy = buffer_read(_buffer, buffer_bool);
	cream = buffer_read(_buffer, buffer_bool);
	sally = buffer_read(_buffer, buffer_bool);
	exe = buffer_read(_buffer, buffer_bool);
	chaos = buffer_read(_buffer, buffer_bool);
	exetior = buffer_read(_buffer, buffer_bool);
	exeller = buffer_read(_buffer, buffer_bool);
	achivements = array_create(50, false);
	prevAchivements = array_create(50, false);
	changed = [];
	changedCount = buffer_read(_buffer, buffer_u8);

	for(var i = 0; i < changedCount; i++)
		array_push(changed, buffer_read(_buffer, buffer_u8));

	for(var i = 0; i < 50; i++)
		achivements[i] = buffer_read(_buffer, buffer_bool);

	array_copy(prevAchivements, 0, achivements, 0, 50);
	mapCount = buffer_read(_buffer, buffer_u8);

	maps = [];
	for(var i = 0; i < mapCount; i++)
		array_push(maps, buffer_read(_buffer, buffer_string));

	buffer_delete(_buffer);
}

save = function()
{
	try
	{
		if(file_exists($"{game_save_id}/3.bin"))
			file_rename($"{game_save_id}/3.bin", $"{game_save_id}/3.bin.bak");
			
		for(var i = 0; i < array_length(achivements); i++)
		{
			if(prevAchivements[i] != achivements[i])
				array_push(changed, i);
			
			prevAchivements[i] = achivements[i];
		}
	
		var _buffer = buffer_create(12, buffer_grow, 1);
	
		buffer_write(_buffer, buffer_u64, mercoins);
		buffer_write(_buffer, buffer_u32, survWins);
		buffer_write(_buffer, buffer_u32, exeWins);
		buffer_write(_buffer, buffer_u32, exeKills);
		buffer_write(_buffer, buffer_u32, survStuns);
	
		buffer_write(_buffer, buffer_bool, tails);
		buffer_write(_buffer, buffer_bool, knux);
		buffer_write(_buffer, buffer_bool, eggman);
		buffer_write(_buffer, buffer_bool, amy);
		buffer_write(_buffer, buffer_bool, cream);
		buffer_write(_buffer, buffer_bool, sally);
		buffer_write(_buffer, buffer_bool, exe);
		buffer_write(_buffer, buffer_bool, chaos);
		buffer_write(_buffer, buffer_bool, exetior);
		buffer_write(_buffer, buffer_bool, exeller);
	
		buffer_write(_buffer, buffer_u8, array_length(changed));
	
		for(var i = 0; i < array_length(changed); i++)
			buffer_write(_buffer, buffer_u8, changed[i]);
	
		for(var i = 0; i < 50; i++)
			buffer_write(_buffer, buffer_bool, achivements[i]);
	
		buffer_write(_buffer, buffer_u8, array_length(maps));
		for(var i = 0; i < array_length(maps); i++)
			buffer_write(_buffer, buffer_string, maps[i]);
		
		buffer_save(_buffer, $"{game_save_id}/3.bin");
		buffer_delete(_buffer);
	}
	catch(error)
	{
		show_message_async($"Failed to save file (3.bin) (report to dev):\n{error.longMessage}");
	}
}

if(!file_exists($"{game_save_id}/3.bin"))
{
	try
	{
		var _buffer = buffer_create(12, buffer_grow, 1);
	
		// [WELCOME PACK v1] instalacion limpia: arrancar con el
		// pack de bienvenida (500 en Android, 0 en PC) — ver top
		buffer_write(_buffer, buffer_u64, welcomePack);
		buffer_write(_buffer, buffer_u32, 0);
		buffer_write(_buffer, buffer_u32, 0);
		buffer_write(_buffer, buffer_u32, 0);
		buffer_write(_buffer, buffer_u32, 0);
	
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_bool, false);
		buffer_write(_buffer, buffer_u8, 0);
	
		for(var i = 0; i < 50; i++)
			buffer_write(_buffer, buffer_bool, 0);
	
		buffer_write(_buffer, buffer_u8, 0);
		buffer_save(_buffer, $"{game_save_id}/3.bin");
		buffer_delete(_buffer);
		
		load($"{game_save_id}/3.bin");

		// [WELCOME PACK v1] hubo regalo: mostrar el popup (~5,3 s:
		// arranca sobre el logo y termina ya en el menu; ver Draw_64)
		if(welcomePack > 0)
			welcomeTimer = 320;
	}
	catch(error)
	{
		show_message_async($"Failed to save file (3.bin) (report to dev):\n{error.longMessage}");
	}
}
else
{
	try
	{
		load($"{game_save_id}/3.bin");
	}
	catch(error)
	{
		try
		{
			load($"{game_save_id}/3.bin");
		}
		catch(error)
		{
			show_message_async($"Save file (3.bin) appears to be corrupted (due to blackout or game's crash)\nThe game will now load a backup save.");
	
			try
			{
				if(file_exists($"{game_save_id}/3.bin.bak"))
				{
					load($"{game_save_id}/3.bin.bak");
					save();
				}
			}
			catch(error2)
			{
				show_message_async($"Backup file (3.bin.bak) seems to be corrupted too. Loading default configuration then!");
			}
		}
	}
}

// achiv
boxX = 0;
boxSide = false;

// round data
revivals = 0;
revivalLast = false;
demonLast = false;
stunnedExe = 0;
wasHurt = false;
healthRestore = 0;
rHeals = 0;
rHealPlayer = -1;
rPlayersEscaped = 0;
rDemonKills = 0;
rEggTrack = 0;
rExeEggTrack = 0;
rAmyStuns = 0;
rExeAmyHits = 0;
rSallyShield = 0;
rBlackRings = 0;
rShardsCollected = 0;
rUsedClone = false;
rShockwave = 0;
rChaosDash = 0;
rExeInvis = false;
rUpper = 0;