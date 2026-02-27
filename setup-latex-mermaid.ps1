#Requires -RunAsAdministrator
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorCount = 0

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "   OK: $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "   ERROR: $msg" -ForegroundColor Red; $script:ErrorCount++ }
function Write-Info($msg) { Write-Host "   $msg" -ForegroundColor Yellow }

# Refresca PATH en la sesion actual leyendo las variables de entorno del sistema y usuario
function Refresh-Path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path    = "$machinePath;$userPath"
}

# Instala un paquete con winget y refresca el PATH
function Install-WithWinget($packageId, $name) {
    Write-Info "Instalando $name con winget..."
    winget install --id $packageId --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "No se pudo instalar $name. Instala manualmente e intenta de nuevo."
        return $false
    }
    Refresh-Path
    return $true
}

# Verifica si un comando existe en PATH
function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# ─── 1. winget ───────────────────────────────────────────────────────────────
Write-Step "[1/6] Verificando winget..."
if (-not (Test-Command "winget")) {
    Write-Fail "winget no encontrado. Instala 'App Installer' desde Microsoft Store y vuelve a ejecutar."
    exit 1
}
Write-OK "winget disponible."

# ─── 2. MiKTeX ───────────────────────────────────────────────────────────────
Write-Step "[2/6] Verificando MiKTeX (pdflatex)..."
if (-not (Test-Command "pdflatex")) {
    if (-not (Install-WithWinget "MiKTeX.MiKTeX" "MiKTeX")) { exit 1 }
    if (-not (Test-Command "pdflatex")) {
        Write-Fail "pdflatex no encontrado tras instalar MiKTeX. Reinicia la terminal e intenta de nuevo."
        exit 1
    }
}
Write-OK "MiKTeX / pdflatex disponible."

Write-Info "Actualizando paquetes MiKTeX..."
miktex packages update 2>&1 | Where-Object { $_ -notmatch "security risk" } | Out-Null
Write-OK "Paquetes MiKTeX actualizados."

$latexPackages = @("standalone", "graphics", "import")
foreach ($pkg in $latexPackages) {
    Write-Info "Asegurando paquete LaTeX: $pkg"
    miktex packages install $pkg 2>&1 | Where-Object { $_ -notmatch "security risk|already installed" } | Out-Null
}

# ─── 3. Node.js ──────────────────────────────────────────────────────────────
Write-Step "[3/6] Verificando Node.js y npm..."
if (-not (Test-Command "node")) {
    if (-not (Install-WithWinget "OpenJS.NodeJS.LTS" "Node.js LTS")) { exit 1 }
    if (-not (Test-Command "node")) {
        Write-Fail "node no encontrado tras instalar. Reinicia la terminal e intenta de nuevo."
        exit 1
    }
}
Write-OK "Node.js $(node --version) disponible."

if (-not (Test-Command "npm")) {
    Write-Fail "npm no encontrado. Reinstala Node.js."
    exit 1
}
Write-OK "npm $(npm --version) disponible."

# ─── 4. Perl (latexmk) ───────────────────────────────────────────────────────
Write-Step "[4/6] Verificando Perl (requerido por latexmk)..."
if (-not (Test-Command "perl")) {
    if (-not (Install-WithWinget "StrawberryPerl.StrawberryPerl" "Strawberry Perl")) { exit 1 }
    if (-not (Test-Command "perl")) {
        Write-Fail "perl no encontrado tras instalar. Reinicia la terminal e intenta de nuevo."
        exit 1
    }
}
Write-OK "Perl $(perl --version | Select-String 'v\d+\.\d+\.\d+' | ForEach-Object { $_.Matches[0].Value }) disponible."

# ─── 5. Mermaid CLI ──────────────────────────────────────────────────────────
Write-Step "[5/6] Verificando Mermaid CLI (mmdc)..."
if (-not (Test-Command "mmdc")) {
    Write-Info "Instalando @mermaid-js/mermaid-cli globalmente..."
    npm install -g @mermaid-js/mermaid-cli
    Refresh-Path
    if (-not (Test-Command "mmdc")) {
        Write-Fail "mmdc no encontrado tras instalar. Verifica que el directorio global de npm este en PATH."
        $npmGlobal = npm root -g
        Write-Info "Directorio global npm: $npmGlobal"
        Write-Info "Agrega manualmente al PATH: $(Split-Path $npmGlobal)"
        exit 1
    }
}
Write-OK "Mermaid CLI disponible."

# ─── 6. Prueba funcional ─────────────────────────────────────────────────────
Write-Step "[6/6] Prueba funcional de Mermaid CLI..."
$testDir = Join-Path $PSScriptRoot "assets"
New-Item -ItemType Directory -Force -Path "$testDir\mermaid", "$testDir\diagrams" | Out-Null

$testMmd = "$testDir\mermaid\test.mmd"
$testPng = "$testDir\diagrams\test.png"
"graph LR; A-->B" | Set-Content $testMmd -Encoding UTF8

mmdc -i $testMmd -o $testPng 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0 -and (Test-Path $testPng)) {
    Write-OK "Mermaid genera imagenes correctamente."
    Remove-Item $testMmd, $testPng -Force
} else {
    Write-Fail "La prueba de Mermaid fallo. Revisa la instalacion de mmdc o Chromium."
}

# ─── Resumen ─────────────────────────────────────────────────────────────────
Write-Host ""
if ($ErrorCount -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Ambiente listo. Puedes compilar LaTeX  " -ForegroundColor Green
    Write-Host " con diagramas Mermaid sin problemas.   " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " Hay $ErrorCount problema(s) pendiente(s)." -ForegroundColor Red
    Write-Host " Revisa los mensajes ERROR arriba.      " -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}
