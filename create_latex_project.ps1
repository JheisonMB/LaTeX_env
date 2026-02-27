# create_latex_project.ps1 - v1 (Windows)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ROOT         = $PSScriptRoot
$TEMPLATE_DIR = Join-Path $ROOT "templates"
$PROJECTS_DIR = Join-Path $ROOT "latex_projects"
$CONFIG_FILE  = Join-Path $ROOT "config.yaml"

. "$ROOT\.helpers\config.ps1"
. "$ROOT\.helpers\placeholders.ps1"

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
    $change = Read-Host "`n¿Cambiar algun valor? [s/N]"
    if ($change -match '^[Ss]$') {
        $cfg = Prompt-Config $cfg
        Write-Config $CONFIG_FILE $cfg
    }
}

# ── Nombre y título ──────────────────────────────────────────────────────────
Write-Title "--- Proyecto ---"
do {
    $projectName = Read-Host "Nombre del proyecto (minusculas, numeros, guion_bajo)"
} while ($projectName -notmatch '^[a-z0-9_]+$' -and (Write-Host "Nombre invalido." -ForegroundColor Red))

$docTitle = Read-Host "Titulo del documento"
Require $docTitle "El titulo no puede estar vacio."

# ── Destino ──────────────────────────────────────────────────────────────────
Write-Title "--- Destino ---"
$existing = @(Get-ChildItem $PROJECTS_DIR -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
if ($existing.Count -gt 0) {
    for ($i = 0; $i -lt $existing.Count; $i++) { Write-Host "  $($i+1)) $($existing[$i])" }
    Write-Host "  $($existing.Count+1)) Otro"
    $sel = Read-Host "Seleccione destino [1-$($existing.Count+1)]"
    if ([int]$sel -le $existing.Count) {
        $projectPath = Join-Path $PROJECTS_DIR "$($existing[[int]$sel-1])\$projectName"
    } else {
        $custom = Read-Host "Ruta en latex_projects/"
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
$tSel = [int](Read-Host "Seleccione plantilla [1-$($templates.Count)]") - 1
Require ($tSel -ge 0 -and $tSel -lt $templates.Count) "Seleccion invalida."
$selectedTemplate = $templates[$tSel]
Copy-Item "$TEMPLATE_DIR\$selectedTemplate\*" $projectPath -Recurse -Force

# Limpiar archivos generados que pudieran haberse copiado
'*.aux','*.log','*.out','*.toc','*.bbl','*.blg','*.fls','*.fdb_latexmk','*.synctex.gz','*.pdf','*.lof','*.lot' |
    ForEach-Object { Get-ChildItem $projectPath -Recurse -Filter $_ | Remove-Item -Force }

Write-Host "  Plantilla: $selectedTemplate" -ForegroundColor Green

# ── Mermaid ──────────────────────────────────────────────────────────────────
$useMermaid = Read-Host "`n¿Incluir soporte Mermaid? [s/N]"
if ($useMermaid -match '^[Ss]$') {
    $latexmkrc = "$TEMPLATE_DIR\mermaid\.latexmkrc"
    if (Test-Path $latexmkrc) { Copy-Item $latexmkrc $projectPath }
    New-Item -ItemType Directory -Force -Path "$projectPath\assets\mermaid","$projectPath\assets\diagrams","$projectPath\assets\images" | Out-Null
    Write-Host "  Mermaid configurado. Compila con: latexmk -pdf main.tex" -ForegroundColor Green
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
