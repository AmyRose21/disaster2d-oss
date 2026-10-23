@echo off
title Limpieza de instalaciones antiguas (Amy v100 / Amy Canon vieja)
cd /d "%~dp0"
echo.
echo Este script borra restos de instalaciones anteriores del personaje.
echo Debe ejecutarse en la RAIZ del proyecto (donde esta el .yyp).
echo.
pause
echo Borrando carpetas v100 antiguas...
for /d %%D in ("sprites\*_v100*") do (echo   - %%D & rmdir /s /q "%%D")
for /d %%D in ("objects\*_v100*") do (echo   - %%D & rmdir /s /q "%%D")
for /d %%D in ("scripts\*_v100*") do (echo   - %%D & rmdir /s /q "%%D")
for /d %%D in ("sprites\Amy Canon" "objects\Player" ) do @rem sin tocar
echo Borrando carpetas canon antiguas de sesiones previas (se recolocaran al copiar la v2)...
echo.
echo Listo. Ahora copia el contenido de esta carpeta sobre el proyecto
echo (aceptando reemplazar todo) y abre el .yyp en GameMaker.
pause
