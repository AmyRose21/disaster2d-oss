# ============================================================
#  configurar_amy.ps1
#  Configurador AUTOMATICO del personaje reservado "Amy Canon"
#
#  Hace todo y se verifica solo:
#    1. Encuentra el Config.json de tu server
#    2. Escribe tu frase secreta ahi (clave amy_canon_token)
#    3. Crea  C:\Users\<tu_usuario>\amy_canon.token  con la misma frase
#    4. Verifica que ambas copias quedaron IDENTICAS
#
#  Unico paso manual al final: reiniciar el server.
#  Compatible con Windows PowerShell 5.1 (Windows 10/11 de fabrica).
# ============================================================

$ErrorActionPreference = "Stop"
$rc = 0
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$utf8sinBOM = New-Object System.Text.UTF8Encoding($false)

Write-Host ""
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host "   CONFIGURADOR AMY CANON  (personaje reservado)"   -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Esto configura TODO lo de la frase secreta:"
Write-Host "   1. La escribe en el Config.json de tu server"
Write-Host "   2. Crea el archivo  amy_canon.token  en tu PC"
Write-Host "   3. Verifica que ambas copias quedaron identicas"
Write-Host ""

# ------------------------------------------------------------
# PASO 1: encontrar el Config.json del server
# ------------------------------------------------------------
Write-Host "--- PASO 1 de 4: buscar el Config.json del server ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "Arrastra aqui la CARPETA de tu server y presiona Enter."
Write-Host "(tambien sirve pegar la ruta completa, o la del DisasterServer.exe)"
Write-Host "Si presionas Enter sin escribir nada, busco Config.json"
Write-Host "alrededor de este programa."
Write-Host ""

$configs = @()

