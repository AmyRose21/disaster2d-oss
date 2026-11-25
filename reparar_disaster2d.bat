@echo off
title Reparador automatico disaster2d v80j
set "PSF=%TEMP%\d2d_repair.ps1"
more +13 "%~f0" > "%PSF%"
if errorlevel 1 goto :err
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSF%"
echo.
pause
exit /b 0
:err
echo ERROR: no se pudo extraer el reparador. Copiame a una ruta normal y ejecutame de nuevo.
pause
exit /b 1
# ============================================================
#  REPARADOR AUTOMATICO disaster2d + GameMaker (v80j)
#  2026-11-24. Repara: cache Gradle rota, exclusiones antivirus,
#  DisasterServer.java v80g (reflection) + fix v80i del crash (intacto)
#  + layout v80j: V abajo del cluster A/B/C, cluster subido, marcador fuera,
#  compila capturando el error REAL de javac y autodiagnostica.
# ============================================================
$ErrorActionPreference = 'Continue'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$log = Join-Path ([Environment]::GetFolderPath('Desktop')) ('reparar_disaster2d_' + $stamp + '.log.txt')
try { Start-Transcript -Path $log -Force | Out-Null } catch {}

function Ok($m)   { Write-Host ('  [OK]    ' + $m) -ForegroundColor Green }
function Bad($m)  { Write-Host ('  [FALLO] ' + $m) -ForegroundColor Red }
function Warn($m) { Write-Host ('  [AVISO] ' + $m) -ForegroundColor Yellow }
function Info($m) { Write-Host ('          ' + $m) }

Write-Host '========================================================='
Write-Host '   REPARADOR AUTOMATICO  disaster2d  (v80j)'
Write-Host '========================================================='
Write-Host ''

# ---------- localizar rutas ----------
$projRoot = 'C:\Users\AM\Documents\GitHub\disaster2d-oss'
if (-not (Test-Path -LiteralPath (Join-Path $projRoot 'Sonicexe The Disaster 2D Remake.yyp'))) {
    $alt = $null
    $gh = Join-Path $env:USERPROFILE 'Documents\GitHub'
    if (Test-Path $gh) {
        $alt = Get-ChildItem $gh -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'Sonicexe The Disaster 2D Remake.yyp') } | Select-Object -First 1
    }
    if ($alt) { $projRoot = $alt.FullName }
    else { $projRoot = (Read-Host 'No encontre el proyecto. Pega la ruta de la carpeta disaster2d-oss y pulsa Enter').Trim() }
}
$gmsRoaming = Join-Path $env:APPDATA 'GameMakerStudio2-LTS2026'
if (-not (Test-Path $gmsRoaming)) {
    $c = Get-ChildItem $env:APPDATA -Directory -Filter 'GameMakerStudio2*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { $gmsRoaming = $c.FullName }
}
$gmTemp = Join-Path $env:LOCALAPPDATA 'GameMakerStudio2-LTS2026\GMS2TEMP'
if (-not (Test-Path (Split-Path $gmTemp -Parent))) {
    $c2 = Get-ChildItem $env:LOCALAPPDATA -Directory -Filter 'GameMakerStudio2*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c2) { $gmTemp = Join-Path $c2.FullName 'GMS2TEMP' }
}
$runRoot = 'C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes'
if (-not (Test-Path $runRoot)) {
    $c3 = Get-ChildItem 'C:\ProgramData' -Directory -Filter 'GameMakerStudio2*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c3) { $runRoot = Join-Path $c3.FullName 'Cache\runtimes' }
}
$cacheRoot = Join-Path $gmsRoaming 'Cache\GMS2CACHE'
$runtime = $null
if (Test-Path $runRoot) {
    $rt = Get-ChildItem $runRoot -Directory -Filter 'runtime-*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($rt) { $runtime = $rt.FullName }
}
$cacheProj = $null
if (Test-Path $cacheRoot) {
    $cp = Get-ChildItem $cacheRoot -Directory -Filter 'Sonicexe*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cp) { $cacheProj = $cp.FullName }
    else { $cacheProj = Join-Path $cacheRoot 'Sonicexe_T_EAB73F4B' }
}
Info ('Proyecto : ' + $projRoot)
Info ('Cache    : ' + $cacheProj)
Info ('Runtime  : ' + $runtime)
Write-Host ''

# ---------- PASO 1: cerrar GameMaker ----------
Write-Host '--- PASO 1: GameMaker debe estar cerrado ---'
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Igor|GameMaker' }
if ($procs) {
    Warn 'GameMaker / Igor sigue abierto.'
    $r = Read-Host 'Escribe S y Enter para que lo cierre yo, o N para abortar'
    if ($r -eq 'S' -or $r -eq 's') {
        $procs | Stop-Process -Force
        Start-Sleep -Seconds 2
        Ok 'Cerrado.'
    }
    else {
        Bad 'Abortado. Cierra GameMaker y vuelve a ejecutar este reparador.'
        try { Stop-Transcript | Out-Null } catch {}
        Read-Host 'Pulsa Enter para cerrar'
        exit 1
    }
}
else { Ok 'GameMaker estaba cerrado.' }
Write-Host ''

