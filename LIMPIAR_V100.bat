@echo off
rem ============================================================
rem  LIMPIAR_V100.bat - Borra restos de la version anterior
rem  del personaje ("Amy v100"). Ejecutar DESPUES de extraer el
rem  contenido de amy_canon_cliente/ sobre el proyecto.
rem ============================================================
cd /d "%~dp0"
echo Buscando restos de la version anterior (Amy v100)...
set FOUND=0
for /d %%D in ("sprites\*_v100") do (
    echo   - Borrando sprites\%%~nxD
    rmdir /s /q "%%D"
    set FOUND=1
)
if exist "objects\obj_amy_v100" (
    echo   - Borrando objects\obj_amy_v100
    rmdir /s /q "objects\obj_amy_v100"
    set FOUND=1
)
if "%FOUND%"=="0" (
    echo   No habia restos. Todo limpio.
) else (
    echo   Limpieza terminada.
)
echo.
echo Ya puedes abrir el proyecto en GameMaker y compilar.
pause
