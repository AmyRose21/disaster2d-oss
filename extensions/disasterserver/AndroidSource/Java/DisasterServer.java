package ${YYAndroidPackageName};

import java.lang.Thread;

import ${YYAndroidPackageName}.R;
import com.yoyogames.runner.RunnerJNILib;

import static com.teamexeempire.disaster2d.Disaster.disaster_start;

public class DisasterServer
{
	public void Init() {}

	public double ServerStart()
	{
		return disaster_start() ? 1d : 0d;
	}

	/* v80c: identificador real del dispositivo para los claims de
	   personajes (.rouge). ANDROID_ID es por-app (distinto por app
	   firmada con otra clave), SOBREVIVE REINSTALAR el juego y solo
	   cambia con factory reset. Si algo falla (contexto nulo,
	   permisos raros) devuelve "" y el juego no puede reclamar
	   (fail closed, no crashea). */
	public String AndroidGetDeviceId()
	{
		try
		{
			android.content.Context ctx = RunnerJNILib.ms_activity;
			if (ctx == null)
				return "";
			return android.provider.Settings.Secure.getString(
				ctx.getContentResolver(),
				android.provider.Settings.Secure.ANDROID_ID);
		}
		catch (Exception e)
		{
			return "";
		}
	}
}
