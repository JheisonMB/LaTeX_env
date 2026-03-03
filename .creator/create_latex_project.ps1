# create_latex_project.ps1 - v1 (Windows)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ROOT         = Split-Path $PSScriptRoot -Parent
$TEMPLATE_DIR = Join-Path $ROOT "templates"
$PROJECTS_DIR = Join-Path $ROOT "latex_projects"
$CONFIG_FILE  = Join-Path $PSScriptRoot "config.yaml"

. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\placeholders.ps1"

function Write-Title($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function Require($val, $msg) { if (-not $val) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 } }

# ── Configuración ────────────────────────────────────────────────────────────
Write-Title "=== CREADOR DE PROYECTOS LaTeX ==="

$cfg = Read-Config $CONFIG_FILE

if ($cfg.Count -eq 0) {
    Write-Host "No se encontro config.yaml. Ingresa la configuracion inicial:" -ForegroundColor Yellow
    $cfg = @{ autores=''; institucion=''; facultad=''; departamento=''; email=''; telefono='';
              codigo_estudiantil=''; director=''; ciudad='Bogota'; pais='Colombia';
              direccion=''; curso=''; codigo_curso=''; semestre=''; ano_academico='' }
    $cfg = Prompt-Config $cfg
    Write-Config $CONFIG_FILE $cfg
} else {
    Write-Host "`nConfiguracion actual:"
    Write-Host "  Autor(es)   : $($cfg['autores'])"
    Write-Host "  Institucion : $($cfg['institucion'])"
    Write-Host "  Facultad    : $($cfg['facultad'])"
    do {
        $change = Read-Host "`n¿Cambiar algun valor? [s/N]"
        if ($change -eq '') { $change = 'n' }
        $validChange = $change -match '^[SsNn]$'
        if (-not $validChange) {
            Write-Host "  Por favor ingrese 's' (sí) o 'n' (no)." -ForegroundColor Red
        }
    } while (-not $validChange)
    if ($change -match '^[Ss]$') {
        $cfg = Prompt-Config $cfg
        Write-Config $CONFIG_FILE $cfg
    }
}

# ── Nombre y título ──────────────────────────────────────────────────────────
Write-Title "--- Proyecto ---"
do {
    $projectName = Read-Host "Nombre del proyecto (minusculas, numeros, guion_bajo)"
    if ($projectName -notmatch '^[a-z0-9_]+$') {
        Write-Host "Nombre invalido. Solo letras minusculas, numeros y guion_bajo." -ForegroundColor Red
        $valid = $false
    } else {
        $valid = $true
    }
} while (-not $valid)

$docTitle = Read-Host "Titulo del documento"
Require $docTitle "El titulo no puede estar vacio."

# ── Destino ──────────────────────────────────────────────────────────────────
Write-Title "--- Destino ---"
$existing = @(Get-ChildItem $PROJECTS_DIR -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
if ($existing.Count -gt 0) {
    for ($i = 0; $i -lt $existing.Count; $i++) { Write-Host "  $($i+1)) $($existing[$i])" }
    Write-Host "  $($existing.Count+1)) Otro"
    do {
        $sel = Read-Host "Seleccione destino [1-$($existing.Count+1)]"
        try {
            $selInt = [int]$sel
            $valid = $true
        } catch {
            Write-Host "  Por favor ingrese un número." -ForegroundColor Red
            $valid = $false
        }
    } while (-not $valid -or $selInt -lt 1 -or $selInt -gt ($existing.Count + 1))
    if ($selInt -le $existing.Count) {
        $projectPath = Join-Path $PROJECTS_DIR "$($existing[$selInt-1])\$projectName"
    } else {
        do {
            $custom = Read-Host "Ruta en latex_projects/"
            if (-not $custom) { Write-Host "  La ruta no puede estar vacía." -ForegroundColor Red }
        } while (-not $custom)
        $projectPath = Join-Path $PROJECTS_DIR "$custom\$projectName"
    }
} else {
    $projectPath = Join-Path $PROJECTS_DIR $projectName
}

Require (-not (Test-Path $projectPath)) "El directorio ya existe: $projectPath"
New-Item -ItemType Directory -Force -Path $projectPath | Out-Null
Write-Host "  Creado: $projectPath" -ForegroundColor Green

# ── Plantilla ────────────────────────────────────────────────────────────────
Write-Title "--- Plantilla ---"
$templates = @(Get-ChildItem $TEMPLATE_DIR -Directory | Where-Object { $_.Name -ne 'mermaid' } | Select-Object -ExpandProperty Name)
for ($i = 0; $i -lt $templates.Count; $i++) { Write-Host "  $($i+1)) $($templates[$i])" }
do {
    $tInput = Read-Host "Seleccione plantilla [1-$($templates.Count)]"
    try {
        $tSel = [int]$tInput - 1
        $valid = $true
    } catch {
        Write-Host "  Por favor ingrese un número." -ForegroundColor Red
        $valid = $false
    }
} while (-not $valid -or $tSel -lt 0 -or $tSel -ge $templates.Count)
$selectedTemplate = $templates[$tSel]
Copy-Item "$TEMPLATE_DIR\$selectedTemplate\*" $projectPath -Recurse -Force

# Limpiar archivos generados que pudieran haberse copiado
'*.aux','*.log','*.out','*.toc','*.bbl','*.blg','*.fls','*.fdb_latexmk','*.synctex.gz','*.pdf','*.lof','*.lot' |
    ForEach-Object { Get-ChildItem $projectPath -Recurse -Filter $_ | Remove-Item -Force }

Write-Host "  Plantilla: $selectedTemplate" -ForegroundColor Green

# ── Mermaid ──────────────────────────────────────────────────────────────────
do {
    $useMermaid = Read-Host "`n¿Incluir soporte Mermaid? [s/N]"
    if ($useMermaid -eq '') { $useMermaid = 'n' }
    $validMermaid = $useMermaid -match '^[SsNn]$'
    if (-not $validMermaid) {
        Write-Host "  Por favor ingrese 's' (sí) o 'n' (no)." -ForegroundColor Red
    }
} while (-not $validMermaid)

if ($useMermaid -match '^[Ss]$') {
    $latexmkrc = "$TEMPLATE_DIR\mermaid\.latexmkrc"
    if (Test-Path $latexmkrc) { Copy-Item $latexmkrc $projectPath }
    New-Item -ItemType Directory -Force -Path "$projectPath\assets\mermaid","$projectPath\assets\diagrams","$projectPath\assets\images" | Out-Null
    Write-Host "  Mermaid configurado. Compila con: latexmk -pdf main.tex" -ForegroundColor Green
} else {
    Write-Host "  Sin soporte Mermaid." -ForegroundColor Yellow
}

# ── Placeholders ─────────────────────────────────────────────────────────────
Write-Title "--- Configurando archivos .tex ---"
Replace-Placeholders $projectPath $cfg $docTitle (Get-Date -Format "yyyy-MM-dd")
Write-Host "  Placeholders reemplazados." -ForegroundColor Green

# ── Resumen ──────────────────────────────────────────────────────────────────
Write-Title "=== PROYECTO CREADO ==="
Write-Host "  Nombre    : $projectName"
Write-Host "  Titulo    : $docTitle"
Write-Host "  Plantilla : $selectedTemplate"
Write-Host "  Ubicacion : $projectPath"
