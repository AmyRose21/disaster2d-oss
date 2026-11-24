package ${YYAndroidPackageName};

import java.lang.Thread;

import ${YYAndroidPackageName}.R;
import static com.teamexeempire.disaster2d.Disaster.disaster_start;

public class DisasterServer
{
        public void Init() {}

        public double ServerStart()
        {
                return disaster_start() ? 1d : 0d;
        }

        /* v80g: identificador del dispositivo para los claims .rouge.
           ANDROID_ID: por-app (distinta si otra clave firma el APK),
           sobrevive reinstalar, solo cambia con factory reset.

           HISTORIA DEL BUG (leela antes de tocar esto):
           - v80c/v80d usaban RunnerJNILib.ms_activity -> "cannot find
             symbol ms_activity": ese campo NO existe en el runner
             runtime-2026.1.0.28 (compila Java contra el .28).
           - v80e usaba RunnerActivity.CurrentActivity con
             import com.yoyogames.runner.RunnerActivity -> TAMPOCO
             compila en el .28: en ese runtime RunnerActivity se genera
             DENTRO DEL PAQUETE DEL JUEGO (log Igor linea "Copying ...
             YYAndroidPackageProduct\RunnerActivity.java -> ...
             com\teamexeempire\disaster2dm\RunnerActivity.java"), y en
             com.yoyogames.runner solo existe RunnerJNILib.
           - v80g: CERO imports del runner. Se busca la clase por
             reflection con Class.forName probando en orden:
               1) ${YYAndroidPackageName}.RunnerActivity  (runtime .28+)
               2) com.yoyogames.runner.RunnerActivity    (runtimes viejos)
             y se lee el campo estatico "CurrentActivity". Si el
             runtime cambia otra vez de sitio o de nombre, catch
             (Throwable) devuelve "" y el juego sigue funcionando sin
             device_id (fail closed, sin crash). Compila en cualquier
             runtime porque no referencia NINGUNA clase del runner en
             tiempo de compilacion. */
        public String AndroidGetDeviceId()
        {
                try
                {
                        Class<?> cls = null;
                        try
                        {
                                cls = Class.forName("${YYAndroidPackageName}.RunnerActivity");
                        }
                        catch (ClassNotFoundException e1)
                        {
                                cls = Class.forName("com.yoyogames.runner.RunnerActivity");
                        }
                        Object act = cls.getField("CurrentActivity").get(null);
                        if (act == null)
                                return "";
                        android.content.ContentResolver cr =
                                (android.content.ContentResolver)
                                act.getClass().getMethod("getContentResolver").invoke(act);
                        if (cr == null)
                                return "";
                        Object id = android.provider.Settings.Secure.getString(
                                cr, android.provider.Settings.Secure.ANDROID_ID);
                        return id instanceof String ? (String) id : "";
                }
                catch (Throwable t)
                {
                        /* Throwable (no Exception): atrapa tambien
                           NoClassDefFoundError / NoSuchFieldError si un runtime
                           futuro vuelve a mover la clase */
                        return "";
                }
        }
}
