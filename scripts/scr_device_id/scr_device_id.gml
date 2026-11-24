function scr_device_id()
{
	/* v80c: identificador REAL del dispositivo para los claims de
	   personajes (.rouge). Android: ANDROID_ID via la extension Java
	   (AndroidGetDeviceId en DisasterServer.java) — es por-app,
	   sobrevive reinstalar el juego (el claim no se pierde) y solo
	   cambia con factory reset. PC: el udid de siempre de os_get_info.
	   Otras plataformas (iOS/Switch/...): "" = no pueden reclamar
	   (fail closed, no rompe nada). Cacheado: se pide una vez por
	   sesion y sobra (es constante mientras la app viva). */

	if(global.deviceIdCache != "")
		return global.deviceIdCache;

	var dev = "";

	if(os_type == os_android)
	{
		/* la extension devuelve "" si algo falla (try/catch alla) */
		dev = string(AndroidGetDeviceId());
	}
	else if(os_type == os_windows || os_type == os_macosx || os_type == os_linux)
	{
		var osInfo = os_get_info();
		dev = $"mod-{osInfo[? "udid"]}";
	}

	/* trim manual: LTS no tiene string_trim, mismo estilo que el
	   token de Amy en scr_globals (el Java a veces manda el id con
	   un \n o espacio de regalo) */
	while(string_length(dev) > 0)
	{
		var _c = string_char_at(dev, string_length(dev));
		if(_c == "\n" || _c == "\r" || _c == " " || _c == "\t")
			dev = string_copy(dev, 1, string_length(dev) - 1);
		else
			break;
	}

	/* tope defensivo (el server trunca a 200; aqui sobra con menos) */
	if(string_length(dev) > 200)
		dev = string_copy(dev, 1, 200);

	global.deviceIdCache = dev;
	return dev;
}
