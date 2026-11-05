@echo off
chcp 65001 >nul
title Actualizar disaster2d-oss a v5.1 y hacer push
cd /d "%~dp0"

echo ============================================================
echo  v5.1 - Copias propias (Sally Canon / Vanilla)
echo         + LMS multi-cancion + Suite TD2D v5.2
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

git status --porcelain | findstr /r "^[ MADRCU?][MDU?]" >nul
if not errorlevel 1 (
    echo.
    echo [!] Tienes cambios sin guardar en el repo.
    echo     Hazles commit o "git stash" antes de aplicar el parche.
    echo.
    git status --short
    echo.
    pause
    exit /b 1
)

echo [2/4] Aplicando el parche v5.1...
git am --3way "%~dp0v5_1_disaster2d.patch"
if errorlevel 1 (
    echo    git am fallo, intentando git apply --3way...
    git am --abort >nul 2>nul
    git apply --3way "%~dp0v5_1_disaster2d.patch"
    if errorlevel 1 (
        echo.
        echo [X] No se pudo aplicar el parche. Posibles causas:
        echo     - Tu repo ya tiene la v5.1 ^(nada que hacer^)
        echo     - Tu repo divergio del historial de GitHub
        echo     Mira LEEME_V5_1.txt para aplicarlo a mano.
        pause
        exit /b 1
    )
    git add -A
    git commit -q -m "v5.1: copias propias Sally Canon/Vanilla + LMS multi-cancion + Suite v5.2"
)

echo [3/4] Push a GitHub ^(origin main^)...
git push origin main
if errorlevel 1 (
    echo.
    echo [!] El push fallo ^(sesion caducada o sin permisos^).
    echo     Solucion rapida: abre "Git Bash" en esta carpeta y ejecuta:
    echo         git push origin main
    echo     ^(te pedira tu usuario y token de GitHub^)
) else (
    echo     PUSH OK
)

echo.
echo [4/4] Recuerda:
echo     - Abre el proyecto en GameMaker y dale F5.
echo     - Recompila el server: betterserver-oss\compilar_server.bat
echo       y reinicialo ^(el reloj y la cancion del show los manda el^).
echo     - El Suite_TD2D.html de dentro del repo ya es la v5.2.
echo.
echo Detalles en LEEME_V5_1.txt
pause
