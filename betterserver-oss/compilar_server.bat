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
echo    1. Compilar cambios            (rapido, uso diario)
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
if not exist "%BUILDDIR%\CMakeCache.txt" (
    echo.
    echo [i] No hay compilacion previa, hago una completa...
    goto build_full
)
call :check_sdl
if "%SDL_OK%"=="0" goto sdl_missing
call :ensure_exe_closed
if "%EXE_BUSY%"=="1" goto build_cancel
echo.
echo Re-aplicando configuracion GUI (BUILD_UI=ON)...
set "PFX=%SDL2:\=/%;%SDL2IMG:\=/%"
cmake -B "%BUILDDIR%" -DBUILD_UI=ON -DCMAKE_PREFIX_PATH="%PFX%"
if errorlevel 1 goto build_fail
echo Compilando cambios...
cmake --build "%BUILDDIR%" --config Release
if errorlevel 1 goto build_fail
call :copy_dlls
call :restore_configs
call :verify_gui
echo.
echo [OK] Listo. Exe actualizado: %EXE%
pause
goto menu

:build_full
call :setup_cmake
if "%CMAKE_OK%"=="0" goto cmake_missing
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
cmake -B "%BUILDDIR%" -DBUILD_UI=ON -DCMAKE_PREFIX_PATH="%PFX%"
if errorlevel 1 goto build_fail
echo Compilando (la primera vez tarda un poco)...
cmake --build "%BUILDDIR%" --config Release
if errorlevel 1 goto build_fail
call :copy_dlls
call :restore_configs
call :verify_gui
echo.
echo [OK] Recompilacion completa terminada. Exe: %EXE%
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
pause
goto menu

:build_cancel
echo.
echo [i] Compilacion cancelada: cierra el DisasterServer.exe y vuelve a intentar.
pause
goto menu