# ---------- PASO 2: plantilla Gradle del runtime ----------
Write-Host '--- PASO 2: plantilla Gradle del runtime ---'
$tmpl = $null
if ($runtime) {
    $gw = Get-ChildItem $runtime -Recurse -Filter 'gradlew.bat' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gw) { $tmpl = $gw.FullName }
}
if ($tmpl) { Ok ('Plantilla Gradle correcta en el runtime: ' + $tmpl) }
else {
    Bad 'El runtime NO tiene gradlew.bat (instalacion danada o borrada por el antivirus).'
    Info 'Unico arreglo que no puedo hacer solo:'
    Info '  1. Abre GameMaker -> File -> Preferences -> Runtime'
    Info '  2. Desinstala y reinstala el runtime 2026.1.0.28 (o instala el mas reciente)'
    Info '  3. Vuelve a ejecutar este reparador para verificarlo'
}
Write-Host ''

# ---------- PASO 3: antivirus (Defender) ----------
Write-Host '--- PASO 3: exclusiones del antivirus ---'
$excl = @($cacheRoot, $runRoot, $gmTemp, (Join-Path $gmsRoaming 'Cache'))
$excl = @($excl | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique)
if ($excl.Count -gt 0) {
    try {
        Add-MpPreference -ExclusionPath $excl -ErrorAction Stop
        Ok 'Exclusiones de Defender anadidas.'
    }
    catch {
        Info 'Pido permiso de administrador para las exclusiones (ventana de UAC)...'
        $elevArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', ('Add-MpPreference -ExclusionPath ' + (($excl | ForEach-Object { '"' + $_ + '"' }) -join ',')))
        Start-Process powershell.exe -Verb RunAs -ArgumentList $elevArgs -Wait
        $prefs = (Get-MpPreference -ErrorAction SilentlyContinue).ExclusionPath
        $missing = @($excl | Where-Object { $prefs -notcontains $_ })
        if ($missing.Count -eq 0) { Ok 'Exclusiones anadidas (con permisos de admin).' }
        else { Warn ('No pude anadir: ' + ($missing -join ' ; ') + '  (si usas otro antivirus, anadelas a mano)') }
    }
    try {
        $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue | Where-Object { ($_.Resources -join ' ') -match 'gradlew|gradle' }
        if ($threats) {
            Warn 'Defender puso gradlew/gradle en cuarentena en su dia:'
            $threats | ForEach-Object { Info ('  - ' + ($_.Resources -join ' ')) }
            Info 'Restauralo a mano: Seguridad de Windows -> Virus y amenazas ->'
            Info 'Historial de proteccion -> gradlew -> Acciones -> Restaurar.'
        }
        else { Ok 'Nada de gradle en la cuarentena de Defender.' }
    }
    catch { Warn 'No pude consultar la cuarentena (quizas hay otro antivirus).' }
}
Write-Host ''

# ---------- PASO 4: limpiar cache (guardando build.bff para el final) ----------
Write-Host '--- PASO 4: limpiar cache del proyecto (se regenera sola) ---'
$bffSrc = Join-Path $gmTemp 'build.bff'
if (Test-Path -LiteralPath $bffSrc) {
    Copy-Item -LiteralPath $bffSrc -Destination (Join-Path $env:TEMP 'd2d_build.bff') -Force
    Info 'build.bff guardado (para poder compilar al final sin abrir el IDE).'
}
if ($cacheProj -and (Test-Path -LiteralPath $cacheProj)) {
    $bakLeaf = (Split-Path $cacheProj -Leaf) + '.bak_' + $stamp
    try {
        Rename-Item -LiteralPath $cacheProj -NewName $bakLeaf -ErrorAction Stop
        Ok ('Cache vieja renombrada a ' + $bakLeaf + ' (borrable cuando quieras).')
    }
    catch {
        try { Remove-Item -LiteralPath $cacheProj -Recurse -Force -ErrorAction Stop; Ok 'Cache vieja borrada.' }
        catch { Bad 'No pude tocar la cache: cierra GameMaker y reintenta.' }
    }
}
else { Ok 'La cache ya estaba limpia.' }
if (Test-Path $gmTemp) {
    Get-ChildItem $gmTemp -Filter 'build.bff' -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem $gmTemp -Directory -Filter 'Sonicexe*' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Ok 'GMS2TEMP limpiado.'
}
Write-Host ''

