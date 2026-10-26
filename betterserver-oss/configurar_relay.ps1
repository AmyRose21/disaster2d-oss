# ============================================================
#  configurar_relay.ps1
#  Configurador del RELAY de relaysc.dr2.site (port del
#  sistema de penguinehis / betterserver-v1.6)
#
#  Que hace:
#    1. Encuentra el Config.json de tu server compilado
#    2. Te pregunta host / puerto / usuario / contrasena
#    3. Escribe la seccion "relay" en el Config.json
#    4. Pone allow_duplicate_ip en true (OBLIGATORIO para el
#       relay: todos los jugadores relayeados llegan desde
#       127.0.0.1 y sin esto solo entraria uno)
#    5. Respalda el Config.json antes de tocarlo
#
#  NO registra cuentas: la cuenta ya la creaste vos en la web
#  de relaysc.dr2.site; esto solo guarda usuario/contrasena en
#  tu Config.json (igual que el betterserver v1.6 original).
#
#  Compatible con Windows PowerShell 5.1 (Windows 10/11 de fabrica).
# ============================================================

param(
    [string]$StartDir = ""
)

$ErrorActionPreference = "Stop"
$utf8sinBOM = New-Object System.Text.UTF8Encoding($false)

Write-Host ""
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host "     CONFIGURADOR DEL RELAY (relaysc.dr2.site)"     -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Publica tu server en el relay SIN abrir puertos."
Write-Host "La cuenta se guarda en Config.json (no se registra"
Write-Host "nada desde aca; usa la que ya creaste en la web)."
Write-Host ""

# ------------------------------------------------------------
# PASO 1: encontrar el Config.json
# ------------------------------------------------------------
Write-Host "--- PASO 1 de 3: buscar el Config.json del server ---" -ForegroundColor Cyan
Write-Host ""

if ($StartDir -eq "") { $StartDir = $PSScriptRoot }

$defaultCfg = Join-Path $StartDir "build\disasterserver\Release\Config.json"
$candidates = @()

if (Test-Path -LiteralPath $defaultCfg) {
    $candidates = @($defaultCfg)
}
else {
    $candidates = @(Get-ChildItem -LiteralPath $StartDir -Filter "Config.json" -File -Recurse -Depth 5 -ErrorAction SilentlyContinue |
                    Where-Object { $_.DirectoryName -notmatch 'config_backup' } |
                    ForEach-Object { $_.FullName })
}

if ($candidates.Count -eq 0) {
    Write-Host "[ERROR] No encontre ningun Config.json compilado." -ForegroundColor Red
    Write-Host ""
    Write-Host "Primero compila y ejecuta el server UNA vez (opciones 4"
    Write-Host "o 5 del compilar_server.bat) para que cree el Config.json,"
    Write-Host "y despues volve a correr este configurador."
    Write-Host ""
    exit 1
}

if ($candidates.Count -eq 1) {
    $configPath = $candidates[0]
}
else {
    Write-Host "Encontre varios Config.json:"
    for ($i = 0; $i -lt $candidates.Count; $i++) {
        Write-Host ("   {0}. {1}" -f ($i + 1), $candidates[$i])
    }
    $sel = 0
    while ($sel -lt 1 -or $sel -gt $candidates.Count) {
        $r = Read-Host "Cual usas? [1-$($candidates.Count)]"
        if ($r -match '^\d+$') { $sel = [int]$r }
    }
    $configPath = $candidates[$sel - 1]
}

Write-Host ""
Write-Host "[OK] Config.json: $configPath" -ForegroundColor Green

# ------------------------------------------------------------
# PASO 2: leer valores actuales y preguntar los nuevos
# ------------------------------------------------------------
Write-Host ""
Write-Host "--- PASO 2 de 3: datos de tu cuenta del relay ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "(Enter sin escribir nada = dejar el valor actual)" -ForegroundColor DarkGray
Write-Host ""

$j = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json

$curEnabled = $false
$curHost    = "relaysc.dr2.site"
$curPort    = 9001
$curUser    = ""
$curPass    = ""

if ($j.relay) {
    if ($j.relay.enabled)        { $curEnabled = [bool]$j.relay.enabled }
    if ($j.relay.directory_host) { $curHost    = "$($j.relay.directory_host)" }
    if ($j.relay.directory_port) { $curPort    = [int]$j.relay.directory_port }
    if ($j.relay.username)       { $curUser    = "$($j.relay.username)" }
    if ($j.relay.password)       { $curPass    = "$($j.relay.password)" }
}

# --- activar? ---
$resp = Read-Host "Activar el relay? S/N [actual: $(if ($curEnabled) {'ACTIVADO'} else {'desactivado'})]"
if ($resp -eq "") { $newEnabled = $curEnabled }
elseif ($resp -match '^[sS]') { $newEnabled = $true }
else { $newEnabled = $false }

