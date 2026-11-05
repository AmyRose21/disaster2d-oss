@echo off
chcp 65001 >nul
title Actualizar disaster2d-oss a v5.3 - Show LMS por personaje (SIN push)
cd /d "%~dp0"

echo ============================================================
echo  v5.3 - SHOW LMS POR PERSONAJE
echo         musica por personaje · sin musica = sin show
echo         Sonic conserva sus pasivas personales (bloqueo/stuns)
echo         + Suite TD2D v5.3 (modulo Show LMS con lista)
echo.
echo   ESTE .bat NO SUBE NADA A GITHUB. El push lo haces TU.
echo ============================================================
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo [X] Necesitas Git instalado ^(https://git-scm.com^).
    pause
    exit /b 1
)

echo [1/4] Comprobando el repo...
git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [X] Este .bat debe vivir DENTRO de tu carpeta del repo
    echo     ^(la que contiene "Sonicexe The Disaster 2D Remake.yyp"^).
    pause
    exit /b 1
)

git diff --quiet HEAD --
if errorlevel 1 (
    echo.
    echo [!] Tienes cambios sin guardar en archivos del repo.
    echo     Hazles commit o "git stash" antes de aplicar el parche.
    echo     ^(Archivos nuevos sin trackear, como esta misma carpeta
    echo      v5_3_git/, no molestan.^)
    echo.
    git diff --name-only HEAD
    echo.
    pause
    exit /b 1
)

echo [2/4] Aplicando el parche v5.3...
git am --3way "%~dp0v5_3_disaster2d.patch"
if errorlevel 1 (
    echo    git am fallo, intentando git apply --3way...
    git am --abort >nul 2>nul
    git apply --3way "%~dp0v5_3_disaster2d.patch"
    if errorlevel 1 (
        echo.
        echo [X] No se pudo aplicar el parche. Posibles causas:
        echo     - Tu repo ya tiene la v5.3 ^(nada que hacer^)
        echo     - Tus archivos LMS cambiaron respecto a la v5.1 del repo
        echo     En ese caso: abre el Suite TD2D nuevo y usa el boton
        echo     "Actualizar base a v5.3" del modulo Show LMS ^(parchea solo^).
        echo     Mira LEEME_V5_3.txt para hacerlo a mano.
        pause
        exit /b 1
    )
    git add -A
    git commit -q -m "v5.3: Show LMS por personaje (musica por personaje, sin musica no aplica) + Suite v5.3"
)

echo [3/4] Verificando...
python "%~dp0validate_v5_3.py" . 2>nul || py "%~dp0validate_v5_3.py" . 2>nul || echo     (sin Python: pasa la comprobacion manual del LEEME)

echo.
echo [4/4] LISTO. El commit ya esta hecho en TU repo local.
echo.
echo   EL PUSH ES TUYO^:  git push origin main
echo.
echo   Recuerda recompilar el server ^(betterserver-oss/compilar_server.bat^)
echo   y el cliente ^(F5 en GameMaker^).
echo.
pause