# ---------- PASO 5: DisasterServer.java v80g ----------
Write-Host '--- PASO 5: Java v80g del runner (fix definitivo) ---'
$javaPath = Join-Path $projRoot 'extensions\disasterserver\AndroidSource\Java\DisasterServer.java'
if (Test-Path -LiteralPath $javaPath) {
    $j = Get-Content -Raw -LiteralPath $javaPath
    if ($j -match 'Class\.forName\("\$\{YYAndroidPackageName\}\.RunnerActivity"\)') { Ok 'DisasterServer.java ya es la version v80g correcta.' }
    else {
        if ($j -match 'RunnerJNILib\.ms_activity') { Warn 'Encontrada version v80c/v80d (ms_activity): es el error de compilacion.' }
        elseif ($j -match 'import com\.yoyogames\.runner\.RunnerActivity') { Warn 'Encontrada version v80e (import RunnerActivity): tambien falla en runtime-2026.1.0.28.' }
        $jbak = $javaPath + '.bak_' + $stamp
        Copy-Item -LiteralPath $javaPath -Destination $jbak -Force
        $javaV80g = @'
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
'@
        Set-Content -LiteralPath $javaPath -Value $javaV80g -Encoding ASCII
        $j2 = Get-Content -Raw -LiteralPath $javaPath
        if ($j2 -match 'Class\.forName') { Ok ('v80g instalada (copia vieja en ' + (Split-Path $jbak -Leaf) + ').') }
        else { Bad 'No se pudo escribir el Java v80g.' }
    }
}
else { Bad ('No encuentro ' + $javaPath) }
foreach ($f in @(
    'extensions\disasterserver\AndroidSource\Java\Disaster.java',
    'extensions\disnet\AndroidSource\Java\Disnet.java',
    'extensions\disnet\AndroidSource\Java\DisnetWrapper.java',
    'scripts\scr_device_id\scr_device_id.gml',
    'scripts\net_indentity\net_indentity.gml'
)) {
    $p = Join-Path $projRoot $f
    if (Test-Path -LiteralPath $p) { Ok ('Presente: ' + $f) }
    else { Bad ('FALTA: ' + $f + '  (reinstala el zip v80e completo y vuelve a correrme)') }
}
Write-Host ''

# ---------- PASO 5b: fix v80i del crash (SLOT-SANITIZE + V-GUARD) ----------
Write-Host '--- PASO 5b: fix del crash point_in_circle (v80i) ---'
$touchPath = Join-Path $projRoot 'scripts\scr_controls_update_touch\scr_controls_update_touch.gml'
if (-not (Test-Path -LiteralPath $touchPath)) {
    Warn 'No encuentro scr_controls_update_touch.gml (ruta de proyecto distinta?). El fix del crash no se aplica.'
}
else {
    $t = [IO.File]::ReadAllText($touchPath)   # UTF-8 auto, sin BOM al reescribir
    if ($t -match 'SLOT-SANITIZE') { Ok 'scr_controls_update_touch.gml ya tiene el fix v80i.' }
    elseif ($t -notmatch 'function scr_controls_update_touch') { Bad 'El script no tiene la funcion esperada; no lo toco.' }
    else {
        $bak = $touchPath + '.bak_' + $stamp
        Copy-Item -LiteralPath $touchPath -Destination $bak -Force

        $vguard = @'
\t\t// v80h2 V-GUARD: _state PRIMERO (patron casa, como los otros 10
\t\t// botones). En movil device_mouse_*_to_gui solo se actualiza MIENTRAS
\t\t// se toca: leer un slot sin dedo podia devolver undefined y el bloque
\t\t// v78 era el unico de los 11 point_in_circle del loop SIN esta guarda
\t\t// => crash 'argument 1 incorrect type (undefined)' al arrancar en
\t\t// Android sin tocar nada. El is_undefined blinda bVX/bV2* por si un
\t\t// 1.bson corrupto trajera el campo a medias (json_parse NO lanza
\t\t// excepcion al faltar un campo, el try/catch del load() no lo cubre).
\t\tvar _inV = _state
\t\t\t&& !is_undefined(obj_config.bVX) && !is_undefined(obj_config.bVY) && !is_undefined(obj_config.bVScale)
\t\t\t&& point_in_circle(_x, _y, obj_config.bVX, obj_config.bVY, 22 * obj_config.bVScale)
\t\t\t|| (_state && jUse && !is_undefined(obj_config.bV2X) && !is_undefined(obj_config.bV2Y) && !is_undefined(obj_config.bV2Scale)
\t\t\t&& point_in_circle(_x, _y, obj_config.bV2X, obj_config.bV2Y, 40 * obj_config.bV2Scale));
'@
        $vguard = $vguard.Replace('\t', "`t")

        # --- paso 1: llevar el bloque V a 'var _inV = _state' sea cual sea su version ---
        if ($t -match 'var _inV = _state') {
            Info 'V-GUARD ya presente (v80h2); solo falta el SLOT-SANITIZE.'
        }
        elseif ($t -match 'v80h V-DEFENSE') {
            Warn 'Encontrada version v80h vieja (V-DEFENSE): la reemplazo por el V-GUARD completo.'
            $t = [regex]::Replace($t, '(?s)[ \t]*// v80h V-DEFENSE.*?// --- fin V-DEFENSE ---', $vguard.TrimEnd("`r","`n"), 1)
        }
        else {
            $vOld = "        var _inV = point_in_circle(_x, _y, obj_config.bVX, obj_config.bVY, 22 * obj_config.bVScale)`r`n            || (jUse && point_in_circle(_x, _y, obj_config.bV2X, obj_config.bV2Y, 40 * obj_config.bV2Scale));".Replace('        ', "`t`t").Replace('    ', "`t")
            if ($t.Contains($vOld)) { $t = $t.Replace($vOld, $vguard.TrimEnd("`r","`n")) }
            else {
                $m1 = [regex]::Match($t, '[ \t]*var _inV = point_in_circle\(_x, _y, obj_config\.bVX, obj_config\.bVY, 22 \* obj_config\.bVScale\)[^\r\n]*\r?\n[ \t]*\|\| \(jUse && point_in_circle\(_x, _y, obj_config\.bV2X, obj_config\.bV2Y, 40 \* obj_config\.bV2Scale\)\);')
                if (-not $m1.Success) { Bad 'No encuentro el bloque _inV del boton V. Mandame el script para verlo.' }
                else { $t = $t.Substring(0, $m1.Index) + $vguard.TrimEnd("`r","`n") + $t.Substring($m1.Index + $m1.Length) }
            }
        }

        if ($t -match 'var _inV = _state') {
            # --- paso 2: SLOT-SANITIZE tras la linea de _state ---
            $anchor = "`t`tvar _state = device_mouse_check_button\(i, mb_left\);[ \t]*\r?\n"
            if ($t -match $anchor) {
                $san = @'
\t\t// v80i SLOT-SANITIZE: un slot con _state true pero coordenadas todavia
\t\t// undefined (frame en que se presiono, o mouse fisico sin datos de
\t\t// touch) se trata como no-tocado: sin coords no hay hit-test posible
\t\t// y _state sola no alcanza (era el unico caso que el V-GUARD v80h2
\t\t// no cubria: crasheaba el dpad, linea 26). Cubre dpad + A..W + V.
\t\tif(_state && (is_undefined(_x) || is_undefined(_y)))
\t\t\t_state = false;
'@
                $san = $san.Replace('\t', "`t")
                $t = [regex]::Replace($t, $anchor, ('$0' + $san), 1)
            }
            else { Bad 'No encuentro la linea de _state (alguien edito el script?). Mandamelo para verlo.' }

            # --- paso 3: joystick fallback ---
            $jx = "`t`t`tvar _x = device_mouse_x_to_gui\(jTouchId\);\r?\n`t`t`tvar _y = device_mouse_y_to_gui\(jTouchId\);\r?\n"
            if ($t -match $jx) {
                $jfix = @'
\t\t\t// v80i: coords del dedo del joystick undefined => tratarlas como
\t\t\t// el centro del pad (dirX/dirY = 0: suelta las 4 direcciones, sin
\t\t\t// tocar jTouchId ni re-disparar nada)
\t\t\tif(is_undefined(_x))
\t\t\t\t_x = obj_config.dpadX;
\t\t\tif(is_undefined(_y))
\t\t\t\t_y = obj_config.dpadY;
'@
                $jfix = $jfix.Replace('\t', "`t")
                $t = [regex]::Replace($t, $jx, ('$0' + $jfix), 1)
            }

            [IO.File]::WriteAllText($touchPath, $t)   # UTF-8 SIN BOM
            $t3 = [IO.File]::ReadAllText($touchPath)
            if (($t3 -match 'SLOT-SANITIZE') -and ($t3 -match 'var _inV = _state')) {
                Ok ('v80i instalado en el script (copia vieja en ' + (Split-Path $bak -Leaf) + ').')
            }
            else { Bad ('El fix no quedo escrito; restaura ' + $bak) }
        }
    }
}