if (-not $newEnabled) {
    Write-Host ""
    Write-Host "[i] Relay desactivado. No toco nada mas." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# --- host ---
$resp = Read-Host "Host del directorio [actual: $curHost]"
$newHost = if ($resp -eq "") { $curHost } else { $resp.Trim() }
if ($newHost -eq "") { $newHost = "relaysc.dr2.site" }

# --- puerto ---
$resp = Read-Host "Puerto del directorio [actual: $curPort]"
if ($resp -eq "") { $newPort = $curPort }
elseif ($resp -match '^\d+$' -and [int]$resp -ge 1 -and [int]$resp -le 65535) { $newPort = [int]$resp }
else {
    Write-Host "[i] '$resp' no es un puerto valido, dejo $curPort." -ForegroundColor Yellow
    $newPort = $curPort
}

# --- usuario ---
$mostrarUser = if ($curUser -ne "") { $curUser } else { "(vacio)" }
$resp = Read-Host "Usuario de tu cuenta [actual: $mostrarUser]"
$newUser = if ($resp -eq "") { $curUser } else { $resp.Trim() }
if ($newUser.Length -gt 31) {
    Write-Host "[i] El usuario se trunca a 31 caracteres (limite del original)." -ForegroundColor Yellow
    $newUser = $newUser.Substring(0, 31)
}

# --- contrasena (no mostrar la actual, Enter la conserva) ---
$pista = if ($curPass -ne "") { "ya hay una guardada (Enter la conserva)" } else { "no hay ninguna guardada" }
$resp = Read-Host "Contrasena de tu cuenta ($pista)"
$newPass = if ($resp -eq "") { $curPass } else { $resp }
if ($newPass.Length -gt 31) {
    Write-Host "[i] La contrasena se trunca a 31 caracteres (limite del original)." -ForegroundColor Yellow
    $newPass = $newPass.Substring(0, 31)
}

if ($newPass -eq "") {
    Write-Host ""
    Write-Host "[!] OJO: no hay contrasena guardada. El server arrancara" -ForegroundColor Yellow
    Write-Host "    con el relay apagado y un aviso en el log hasta que" -ForegroundColor Yellow
    Write-Host "    pongas la contrasena de tu cuenta." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# PASO 3: respaldar y escribir
# ------------------------------------------------------------
Write-Host ""
Write-Host "--- PASO 3 de 3: guardar en el Config.json ---" -ForegroundColor Cyan
Write-Host ""

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bakDir = Join-Path (Split-Path -Parent $configPath) "config_backup"
if (-not (Test-Path -LiteralPath $bakDir)) { New-Item -ItemType Directory -Path $bakDir | Out-Null }
Copy-Item -LiteralPath $configPath -Destination (Join-Path $bakDir "Config.json.bak-$stamp")
Write-Host "[i] Respaldo: config_backup\Config.json.bak-$stamp"

if (-not $j.relay) {
    $j | Add-Member -NotePropertyName relay -NotePropertyValue ([pscustomobject]@{
        enabled         = $false
        directory_host  = ""
        directory_port  = 0
        username        = ""
        password        = ""
    })
}

$j.relay.enabled        = $true
$j.relay.directory_host = $newHost
$j.relay.directory_port = $newPort
$j.relay.username       = $newUser
$j.relay.password       = $newPass

# OBLIGATORIO con relay: sin esto solo entra 1 jugador por IP
# (todos los relayeados llegan desde 127.0.0.1)
$j.allow_duplicate_ip = $true

$json = $j | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($configPath, $json, $utf8sinBOM)

# verificar
$chk = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
if (-not ($chk.relay -and $chk.relay.enabled -and $chk.relay.directory_host -eq $newHost)) {
    Write-Host "[ERROR] La verificacion fallo, revisa el archivo a mano." -ForegroundColor Red
    Write-Host "        (hay respaldo en config_backup)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Relay configurado:" -ForegroundColor Green
Write-Host "     activado   : si"
Write-Host "     directorio : $newHost`:$newPort"
Write-Host "     cuenta     : $(if ($newUser) { $newUser } else { '(anonimo)' })"
Write-Host "     contrasena : $(if ($newPass) { 'guardada' } else { '(VACIA - ponla despues)' })"
Write-Host "     allow_duplicate_ip: true (necesario para el relay)"
Write-Host ""
Write-Host "Al arrancar el server vas a ver en el log:"
Write-Host "   'Relay: connecting to directory at $newHost`:$newPort...'"
Write-Host "y si la cuenta esta bien:"
Write-Host "   'Relay: online - players can join at ... ports X-Y'" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora REINICIA el server (opciones 4/5) para que aplique."
Write-Host ""
