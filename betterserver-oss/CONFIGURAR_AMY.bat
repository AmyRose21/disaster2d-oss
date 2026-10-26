@echo off
setlocal
title Configurador Amy Canon

echo.
echo  ===============================================
echo    CONFIGURADOR AMY CANON - PERSONAJE RESERVADO
echo  ===============================================
echo.
echo  Este programa configura TODO automaticamente:
echo    - encuentra el Config.json de tu server
echo    - genera tu frase secreta (o usas la tuya)
echo    - la escribe en el Config.json
echo    - crea el archivo amy_canon.token en tu PC
echo    - se verifica solo al final
echo.
echo  No necesita permisos de administrador.
echo.

where powershell >nul 2>nul
if errorlevel 1 (
    echo  [ERROR] Este sistema no tiene PowerShell. Abortando.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0configurar_amy.ps1" (
    echo  [ERROR] Falta el archivo configurar_amy.ps1 junto a este .bat
    echo.
    echo  Si estas viendo esto desde DENTRO del zip: extraelo primero
    echo  ^(clic derecho al zip -^> "Extraer todo..."^) y ejecuta el .bat
    echo  desde la carpeta extraida, no desde dentro del zip.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configurar_amy.ps1"
if errorlevel 1 (
    echo.
    echo  [AVISO] El configurador termino con un error.
    echo  Revisa los mensajes de arriba; si no entiendes el error,
    echo  hazle una captura de pantalla y mandasela a Z.
    echo.
    pause
) else (
    echo.
    echo  Listo. Recuerda: REINICIA el server antes de probar.
)

endlocal