# ---------- PASO 5c: BUILD TAG v80i en Draw_64 (verificacion visual) ----------
Write-Host '--- PASO 5c: BUILD TAG v80i en pantalla (prueba del APK) ---'
$drawPath = Join-Path $projRoot 'objects\obj_controls\Draw_64.gml'
if (-not (Test-Path -LiteralPath $drawPath)) { Warn 'No encuentro objects\obj_controls\Draw_64.gml (ruta distinta?). Sin marcador.' }
elseif (([IO.File]::ReadAllText($drawPath)) -match 'v80i BUILD TAG') { Ok 'Draw_64.gml ya tiene el BUILD TAG v80i.' }
else {
    $d = [IO.File]::ReadAllText($drawPath)
    if (-not $d.EndsWith('}')) { Bad 'Draw_64.gml no termina en } como esperaba; no lo toco.' }
    else {
        $dbak = $drawPath + '.bak_' + $stamp
        Copy-Item -LiteralPath $drawPath -Destination $dbak -Force
        $tag = @'
// v80i BUILD TAG: verificacion visual de que el APK lleva ESTE archivo.
// Si la esquina inferior-izquierda NO dice "v80i", el telefono esta
// corriendo un APK viejo (desinstalalo antes de instalar el nuevo).
// Semitransparente, pequeno, solo Android, siempre visible (fuera del
// if del HUD para que se vea aunque el HUD este escondido).
if(isMobile)
{
\tdraw_set_alpha(0.55);
\tdraw_set_halign(fa_left);
\tdraw_text(4, room_height - 14, "v80i");
\tdraw_set_alpha(1);
}
'@
        $tag = $tag.Replace('\t', "`t")
        # se ANEXA despues del } final: nunca se quita el cierre del if
        $d2 = $d + "`n`n" + $tag.TrimEnd("`r","`n")
        [IO.File]::WriteAllText($drawPath, $d2)
        if (([IO.File]::ReadAllText($drawPath)) -match 'v80i BUILD TAG') {
            Ok ('BUILD TAG instalado (copia vieja en ' + (Split-Path $dbak -Leaf) + ').')
        }
        else { Bad ('El marcador no quedo escrito; restaura ' + $dbak) }
    }
}
Write-Host ''

