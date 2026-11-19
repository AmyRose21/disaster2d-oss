@echo off
setlocal EnableExtensions
title DisasterServer - Compilador
color 0B

rem ============================================================
rem  DisasterServer (BetterServer) - Script de compilacion
rem  Guarda este .bat DENTRO de la carpeta betterserver-oss
rem  (la misma carpeta donde esta el CMakeLists.txt raiz)
rem
rem  Si mueves las carpetas de SDL o cambias de Visual Studio,
rem  edita las rutas de la seccion CONFIG mas abajo.
rem
rem  RELAY: este .bat ya incluye todo lo del relay (Relay.c se
rem  compila solo; no hace falta instalar nada extra). Usa la
rem  opcion 7 para poner tu cuenta de relaysc.dr2.site en el
rem  Config.json del server.
rem
rem  v31 (SOLO LO CAMBIADO - arregla el "compila todo cada vez"):
rem   - Compuerta rapida ANTES de compilar: el propio .bat mira
rem     que archivos (.c/.h/.rc, CMakeLists, *.cmake) son mas
rem     nuevos que el exe. Si NO hay ninguno: "Nada que recompilar"
rem     en 1 segundo, sin abrir cmake. Si los hay: te los LISTA y
rem     solo entonces compila (solo esos se recompilan).
rem   - Se desconecta la regeneracion silenciosa de CMake
rem     (-DCMAKE_SUPPRESS_REGENERATION=ON): ni el viejo
rem     "cmake -B de cada vez" ni el ZERO_CHECK de Visual Studio
rem     pueden reescribir los proyectos y provocar un rebuild
rem     completo escondido. Re-configurar solo pasa si cambias la
rem     CONFIG de arriba o editas un CMakeLists.txt.
rem   - Contador tras compilar: "Recompilados: N de M objetos",
rem     para comprobar que solo se compilo lo cambiado.
rem   - Si detecta que recompilo casi TODO con pocos cambios,
rem     te avisa y sugiere el remedio (opcion 2 una vez / reloj).
rem  v30: compilacion paralela (-j todos los nucleos), temporizador,
rem   sello de configuracion y auto-descarga de enet. Ojo: la
rem   PRIMERA vez con v31 re-configura y puede recompilar todo UNA
rem   sola vez (es normal); desde ahi, la opcion 1 va al grano.
rem ============================================================

cd /d "%~dp0"

rem ======================= CONFIG ==============================
set "SDL2=C:\SDL\SDL2-2.32.10"
set "SDL2IMG=C:\SDL\SDL2_image-2.8.12"
set "CMAKE_BIN=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
set "BUILDDIR=build"
set "EXEDIR=%BUILDDIR%\disasterserver\Release"
set "EXE=%EXEDIR%\DisasterServer.exe"
set "BACKUP=config_backup"
set "STAMPFILE=%BUILDDIR%\.configure-stamp"
if not defined NUMBER_OF_PROCESSORS set "NUMBER_OF_PROCESSORS=4"
rem =============================================================

:menu
cls
echo ============================================================
echo        DISASTERSERVER - MENU DE COMPILACION
echo ============================================================
echo.
if exist "%EXE%" (echo    Estado: exe LISTO en %EXE%) else (echo    Estado: sin compilar todavia)
call :relay_status
echo    %RELAY_STATUS%
echo.
echo    1. Compilar cambios            (solo lo que haya cambiado)
echo    2. Limpiar y recompilar TODO   (desde cero)
echo    3. Copiar DLLs de SDL al exe
echo    4. Ejecutar server (GUI)
echo    5. Ejecutar server (consola)
echo    6. Abrir carpeta del exe
echo    7. Configurar RELAY            (relaysc.dr2.site, tu cuenta)
echo    8. Salir
echo.
set "OP="
set /p OP=   Elige una opcion y Enter [1-8]:
if "%OP%"=="1" goto build_fast
if "%OP%"=="2" goto build_full
if "%OP%"=="3" goto dll_menu
if "%OP%"=="4" goto run_gui
if "%OP%"=="5" goto run_console
if "%OP%"=="6" goto open_folder
if "%OP%"=="7" goto relay_config
if "%OP%"=="8" goto :eof
goto menu