for ($intento = 1; $intento -le 3; $intento++) {
    $respuesta = Read-Host "Carpeta del server"
    $respuesta = "$respuesta".Trim().Trim('"').Trim()

    if ($respuesta -eq "") {
        Write-Host "Buscando Config.json cerca de este programa..."
        $configs = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter "Config.json" -File -Recurse -Depth 5 -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }
    elseif (Test-Path -LiteralPath $respuesta -PathType Leaf) {
        $item = Get-Item -LiteralPath $respuesta
        if ($item.Extension -eq ".exe") {
            $configs = @(Get-ChildItem -LiteralPath $item.DirectoryName -Filter "Config.json" -File -Recurse -Depth 5 -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        }
        elseif ($item.Name -ieq "Config.json") {
            $configs = @($item.FullName)
        }
        else {
            Write-Host "[!] Ese archivo no es un Config.json ni un exe del server." -ForegroundColor Yellow
            continue
        }
    }
    elseif (Test-Path -LiteralPath $respuesta -PathType Container) {
        if ($respuesta.Length -le 3) {
            Write-Host "[!] No puedo buscar en toda una unidad (ej: C:\)." -ForegroundColor Yellow
            Write-Host "    Arrastra la carpeta CONCRETA de tu server." -ForegroundColor Yellow
            continue
        }
        $configs = @(Get-ChildItem -LiteralPath $respuesta -Filter "Config.json" -File -Recurse -Depth 5 -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }
    else {
        Write-Host "[!] Esa ruta no existe. Revisala o arrastra de nuevo." -ForegroundColor Yellow
        continue
    }

    if ($configs.Count -gt 0) { break }
    Write-Host "[!] No encontre ningun Config.json ahi." -ForegroundColor Yellow
    Write-Host "    Pista: es la carpeta donde corre tu DisasterServer"
    Write-Host "    (donde esta el .exe; si lo lanzas desde Visual Studio,"
    Write-Host "    suele estar en out\build\...\disasterserver\)."
}

if ($configs.Count -eq 0) {
    Write-Host ""
    Write-Host "[X] No pude encontrar ningun Config.json. No se configuro nada." -ForegroundColor Red
    Write-Host "    Pista: arranca el server una vez y fijate en que carpeta"
    Write-Host "    crea el Config.json; luego arrastra ESA carpeta aqui."
    Read-Host "Presiona Enter para cerrar"
    exit 1
}

$configs = @($configs | Sort-Object -Unique)

Write-Host ""
Write-Host "Encontre $($configs.Count) Config.json:" -ForegroundColor Green
foreach ($c in $configs) {
    $dir = Split-Path -Parent $c
    $exe = Get-ChildItem -LiteralPath $dir -Filter "DisasterServer*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exe) {
        Write-Host "   [con server al lado]  $c" -ForegroundColor Green
    }
    else {
        Write-Host "   [sin exe cerca]       $c" -ForegroundColor Yellow
    }
}
Write-Host ""

if ($configs.Count -gt 1) {
    $conf = Read-Host "Hay varios. Escribir la frase en TODOS? (S/n)"
    if ("$conf".Trim().ToLower() -eq "n") {
        Write-Host "Cancelado. Vuelve a ejecutar y arrastra SOLO la carpeta"
        Write-Host "buena del server (la que tiene el DisasterServer.exe)."
        Read-Host "Presiona Enter para cerrar"
        exit 1
    }
}

# ------------------------------------------------------------
# PASO 2: la frase secreta
# ------------------------------------------------------------
Write-Host ""
Write-Host "--- PASO 2 de 4: tu frase secreta ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opciones:"
Write-Host "  - Escribe tu propia frase: solo letras (a-z, A-Z),"
Write-Host "    numeros (0-9) y guiones (-). De 4 a 64 caracteres."
Write-Host "  - O presiona Enter y genero una segura al azar."
Write-Host ""

$frase = ""
for ($intento = 1; $intento -le 5; $intento++) {
    $frase = Read-Host "Frase secreta"
    $frase = "$frase".Trim()
    if ($frase -eq "") {
        $frase = "amy-" + (Get-Random -Minimum 10000 -Maximum 99999) + "-" + (Get-Random -Minimum 10000 -Maximum 99999) + "-" + (Get-Random -Minimum 10000 -Maximum 99999)
        break
    }
    if ($frase -match '^[A-Za-z0-9\-]{4,64}$') { break }
    Write-Host "[!] Frase invalida (solo letras, numeros y guiones; 4 a 64)." -ForegroundColor Yellow
    $frase = ""
}
if ($frase -eq "") {
    $frase = "amy-" + (Get-Random -Minimum 10000 -Maximum 99999) + "-" + (Get-Random -Minimum 10000 -Maximum 99999) + "-" + (Get-Random -Minimum 10000 -Maximum 99999)
}

Write-Host ""
Write-Host "   TU FRASE SECRETA ES:" -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "      $frase" -ForegroundColor Yellow
Write-Host ""
Write-Host "   (No hace falta apuntarla: queda escrita en los archivos" -ForegroundColor DarkGray
Write-Host "    y ademas se guarda una copia al final.)" -ForegroundColor DarkGray
Write-Host ""

# ------------------------------------------------------------
# PASO 3: escribir
# ------------------------------------------------------------
Write-Host "--- PASO 3 de 4: escribiendo ---" -ForegroundColor Cyan
$configsOk = @()

foreach ($c in $configs) {
    try {
        $raw = [System.IO.File]::ReadAllText($c)
        $patron = '"amy_canon_token"\s*:\s*"[^"]*"'
        if ($raw -match $patron) {
            $nuevo = $raw -replace $patron, ('"amy_canon_token": "' + $frase + '"')
        }
        else {
            $i = $raw.IndexOf('{')
            if ($i -lt 0) {
                Write-Host "[X] $c no parece un JSON valido. Saltado." -ForegroundColor Red
                continue
            }
            $nuevo = $raw.Substring(0, $i + 1) + "`r`n`t`"amy_canon_token`": `"$frase`"," + $raw.Substring($i + 1)
        }
        Copy-Item -LiteralPath $c -Destination "$c.bak-$stamp" -Force
        [System.IO.File]::WriteAllText($c, $nuevo, $utf8sinBOM)
        Write-Host "[+] Config.json actualizado:  $c" -ForegroundColor Green
        $configsOk += $c
    }
    catch {
        Write-Host "[X] Error escribiendo $c : $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($configsOk.Count -eq 0) {
    Write-Host ""
    Write-Host "[X] No se pudo actualizar ningun Config.json." -ForegroundColor Red
    Write-Host "    No se cambio nada mas. Haz una captura de este error."
    Read-Host "Presiona Enter para cerrar"
    exit 1
}

$tokenPath = Join-Path $env:USERPROFILE "amy_canon.token"
try {
    if (Test-Path -LiteralPath $tokenPath) {
        Copy-Item -LiteralPath $tokenPath -Destination "$tokenPath.bak-$stamp" -Force
    }
    [System.IO.File]::WriteAllText($tokenPath, $frase, $utf8sinBOM)
    Write-Host "[+] Token local creado:      $tokenPath" -ForegroundColor Green
}
catch {
    Write-Host "[X] Error creando el token local: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Presiona Enter para cerrar"
    exit 1
}

$rutaCopia = ""
try {
    $copia = Join-Path $PSScriptRoot "amy_canon_frase_copia.txt"
    $txt = "Tu frase secreta de Amy Canon (guardada el " + (Get-Date -Format "yyyy-MM-dd HH:mm") + "):`r`n`r`n$frase`r`n`r`nSi algun dia la cambias a mano, debe quedar IDENTICA en:`r`n`r`n- el Config.json del server (clave amy_canon_token)`r`n`r`n- tu archivo amy_canon.token`r`n"
    [System.IO.File]::WriteAllText($copia, $txt, $utf8sinBOM)
    $rutaCopia = $copia
}
catch {
    $rutaCopia = "(la copia de respaldo no se pudo crear, no pasa nada)"
}

# ------------------------------------------------------------
# PASO 4: verificacion automatica
# ------------------------------------------------------------
Write-Host ""
Write-Host "--- PASO 4 de 4: verificacion automatica ---" -ForegroundColor Cyan
Write-Host ""
$todosOk = $true

$leido = [System.IO.File]::ReadAllText($tokenPath)
if ($leido -ceq $frase) {
    Write-Host "[OK] amy_canon.token  ->  identico" -ForegroundColor Green
}
else {
    Write-Host "[X]  amy_canon.token no coincide! (dice: '$leido')" -ForegroundColor Red
    $todosOk = $false
}

foreach ($c in $configsOk) {
    try {
        $json = Get-Content -LiteralPath $c -Raw | ConvertFrom-Json
        $valor = $json.amy_canon_token
        if ("$valor" -ceq $frase) {
            Write-Host "[OK] $c" -ForegroundColor Green
        }
        else {
            Write-Host "[X]  $c  (la clave dice: '$valor')" -ForegroundColor Red
            $todosOk = $false
        }
    }
    catch {
        Write-Host "[X]  $c no se pudo releer como JSON: $($_.Exception.Message)" -ForegroundColor Red
        $todosOk = $false
    }
}

Write-Host ""
if ($todosOk) {
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host "   TODO CONFIGURADO Y VERIFICADO" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Frase secreta:  $frase"
    Write-Host "  Server config:  $($configsOk -join ', ')"
    Write-Host "  Token local:    $tokenPath"
    if ($rutaCopia -ne "") { Write-Host "  Copia de frase: $rutaCopia" }
    if ($configs.Count -gt 1) {
        Write-Host "  (Se actualizo en TODOS los Config.json encontrados)"
    }
    Write-Host ""
    Write-Host "  ULTIMO PASO (manual, 10 segundos):" -ForegroundColor Yellow
    Write-Host "   1. CIERRA la ventana del server por completo" -ForegroundColor Yellow
    Write-Host "      (sin tocar sus menus ni botones)" -ForegroundColor Yellow
    Write-Host "   2. Vuelve a abrir el server" -ForegroundColor Yellow
    Write-Host "   3. Entra al juego. La consola del server debe decir:" -ForegroundColor Yellow
    Write-Host "        amy canon unlock: true" -ForegroundColor Yellow
}
else {
    $rc = 1
    Write-Host "=================================================" -ForegroundColor Red
    Write-Host "   ALGO FALLO EN LA VERIFICACION" -ForegroundColor Red
    Write-Host "=================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  No pasa nada: hay copias de seguridad *.bak-$stamp"
    Write-Host "  junto a cada archivo tocado. Para volver atras:"
    Write-Host "  borra el archivo nuevo y renombra la copia .bak-..."
    Write-Host "  quitandole el .bak-$stamp del final."
    Write-Host "  Y mandame una captura de este error :)"
}

$proceso = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "*DisasterServer*" }
if ($proceso) {
    Write-Host ""
    Write-Host "[!] ATENCION: hay un DisasterServer ABIERTO ahora mismo." -ForegroundColor Yellow
    Write-Host "    Cierralo y vuelve a abrirlo para que lea el cambio." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Presiona Enter para cerrar"
exit $rc