# ---------- PASO 5d: layout v80j del cluster (V abajo, cluster subido) ----------
Write-Host '--- PASO 5d: layout v80j (V abajo del cluster, subido ~44px) ---'
$cfgPath = Join-Path $projRoot 'objects\obj_config\Create_0.gml'
if (-not (Test-Path -LiteralPath $cfgPath)) { Warn 'No encuentro objects\obj_config\Create_0.gml. Layout no aplicado.' }
elseif (([IO.File]::ReadAllText($cfgPath)) -match 'v80j LAYOUT MIGRATION') { Ok 'obj_config ya tiene el layout v80j.' }
else {
    $c = [IO.File]::ReadAllText($cfgPath)
    $bak = $cfgPath + '.bak_' + $stamp
    Copy-Item -LiteralPath $cfgPath -Destination $bak -Force
    $okLayout = $true

    # defaults zTouch(A)/xTouch(B)/cTouch(C): xx y yy nuevos (escala/opacity intactos)
    foreach ($kv in @(
        @{ key='zTouch'; ox=378; nx=336; ny=177 },
        @{ key='xTouch'; ox=416; nx=374; ny=127 },
        @{ key='cTouch'; ox=452; nx=412; ny=177 }
    )) {
        $pat = '(?m)^\t' + $kv.key + ': \{\r?\n\t\txx: ' + $kv.ox + ',\r?\n\t\tyy: [0-9+\-*/ ]+,(\r?\n\t\tscale: 1,\r?\n\t\topacity: 0\.6\r?\n\t\},)'
        $rep = "`t" + $kv.key + ": {`r`n`t`txx: " + $kv.nx + ",`r`n`t`tyy: " + $kv.ny + ",`$1"
        $c2 = [regex]::Replace($c, $pat, $rep, 1)
        if ($c2 -eq $c) { $okLayout = $false; Bad ('default ' + $kv.key + ' (xx ' + $kv.ox + ') no encontrado.') }
        $c = $c2
    }

    # default vMainTouch (V): 378/121 -> 374/227
    $patV = '(?m)^\tvMainTouch: \{\r?\n\t\txx: 378,\r?\n\t\tyy: 121,'
    $c2 = [regex]::Replace($c, $patV, "`tvMainTouch: {`r`n`t`txx: 374,`r`n`t`tyy: 227,", 1)
    if ($c2 -eq $c) { $okLayout = $false; Bad 'default vMainTouch (378/121) no encontrado.' }
    $c = $c2

    # catch del load (guardados pre-v78): mismo default nuevo
    $patC = '(?m)^\t\t_buffer\.vMainTouch = \{\r?\n\t\t\txx: 378,\r?\n\t\t\tyy: 121,'
    $c2 = [regex]::Replace($c, $patC, "`t`t_buffer.vMainTouch = {`r`n`t`t`txx: 374,`r`n`t`t`tyy: 227,", 1)
    if ($c2 -eq $c) { $okLayout = $false; Bad 'catch vMainTouch no encontrado.' }
    $c = $c2

    # migracion layoutVer: insertar justo antes del final del load()
    $mig = @'
	// v80j LAYOUT MIGRATION: los guardados v78-v80i traen el rombo viejo
	// (V arriba en 378,121 y A/B/C abajo). Si la duena no arrastro el
	// cluster a mano (posiciones == viejas por defecto), se reposiciona al
	// layout nuevo (B arriba, V abajo, subido 44px). Si lo movio, se
	// respeta su arrangement y solo se marca layoutVer para no volver a
	// mirar. Cualquier otro boton (W, V pequena, chat, dpad) ni se toca.
	var _layoutVer = 1;
	try { _layoutVer = _buffer.layoutVer; } catch(ex2) { }
	if(_layoutVer < 2)
	{
		var _oldCluster = (bAX == 378 && bAY == 221 && bBX == 416 && bBY == 177
			&& bCX == 452 && bCY == 221
			// V en su default VIEJO (guardado v78-v80i) o en el NUEVO (catch
			// de guardados pre-v78, que ya da 374/227): en ambos casos A/B/C
			// siguen viejos y hay que migrar los 4 juntos (si no, la V nueva
			// caeria encima de la A vieja)
			&& ((bV2X == 378 && bV2Y == 121) || (bV2X == 374 && bV2Y == 227)));
		if(_oldCluster)
		{
			bAX = 336; bAY = 177;
			bBX = 374; bBY = 127;
			bCX = 412; bCY = 177;
			bV2X = 374; bV2Y = 227;
		}
		try { _buffer.layoutVer = 2; } catch(ex3) { }
	}

'@
    # el final del load: nickname validate + cierre + save (con \r?\n)
    $tailPat = '(?m)(^\tglobal\.nickname = scr_nickname_validate\(nickname\);\r?\n^\}\r?\n\r?\n^save = function\(\))'
    $m = [regex]::Match($c, $tailPat)
    if (-not $m.Success) { $okLayout = $false; Bad 'No encontre el final del load() en obj_config.' }
    else { $c = $c.Substring(0, $m.Index) + $mig + $c.Substring($m.Index) }

    # save(): persistir layoutVer tras chatTouch
    $savePat = '(?m)^\t_buffer\.chatTouch\.xx = bChatX;\r?\n^\t_buffer\.chatTouch\.yy = bChatY;\r?\n'
    $m2 = [regex]::Match($c, $savePat)
    if (-not $m2.Success) { $okLayout = $false; Bad 'No encontre el save() de chatTouch.' }
    else {
        $saveAdd = "`t// v80j: layout del cluster aplicado (para no re-migrar)`r`n`t_buffer.layoutVer = 2;`r`n"
        $c = $c.Substring(0, $m2.Index + $m2.Length) + $saveAdd + $c.Substring($m2.Index + $m2.Length)
    }

    if ($okLayout) {
        [IO.File]::WriteAllText($cfgPath, $c)
        if (([IO.File]::ReadAllText($cfgPath)) -match 'v80j LAYOUT MIGRATION') {
            Ok ('layout v80j en obj_config (copia vieja en ' + (Split-Path $bak -Leaf) + ').')
        } else { Bad ('El layout no quedo escrito; restaura ' + $bak) }
    } else { Bad ('obj_config no tocado (restaura ' + $bak + ' si hace falta).') }
}

