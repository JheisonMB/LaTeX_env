#!/usr/bin/env bash
# create_latex_project.sh - Multiplataforma (macOS/Linux)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
TEMPLATE_DIR="$ROOT/templates"
PROJECTS_DIR="$ROOT/latex_projects"
CREATOR_DIR="$ROOT/.creator"
CONFIG_FILE="$CREATOR_DIR/config.yaml"

source "$CREATOR_DIR/config.sh"
source "$CREATOR_DIR/placeholders.sh"

# ── Funciones auxiliares ────────────────────────────────────────────────────
title() { echo -e "\n\033[36m$1\033[0m"; }
error() { echo -e "\033[31mERROR: $1\033[0m" >&2; exit 1; }
success() { echo -e "\033[32m$1\033[0m"; }
warning() { echo -e "\033[33m$1\033[0m"; }

# ── Configuración ────────────────────────────────────────────────────────────
title "=== CREADOR DE PROYECTOS LaTeX ==="

read_config "$CONFIG_FILE"

if [[ "${#CONFIG[@]}" -eq 0 ]]; then
    warning "No se encontró config.yaml. Ingresa la configuración inicial:"
    prompt_config
    write_config "$CONFIG_FILE"
else
    echo -e "\nConfiguración actual:"
    echo "  Autor(es)   : ${CONFIG[autores]}"
    echo "  Institución : ${CONFIG[institucion]}"
    echo "  Facultad    : ${CONFIG[facultad]}"
    while true; do
        read -rp $'\n¿Cambiar algún valor? [s/N] ' change
        change="${change:-n}"
        if [[ "$change" =~ ^[SsNn]$ ]]; then break; fi
        echo "  Por favor ingrese 's' (sí) o 'n' (no)."
    done
    if [[ "$change" =~ ^[Ss]$ ]]; then
        prompt_config
        write_config "$CONFIG_FILE"
    fi
fi

# ── Nombre y título ──────────────────────────────────────────────────────────
title "--- Proyecto ---"
while true; do
    read -rp "Nombre del proyecto (minúsculas, números, guion_bajo): " projectName
    if [[ "$projectName" =~ ^[a-z0-9_]+$ ]]; then break; fi
    echo "Nombre inválido. Solo letras minúsculas, números y guion_bajo."
done

read -rp "Título del documento: " docTitle
[[ -z "$docTitle" ]] && error "El título no puede estar vacío."

# ── Destino ──────────────────────────────────────────────────────────────────
title "--- Destino ---"

select_project_path() {
    local currentPath="$1"
    local dirs=()
    
    if [[ -d "$currentPath" ]]; then
        while IFS= read -r -d '' dir; do
            dirs+=("$(basename "$dir")")
        done < <(find "$currentPath" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    fi
    
    echo -e "\nRuta actual: ${currentPath/$PROJECTS_DIR/latex_projects}"
    echo "  1) [HERE] - Crear proyecto aquí"
    echo "  2) [NEW] - Crear nuevo directorio aquí"
    
    local offset=2
    if [[ ${#dirs[@]} -gt 0 ]]; then
        for i in "${!dirs[@]}"; do
            echo "  $((i+3))) ${dirs[$i]}/"
        done
        offset=$((${#dirs[@]} + 2))
    fi
    
    while true; do
        read -rp "Seleccione opción [1-$offset]: " sel
        if [[ "$sel" =~ ^[0-9]+$ ]] && [[ "$sel" -ge 1 ]] && [[ "$sel" -le "$offset" ]]; then
            break
        fi
        echo "  Opción inválida."
    done
    
    if [[ "$sel" -eq 1 ]]; then
        echo "$currentPath"
    elif [[ "$sel" -eq 2 ]]; then
        while true; do
            read -rp "Nombre del nuevo directorio: " newDir
            [[ -n "$newDir" ]] && break
            echo "  El nombre no puede estar vacío."
        done
        local newPath="$currentPath/$newDir"
        mkdir -p "$newPath"
        select_project_path "$newPath"
    else
        local selectedDir="${dirs[$((sel-3))]}"
        select_project_path "$currentPath/$selectedDir"
    fi
}

mkdir -p "$PROJECTS_DIR"
destinationPath=$(select_project_path "$PROJECTS_DIR")
projectPath="$destinationPath/$projectName"

[[ -d "$projectPath" ]] && error "El directorio ya existe: $projectPath"
mkdir -p "$projectPath"
success "  Creado: $projectPath"

# ── Plantilla ────────────────────────────────────────────────────────────────
title "--- Plantilla ---"
templates=()
while IFS= read -r -d '' tmpl; do
    name="$(basename "$tmpl")"
    [[ "$name" != "mermaid" ]] && templates+=("$name")
done < <(find "$TEMPLATE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

for i in "${!templates[@]}"; do
    echo "  $((i+1))) ${templates[$i]}"
done

while true; do
    read -rp "Seleccione plantilla [1-${#templates[@]}]: " tInput
    if [[ "$tInput" =~ ^[0-9]+$ ]] && [[ "$tInput" -ge 1 ]] && [[ "$tInput" -le "${#templates[@]}" ]]; then
        break
    fi
    echo "  Opción inválida."
done

selectedTemplate="${templates[$((tInput-1))]}"
cp -r "$TEMPLATE_DIR/$selectedTemplate/"* "$projectPath/"

# Limpiar archivos generados
find "$projectPath" -type f \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \
    -o -name "*.bbl" -o -name "*.blg" -o -name "*.fls" -o -name "*.fdb_latexmk" \
    -o -name "*.synctex.gz" -o -name "*.pdf" -o -name "*.lof" -o -name "*.lot" \) -delete

success "  Plantilla: $selectedTemplate"

# ── Mermaid ──────────────────────────────────────────────────────────────────
while true; do
    read -rp $'\n¿Incluir soporte Mermaid? [s/N] ' useMermaid
    useMermaid="${useMermaid:-n}"
    if [[ "$useMermaid" =~ ^[SsNn]$ ]]; then break; fi
    echo "  Por favor ingrese 's' (sí) o 'n' (no)."
done

if [[ "$useMermaid" =~ ^[Ss]$ ]]; then
    latexmkrc="$TEMPLATE_DIR/mermaid/.latexmkrc"
    [[ -f "$latexmkrc" ]] && cp "$latexmkrc" "$projectPath/"
    mkdir -p "$projectPath/assets"/{mermaid,diagrams,images}
    success "  Mermaid configurado. Compila con: latexmk -pdf main.tex"
else
    warning "  Sin soporte Mermaid."
fi

# ── Placeholders ─────────────────────────────────────────────────────────────
title "--- Configurando archivos .tex ---"
replace_placeholders "$projectPath" "$docTitle" "$(date +%Y-%m-%d)"
success "  Placeholders reemplazados."

# ── Resumen ──────────────────────────────────────────────────────────────────
title "=== PROYECTO CREADO ==="
echo "  Nombre    : $projectName"
echo "  Título    : $docTitle"
echo "  Plantilla : $selectedTemplate"
echo "  Ubicación : $projectPath"
