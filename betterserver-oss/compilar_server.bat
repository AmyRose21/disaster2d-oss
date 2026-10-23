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
echo.
echo    1. Compilar cambios            (rapido, uso diario)
echo    2. Limpiar y recompilar TODO   (desde cero)
echo    3. Copiar DLLs de SDL al exe
echo    4. Ejecutar server (GUI)
echo    5. Ejecutar server (consola)
echo    6. Abrir carpeta del exe
echo    7. Salir
echo.
set "OP="
set /p OP=   Elige una opcion y Enter [1-7]: 
if "%OP%"=="1" goto build_fast
if "%OP%"=="2" goto build_full
if "%OP%"=="3" goto dll_menu
if "%OP%"=="4" goto run_gui
if "%OP%"=="5" goto run_console
if "%OP%"=="6" goto open_folder
if "%OP%"=="7" goto :eof
goto menu

:build_fast
call :setup_cmake
if "%CMAKE_OK%"=="0" goto cmake_missing
if not exist "%BUILDDIR%\CMakeCache.txt" (
    echo.
    echo [i] No hay compilacion previa, hago una completa...
    goto build_full
)
echo.
echo Compilando cambios...
cmake --build "%BUILDDIR%" --config Release
if errorlevel 1 goto build_fail
call :copy_dlls
call :restore_configs
echo.
echo [OK] Listo. Exe actualizado: %EXE%
pause
goto menu

:build_full
call :setup_cmake
if "%CMAKE_OK%"=="0" goto cmake_missing
call :check_sdl
if "%SDL_OK%"=="0" goto sdl_missing
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

rem ==================== SUBRUTINAS =============================

:setup_cmake
set "CMAKE_OK=1"
if exist "%CMAKE_BIN%\cmake.exe" set "PATH=%CMAKE_BIN%;%PATH%"
where cmake >nul 2>&1
if errorlevel 1 set "CMAKE_OK=0"
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