:build_fast
call :setup_cmake
if "%CMAKE_OK%"=="0" goto cmake_missing
call :check_enet
if "%ENET_OK%"=="0" goto enet_missing
if not exist "%BUILDDIR%\CMakeCache.txt" (
    echo.
    echo [i] No hay compilacion previa, hago una completa...
    goto build_full
)
call :check_sdl
if "%SDL_OK%"=="0" goto sdl_missing
call :exe_ticks EXE_T0
for /f %%T in ('powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()"') do set "T0=%%T"
echo.
echo Buscando archivos mas nuevos que el exe...
call :need_build
if "%GATE:~0,5%"=="READY" (
    echo [i] Nada que recompilar: ningun archivo cambio desde la
    echo     ultima compilacion ^(no se abre ni cmake ni Visual Studio^).
    powershell -NoProfile -Command "$d=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()-[long]$env:T0; Write-Host ('    Tiempo: {0:n1} s' -f ($d/1000))"
    pause
    goto menu
)
echo [i] %CHGLIST%
call :ensure_exe_closed
if "%EXE_BUSY%"=="1" goto build_cancel
call :need_configure
if "%NEEDCFG%"=="1" (
    echo Configurando ^(CONFIG o CMakeLists cambiaron^): BUILD_UI=ON...
    echo [i] Ojo: re-configurar reescribe los proyectos de Visual
    echo     Studio y esa vez puede recompilar TODO. Solo pasa cuando
    echo     cambia la CONFIG o un CMakeLists.txt, no en el dia a dia.
    cmake -B "%BUILDDIR%" -DBUILD_UI=ON -DCMAKE_PREFIX_PATH="%PFX%" -DCMAKE_SUPPRESS_REGENERATION=ON
    if errorlevel 1 goto build_fail
    >"%STAMPFILE%" echo BUILD_UI=ON;PFX=%PFX%;SUPPRESS=1
) else (
    echo [i] Configuracion y proyectos intactos: directo a compilar.
)
echo Compilando cambios ^(paralelo, -j %NUMBER_OF_PROCESSORS%^)...
cmake --build "%BUILDDIR%" --config Release --parallel %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto build_fail
call :exe_ticks EXE_T1
call :build_report
if "%EXE_T0%"=="%EXE_T1%" (
    echo.
    echo [i] Nada nuevo que enlazar: el exe quedo igual.
    pause
    goto menu
)
call :copy_dlls
call :restore_configs
call :verify_gui
echo.
powershell -NoProfile -Command "$d=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()-[long]$env:T0; Write-Host ('[OK] Listo en {0:n1} s. Exe actualizado: %EXE%' -f ($d/1000))"
pause
goto menu

:build_full
call :setup_cmake
if "%CMAKE_OK%"=="0" goto cmake_missing
call :check_enet
if "%ENET_OK%"=="0" goto enet_missing
call :check_sdl
if "%SDL_OK%"=="0" goto sdl_missing
call :ensure_exe_closed
if "%EXE_BUSY%"=="1" goto build_cancel
call :backup_configs
echo.
echo Limpiando compilacion anterior...
if exist "%BUILDDIR%" rmdir /s /q "%BUILDDIR%"
echo Configurando proyecto (GUI activada)...
set "PFX=%SDL2:\=/%;%SDL2IMG:\=/%"
cmake -B "%BUILDDIR%" -DBUILD_UI=ON -DCMAKE_PREFIX_PATH="%PFX%" -DCMAKE_SUPPRESS_REGENERATION=ON
if errorlevel 1 goto build_fail
>"%STAMPFILE%" echo BUILD_UI=ON;PFX=%PFX%;SUPPRESS=1
for /f %%T in ('powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()"') do set "T0=%%T"
echo Compilando TODO ^(paralelo, -j %NUMBER_OF_PROCESSORS%; la primera vez tarda un poco^)...
cmake --build "%BUILDDIR%" --config Release --parallel %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto build_fail
call :build_report
call :copy_dlls
call :restore_configs
call :verify_gui
echo.
powershell -NoProfile -Command "$d=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()-[long]$env:T0; Write-Host ('[OK] Recompilacion completa en {0:n1} s. Exe: %EXE%' -f ($d/1000))"
pause
goto menu

:dll_menu
call :check_sdl
if "%SDL_OK%"=="0" goto sdl_missing
call :copy_dlls
pause
goto menu

:run_gui
if not exist "%EXE%" goto exe_missing
echo.
echo Ejecutando server con GUI...
start "" "%EXE%"
goto menu

:run_console
if not exist "%EXE%" goto exe_missing
echo.
echo Ejecutando server en consola...
start "" "%EXE%" --nogui
goto menu