# init_touch: espejos documentales (lo real vive en obj_config)
$initPath = Join-Path $projRoot 'scripts\scr_controls_init_touch\scr_controls_init_touch.gml'
if (-not (Test-Path -LiteralPath $initPath)) { Warn 'No encuentro scr_controls_init_touch.gml. Espejos no actualizados.' }
elseif (([IO.File]::ReadAllText($initPath)) -match 'v80j') { Ok 'init_touch ya tiene los espejos v80j.' }
else {
    $s = [IO.File]::ReadAllText($initPath)
    $ibak = $initPath + '.bak_' + $stamp
    Copy-Item -LiteralPath $initPath -Destination $ibak -Force
    $okInit = $true
    foreach ($p in @(
        @('bAX = 378;(\r?\n\t)bAY = 196\+25;', 'bAX = 336; // v80j: espejo documental (lo real vive en obj_config)$1bAY = 177;'),
        @('bBX = 416;(\r?\n\t)bBY = 146\+25;', 'bBX = 374; // v80j$1bBY = 127;'),
        @('bCX = 452;(\r?\n\t)bCY = 196\+25;', 'bCX = 412; // v80j$1bCY = 177;'),
        @('bV2X = 378;(\r?\n\t)bV2Y = 121;', 'bV2X = 374; // v80j: V abajo del cluster$1bV2Y = 227;')
    )) {
        $s2 = [regex]::Replace($s, $p[0], $p[1], 1)
        if ($s2 -eq $s) { $okInit = $false; Bad ('init_touch: no encontre ' + $p[0].Split("`r")[0]) }
        $s = $s2
    }
    if ($okInit) {
        [IO.File]::WriteAllText($initPath, $s)
        Ok ('init_touch espejos v80j (copia vieja en ' + (Split-Path $ibak -Leaf) + ').')
    } else { Bad ('init_touch no tocado; restaura ' + $ibak) }
}

# room_menu: mover los 4 handles (bid 1/2/3/10) - por INDICES (el regex
# perezoso sobre 260KB se cuelga; mismo problema tendria en PowerShell)
$roomPath = Join-Path $projRoot 'rooms\room_menu\room_menu.yy'
if (-not (Test-Path -LiteralPath $roomPath)) { Warn 'No encuentro rooms\room_menu\room_menu.yy. Handles no movidos.' }
else {
    $r = [IO.File]::ReadAllText($roomPath)
    if ($r -match '"x":336\.0,"y":177\.0') { Ok 'room_menu ya tiene los handles v80j.' }
    else {
        $rbak = $roomPath + '.bak_' + $stamp
        Copy-Item -LiteralPath $roomPath -Destination $rbak -Force
        $okRoom = $true
        foreach ($mv in @(
            @('1',  '378.0', '221.0', '336.0', '177.0'),
            @('2',  '416.0', '171.0', '374.0', '127.0'),
            @('3',  '452.0', '221.0', '412.0', '177.0'),
            @('10', '378.0', '121.0', '374.0', '227.0')
        )) {
            # localizar el bloque del handle: objectId obj_menu_mobilebutton
            # (no mobilebutton2) cuyo property value sea este bid; el x/y
            # esta tras resourceType GMRInstance del mismo bloque
            $oi = $r.IndexOf('"name":"obj_menu_mobilebutton"')
            $found = $false
            while ($oi -ge 0) {
                $blkEnd = $r.IndexOf('"x":', $oi)
                $blk = $r.Substring($oi, $blkEnd - $oi)
                if ($blk -match ('"value":"' + $mv[0] + '",}') -and $blk -notmatch 'mobilebutton2') {
                    # x/y justo tras este punto
                    $m2 = [regex]::Match($r.Substring($blkEnd, 60), ('"x":' + [regex]::Escape($mv[1]) + ',"y":' + [regex]::Escape($mv[2]) + ',\}'))
                    if ($m2.Success) {
                        $at = $blkEnd + $m2.Index
                        $len = $m2.Length
                        $r = $r.Substring(0, $at) + ('"x":' + $mv[3] + ',"y":' + $mv[4] + ',}') + $r.Substring($at + $len)
                        $found = $true
                        break
                    }
                }
                $oi = $r.IndexOf('"name":"obj_menu_mobilebutton"', $oi + 1)
            }
            if (-not $found) { $okRoom = $false; Bad ('room_menu: no encontre handle bid ' + $mv[0]) }
        }
        if ($okRoom) {
            [IO.File]::WriteAllText($roomPath, $r)
            Ok ('handles del cluster movidos (copia vieja en ' + (Split-Path $rbak -Leaf) + ').')
        } else { Bad ('room_menu no tocado; restaura ' + $rbak) }
    }
}
Write-Host ''

