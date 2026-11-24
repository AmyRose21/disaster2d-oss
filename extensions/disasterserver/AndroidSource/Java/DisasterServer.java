package ${YYAndroidPackageName};

import java.lang.Thread;

import ${YYAndroidPackageName}.R;
import com.yoyogames.runner.RunnerActivity;

import static com.teamexeempire.disaster2d.Disaster.disaster_start;

public class DisasterServer
{
	public void Init() {}

	public double ServerStart()
	{
		return disaster_start() ? 1d : 0d;
	}

	/* v80e: identificador real del dispositivo para los claims de
	   personajes (.rouge). ANDROID_ID es por-app (distinto por app
	   firmada con otra clave), SOBREVIVE REINSTALAR el juego y solo
	   cambia con factory reset. Si algo falla devuelve "" y el juego
	   no puede reclamar (fail closed, no crashea).

	   OJO (bug v80c/v80d corregido aqui): el contexto NO se saca de
	   RunnerJNILib.ms_activity — esa variable NO existe en el runner
	   runtime-2026.1.0.28 y la compilacion de Android fallaba con
	   "error: cannot find symbol ms_activity". La via correcta (la
	   que usan las extensiones de GameMaker, foros oficiales
	   2014-2023) es RunnerActivity.CurrentActivity, campo publico y
	   estatico de com.yoyogames.runner.RunnerActivity, clase que el
	   propio runner compila dentro del paquete. */
	public String AndroidGetDeviceId()
	{
		try
		{
			android.app.Activity act = RunnerActivity.CurrentActivity;
			if (act == null)
				return "";
			return android.provider.Settings.Secure.getString(
				act.getContentResolver(),
				android.provider.Settings.Secure.ANDROID_ID);
		}
		catch (Throwable t)
		{
			/* Throwable (no Exception): tambien atrapa NoClassDefFound
			   si el nombre cambiara en un runtime futuro — el juego
			   sigue funcionando, solo que sin device_id */
			return "";
		}
	}
}