:open_folder
if not exist "%EXEDIR%" (
    echo.
    echo [ERROR] Aun no hay carpeta de compilacion. Compila primero.
    pause
    goto menu
)
start "" explorer "%~dp0%EXEDIR%"
goto menu

:relay_config
if not exist "%~dp0configurar_relay.ps1" (
    echo.
    echo [ERROR] No encuentro configurar_relay.ps1 junto a este .bat.
    pause
    goto menu
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configurar_relay.ps1" -StartDir "%~dp0"
pause
goto menu

rem ==================== SUBRUTINAS =============================

:setup_cmake
set "CMAKE_OK=1"
if exist "%CMAKE_BIN%\cmake.exe" set "PATH=%CMAKE_BIN%;%PATH%"
where cmake >nul 2>&1
if errorlevel 1 set "CMAKE_OK=0"
goto :eof

rem ---- v31: COMPUERTA. Que archivos son mas nuevos que el exe?
rem ---- Sale una linea "READY" o "BUILD#lista legible#numero".
rem ---- (El %GATE% nunca se imprime tal cual: lleva el separador
rem ----  # dentro y solo se usa troceado o via %CHGLIST%/%NCHG%.
rem ----  Si PowerShell fallara, el valor por defecto es BUILD:
rem ----  se compila igual, nunca se salta una compilacion.)
:need_build
set "GATE=BUILD#no pude comprobar los archivos; compilo igual#999"
set "CHGLIST=Cambios detectados: no pude comprobar los archivos; compilo igual"
set "NCHG=999"
if not exist "%EXE%" (
    set "GATE=BUILD#sin compilacion previa#999"
    set "CHGLIST=Cambios detectados: sin compilacion previa"
    goto :eof
)
for /f "usebackq tokens=1-3 delims=#" %%a in (`powershell -NoProfile -Command "$e=(Get-Item -LiteralPath '%EXE%').LastWriteTimeUtc; $ch=Get-ChildItem -Recurse -File -Path disasterserver,include,enet -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.c','.h','.rc' -and $_.LastWriteTimeUtc -gt $e }; $cm=Get-ChildItem -Recurse -File -Path . -Include CMakeLists.txt,*.cmake -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.LastWriteTimeUtc -gt $e }; $n=@($ch)+@($cm) | Sort-Object LastWriteTimeUtc -Descending; if($n.Count -eq 0){'READY'}else{$names=($n | Select-Object -First 5 | ForEach-Object {$_.Name}) -join ', '; $extra=''; if($n.Count -gt 5){$extra=' (y ' + ($n.Count-5) + ' mas)'}; 'BUILD#Cambios detectados: ' + $names + $extra + '#' + $n.Count}"`) do (
    set "GATE=%%a"
    set "CHGLIST=%%b"
    set "NCHG=%%c"
)
goto :eof

rem ---- v30/v31: hay que volver a configurar? Solo si cambio la
rem ---- CONFIG del .bat (sello de contenido) o si un CMakeLists.txt/
rem ---- *.cmake es mas nuevo que la ULTIMA VEZ que configuramos.
rem ---- OJO: se compara contra el sello, NO contra CMakeCache.txt:
rem ---- cmake no reescribe los archivos si el contenido no cambio
rem ---- (verificado), asi que el cache puede quedar mas viejo que
rem ---- un CMakeLists recien re-configurado y la regla daria
rem ---- falsos positivos eternos. El sello SI se escribe siempre
rem ---- tras cada configure. Con SUPPRESS_REGENERATION nadie mas
rem ---- re-configura solo: este es el unico sitio que decide.
:need_configure
set "NEEDCFG=1"
set "PFX=%SDL2:\=/%;%SDL2IMG:\=/%"
set "CFGKEY=BUILD_UI=ON;PFX=%PFX%;SUPPRESS=1"
if not exist "%STAMPFILE%" goto :eof
set "STAMP="
for /f "usebackq delims=" %%L in ("%STAMPFILE%") do set "STAMP=%%L"
if not "%STAMP%"=="%CFGKEY%" goto :eof
set "NEEDCFG=0"
set "CMNEW=0"
for /f "usebackq delims=" %%N in (`powershell -NoProfile -Command "$c=(Get-Item -LiteralPath '%STAMPFILE%').LastWriteTimeUtc; $x=Get-ChildItem -Recurse -File -Path . -Include CMakeLists.txt,*.cmake -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.LastWriteTimeUtc -gt $c }; if($x){'1'}else{'0'}"`) do set "CMNEW=%%N"
if "%CMNEW%"=="1" set "NEEDCFG=1"
goto :eof

rem ---- v30: la carpeta enet es un submodulo; si falta, bajarla ----
:check_enet
set "ENET_OK=1"
if exist "%~dp0enet\CMakeLists.txt" goto :eof
echo.
echo [i] Falta la carpeta enet ^(submodulo^). Descargandola una sola vez...
where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Necesito git para descargar enet y no esta en el PATH.
    echo         O instala git, o bajala a mano dentro de esta carpeta:
    echo         git clone https://github.com/lsalzman/enet enet
    set "ENET_OK=0"
    goto :eof
)
git clone --depth 1 https://github.com/lsalzman/enet "%~dp0enet"
if errorlevel 1 (
    echo [ERROR] No pude descargar enet (revisa tu internet).
    echo         Bajala a mano: git clone https://github.com/lsalzman/enet enet
    set "ENET_OK=0"
)
goto :eof