# ---------- PASO 5e: quitar el BUILD TAG v80i ----------
Write-Host '--- PASO 5e: quitar el marcador v80i de pantalla ---'
$drawPath = Join-Path $projRoot 'objects\obj_controls\Draw_64.gml'
if (-not (Test-Path -LiteralPath $drawPath)) { Warn 'No encuentro objects\obj_controls\Draw_64.gml.' }
else {
    $d = [IO.File]::ReadAllText($drawPath)
    $i = $d.IndexOf("`n`n// v80i BUILD TAG:")
    if ($i -lt 0) { Ok 'Draw_64 no tiene marcador (ya limpio).' }
    else {
        $dbak = $drawPath + '.bak_' + $stamp
        Copy-Item -LiteralPath $drawPath -Destination $dbak -Force
        $d2 = $d.Substring(0, $i + 1)
        if ($d2.EndsWith("}")) {
            [IO.File]::WriteAllText($drawPath, $d2)
            if (([IO.File]::ReadAllText($drawPath)) -notmatch 'BUILD TAG') {
                Ok ('Marcador v80i quitado (copia vieja en ' + (Split-Path $dbak -Leaf) + ').')
            } else { Bad ('No se quito del todo; restaura ' + $dbak) }
        }
        else { Bad 'Estructura inesperada al final de Draw_64; no lo toco. Avisa.' }
    }
}
Write-Host ''

# ---------- PASO 6: espacio en disco ----------
Write-Host '--- PASO 6: espacio en disco ---'
$d = Get-PSDrive C
$freeGB = [math]::Round($d.Free / 1GB, 1)
if ($freeGB -lt 5) { Warn ('Solo ' + [string]$freeGB + ' GB libres en C: (Gradle quiere 5 o mas).') } else { Ok ([string]$freeGB + ' GB libres en C:.') }
Write-Host ''

# ---------- PASO 6b: recordatorio antes de probar ----------
Write-Host '--- PASO 6b: antes de probar en el telefono ---'
Info '  1. Recompila desde GameMaker con estos archivos.'
Info '  2. El marcador v80i YA NO aparece (se quito en v80j): si lo ves,'
Info '     el APK es el v80i viejo -> recompila de nuevo.'
Info '  3. Layout nuevo: B arriba, A y C al medio, V ABAJO, cluster ~44px'
Info '     mas arriba. Tu guardado se migra solo si NO moviste los botones'
Info '     a mano (si los moviste, se respetan como los dejaste).'
Write-Host ''

# ---------- FINAL ----------
Write-Host '========================================================='
Write-Host '   RESULTADO'
Write-Host '========================================================='
if ($tmpl) { Ok 'Todo lo arreglable esta arreglado.' }
else { Bad 'Falta reinstalar el runtime (PASO 2) antes de compilar.' }
$choice = Read-Host 'Que hago ahora?  A = compilar e instalar en el telefono  /  B = abrir GameMaker  /  N = nada'
if ($choice -eq 'A' -or $choice -eq 'a') {
    $igor = $null
    if ($runtime) {
        $t = Join-Path $runtime 'bin\igor\windows\x64\Igor.exe'
        if (Test-Path $t) { $igor = $t }
    }
    $bff = Join-Path $env:TEMP 'd2d_build.bff'
    if (-not $igor) { Bad 'No encuentro Igor.exe; compila desde GameMaker (opcion B).' }
    elseif (-not (Test-Path $bff)) { Bad 'No tengo build.bff. Elige B, compila UNA vez desde el IDE, y vuelve a ejecutarme con A.' }
    else {
        $adb = 'C:\Users\AM\AppData\Local\Android\Sdk\platform-tools\adb.exe'
        if (-not (Test-Path $adb)) {
            $g = Get-Command adb -ErrorAction SilentlyContinue
            if ($g) { $adb = $g.Source } else { $adb = $null }
        }
        if ($adb) {
            $devlist = & $adb devices
            $devlist | ForEach-Object { Info $_ }
            $conn = @($devlist | Where-Object { $_ -match 'device\s*$' -and $_ -notmatch 'List of' })
            if ($conn.Count -eq 0) { Warn 'No veo telefono conectado (USB + depuracion USB) o la instalacion final fallara.' }
        }
        else { Warn 'No encuentro adb; sigo igual.' }
        Info 'COMPILANDO (la primera vez descarga Gradle 8.9: 5-15 min extra)...'
        $buildLog = Join-Path $env:TEMP ('d2d_build_' + $stamp + '.txt')
        & $igor -j=8 ('-options=' + $bff) -v -- Android Run 2>&1 | Tee-Object -FilePath $buildLog
        $code = $LASTEXITCODE
        Write-Host ''
        if ($code -eq 0) {
            Ok 'BUILD COMPLETO: APK compilado e instalado en el telefono.'
        }
        else {
            Bad ('Igor devolvio codigo ' + [string]$code + '. Analizando el error real...')
            $raw = Get-Content -LiteralPath $buildLog -Raw
            # ultimas lineas con error javac (el log de gradle muerde las previas)
            $errLines = @($raw -split "`r?`n" | Where-Object { $_ -match 'error:|error :|ERROR' } | Select-Object -First 8)
            $fixedSomething = $false
            if ($errLines.Count -gt 0) {
                Write-Host '  --- errores que reporto javac/gradle ---'
                $errLines | ForEach-Object { Write-Host ('    ' + $_.Trim()) -ForegroundColor Red }
                if ($raw -match 'ms_activity') {
                    Warn 'CAUSA: DisasterServer.java v80c/v80d (ms_activity). Aplico v80g y reintento UNA vez...'
                    $fixedSomething = $true
                }
                elseif ($raw -match 'cannot find symbol.*RunnerActivity|RunnerActivity cannot|import com\.yoyogames\.runner\.RunnerActivity') {
                    Warn 'CAUSA: DisasterServer.java v80e (import RunnerActivity) no existe en runtime-2026.1.0.28. Aplico v80g y reintento UNA vez...'
                    $fixedSomething = $true
                }
                elseif ($raw -match 'gradlew\.bat.*no se puede encontrar|Win32Exception.*gradlew|Could not find gradlew') {
                    Bad 'CAUSA: gradlew.bat borrado por el antivirus. Ve al PASO 3 de arriba y restaura la cuarentena.'
                }
                else { Info 'Error no reconocido: abre ' + $buildLog + ' y mandame las lineas rojas.' }
                if ($fixedSomething) {
                    $j3 = Get-Content -Raw -LiteralPath $javaPath -ErrorAction SilentlyContinue
                    if ($j3 -and $j3 -match 'Class\.forName') { Ok 'El proyecto ya tiene la v80g; el error vino de la cache Gradle. La limpio y reintento...' }
                    else {
                        $jbak2 = $javaPath + '.bak_' + $stamp + '_2'
                        Copy-Item -LiteralPath $javaPath -Destination $jbak2 -Force
                        $javaV80g2 = @'
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
'@
                        Set-Content -LiteralPath $javaPath -Value $javaV80g2 -Encoding ASCII
                    }
                    if ($cacheProj -and (Test-Path -LiteralPath $cacheProj)) {
                        try { Remove-Item -LiteralPath $cacheProj -Recurse -Force -ErrorAction Stop } catch {}
                    }
                    Info 'REINTENTO (un unico reintento automatico)...'
                    $buildLog2 = Join-Path $env:TEMP ('d2d_build_' + $stamp + '_2.txt')
                    & $igor -j=8 ('-options=' + $bff) -v -- Android Run 2>&1 | Tee-Object -FilePath $buildLog2
                    if ($LASTEXITCODE -eq 0) { Ok 'BUILD COMPLETO EN EL REINTENTO: APK compilado e instalado.' }
                    else { Bad ('Sigue fallando. Log completo: ' + $buildLog2 + '  (mandame ese archivo)') }
                }
            }
            else {
                Info 'Sin lineas "error:" en el log (fallo de Igor/gradle arrancando). Log: ' + $buildLog
                if ($raw -match 'Win32Exception|no puede encontrar el archivo') { Bad 'gradlew.bat no existe: antivirus (PASO 3) o runtime daado (PASO 2).' }
            }
        }
    }
}
elseif ($choice -eq 'B' -or $choice -eq 'b') {
    $ide = $null
    $pf = Get-ChildItem 'C:\Program Files' -Directory -Filter 'GameMakerStudio2*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pf) {
        $exe = Get-ChildItem $pf.FullName -Filter '*.exe' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'GameMaker' } | Select-Object -First 1
        if ($exe) { Start-Process $exe.FullName; Ok 'GameMaker abierto: dale a Run/Compile con destino Android.' }
    }
    if (-not $pf) { Warn 'No encontre el exe del IDE; abrelo a mano.' }
}
else { Info 'Ok. Al compilar: .info debe decir v1102, .rouge debe reclamar a Rouge, y la esquina inferior-izquierda debe decir v80i.' }
Info ('Log de esta reparacion: ' + $log)
try { Stop-Transcript | Out-Null } catch {}
Read-Host 'Pulsa Enter para cerrar'