rem ---- v30: ticks (100 ns) de la ultima escritura del exe, para
rem ---- saber si el rebuild toco el binario. 0 si aun no existe. ----
:exe_ticks
set "%~1=0"
if not exist "%EXE%" goto :eof
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "try{(Get-Item -LiteralPath '%EXE%').LastWriteTimeUtc.Ticks}catch{0}"`) do set "%~1=%%T"
goto :eof

rem ---- v31: informe tras compilar: cuantos objetos se han
rem ---- recompilado de los M que hay. Si recompilo casi TODO
rem ---- habiendo pocos cambios (<=3), avisa con el remedio. ----
:build_report
powershell -NoProfile -Command "$t0=[DateTimeOffset]::FromUnixTimeMilliseconds($env:T0).LocalDateTime; $all=Get-ChildItem -Recurse -Filter *.obj -Path '%BUILDDIR%' -ErrorAction SilentlyContinue; $n=@($all | Where-Object {$_.LastWriteTime -gt $t0}).Count; $m=@($all).Count; Write-Host ('    Recompilados: ' + $n + ' de ' + $m + ' objetos'); if($m -gt 0 -and $n -ge [math]::Ceiling($m*0.8) -and ([int]$env:NCHG) -le 3){exit 1}; exit 0"
if errorlevel 1 (
    echo.
    echo [!] Recompilo casi TODO pese a haber pocos cambios. Eso pasa
    echo     cuando algo reescribe los proyectos de Visual Studio o el
    echo     reloj del PC quedo desordenado. Remedio:
    echo     1. Corre la opcion 2 UNA vez ^(Limpiar TODO^) y luego la 1.
    echo     2. Si vuelve a pasar, revisa la fecha y hora del PC.
)
goto :eof

rem ---- RELAY: leer estado del relay desde el Config.json del exe ----
:relay_status
set "RELAY_STATUS=RELAY: sin Config.json (ejecuta el server una vez)"
if not exist "%EXEDIR%\Config.json" goto :eof
for /f "usebackq delims=" %%R in (`powershell -NoProfile -Command "try{$j=Get-Content -Raw -LiteralPath '%EXEDIR%\Config.json'|ConvertFrom-Json; if($j.relay -and $j.relay.enabled){$u=$j.relay.username; if(-not $u){$u='(anonimo)'}; 'RELAY: ACTIVO -> ' + $j.relay.directory_host + ':' + $j.relay.directory_port + '  cuenta: ' + $u}else{'RELAY: desactivado (opcion 7 para activarlo)'}}catch{'RELAY: desactivado (opcion 7 para activarlo)'}"`) do set "RELAY_STATUS=%%R"
goto :eof

rem ---- El server esta corriendo? Windows bloquea el exe si es asi ----
:ensure_exe_closed
set "EXE_BUSY=0"
tasklist /fi "imagename eq DisasterServer.exe" 2>nul | find /i "DisasterServer.exe" >nul
if errorlevel 1 goto :eof
echo.
echo [!] El DisasterServer.exe esta corriendo y Windows bloquea el
echo     archivo: no se puede recompilar hasta cerrarlo.
echo     (NO hace falta borrar el exe, solo cerrarlo)
set "OP2="
set /p OP2=     Cerrar el server ahora? [S/N]:
if /i not "%OP2%"=="S" (
    set "EXE_BUSY=1"
    goto :eof
)
taskkill /im "DisasterServer.exe" /f >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No pude cerrar el proceso. Cierralo a mano y reintenta.
    set "EXE_BUSY=1"
) else (
    echo [i] Server cerrado.
    timeout /t 1 /nobreak >nul
)
goto :eof

:check_sdl
set "SDL_OK=1"
if not exist "%SDL2%\cmake\sdl2-config.cmake" set "SDL_OK=0"
if not exist "%SDL2IMG%\cmake\sdl2_image-config.cmake" set "SDL_OK=0"
goto :eof

:backup_configs
if not exist "%EXEDIR%\Config.json" goto :eof
if not exist "%BACKUP%" mkdir "%BACKUP%"
copy /y "%EXEDIR%\Config.json" "%BACKUP%\" >nul
copy /y "%EXEDIR%\Operators.json" "%BACKUP%\" >nul 2>&1
copy /y "%EXEDIR%\Bans.json" "%BACKUP%\" >nul 2>&1
copy /y "%EXEDIR%\Timeouts.json" "%BACKUP%\" >nul 2>&1
echo [i] Config del server respaldada en la carpeta %BACKUP%
goto :eof

:restore_configs
if not exist "%BACKUP%\Config.json" goto :eof
if exist "%EXEDIR%\Config.json" goto :eof
copy /y "%BACKUP%\*.json" "%EXEDIR%\" >nul
echo [i] Config del server restaurada (anticheat, ops, bans...)
goto :eof

:copy_dlls
if not exist "%EXEDIR%" mkdir "%EXEDIR%"
copy /y "%SDL2%\lib\x64\*.dll" "%EXEDIR%\" >nul
copy /y "%SDL2IMG%\lib\x64\*.dll" "%EXEDIR%\" >nul
copy /y "%SDL2IMG%\lib\x64\optional\*.dll" "%EXEDIR%\" >nul 2>&1
echo [i] DLLs de SDL copiados junto al exe
goto :eof

rem ---- Verificar que el exe salio con GUI SDL (subsystem PE = 2) ----
rem ---- Si sale 3 = consola (cmd): la GUI se pierde. Aviso gordo. ----
:verify_gui
set "SUBSYS=0"
if not exist "%EXE%" goto :eof
for /f "usebackq delims=" %%S in (`powershell -NoProfile -Command "try{$b=[IO.File]::ReadAllBytes('%EXE%');$o=[BitConverter]::ToInt32($b,0x3C);[BitConverter]::ToUInt16($b,$o+92)}catch{0}"`) do set "SUBSYS=%%S"
if "%SUBSYS%"=="2" (
    echo [OK] Exe GUI verificado ^(ventana SDL, ~770 KB^).
) else (
    echo.
    echo [!] OJO: el exe salio en modo CONSOLA ^(cmd^), sin la ventana SDL.
    echo     Ejecuta la opcion 2 ^(Limpiar y recompilar TODO^) para recuperar
    echo     la GUI. Si ya hiciste la 2 y sigue saliendo consola, revisa las
    echo     rutas SDL2 / SDL2IMG de la seccion CONFIG de este .bat.
)
goto :eof

rem ==================== MENSAJES DE ERROR ======================

:cmake_missing
echo.
echo [ERROR] No encuentro cmake.
echo        Revisa la variable CMAKE_BIN dentro de este .bat
echo        o reinstala Build Tools con las herramientas CMake.
pause
goto menu

:enet_missing
echo.
echo [ERROR] No pude conseguir la carpeta enet (submodulo del server).
echo        Bajala a mano, DENTRO de betterserver-oss:
echo        git clone https://github.com/lsalzman/enet enet
echo        y vuelve a intentar la compilacion.
pause
goto menu

:sdl_missing
echo.
echo [ERROR] No encuentro SDL2 en:
echo        %SDL2%
echo        %SDL2IMG%
echo        Descarga los 2 zip devel de SDL y extraelos en C:\SDL
echo        o edita las rutas SDL2 / SDL2IMG dentro de este .bat.
pause
goto menu

:exe_missing
echo.
echo [ERROR] El exe no existe todavia. Compila primero (opcion 1 o 2).
pause
goto menu

:build_fail
echo.
echo [ERROR] La compilacion fallo. Mira el ultimo mensaje de arriba.
echo        Si el error menciona CMakeCache.txt / "different directory",
echo        la carpeta se movio de sitio: usa la opcion 2 (Limpiar TODO).
pause
goto menu

:build_cancel
echo.
echo [i] Compilacion cancelada: cierra el DisasterServer.exe y vuelve a intentar.
pause
goto menu
