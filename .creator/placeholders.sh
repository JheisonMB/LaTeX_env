#!/usr/bin/env bash
# .creator/placeholders.sh - Reemplazo de placeholders en archivos .tex

replace_placeholders() {
    local projectPath="$1"
    local title="$2"
    local date="$3"
    
    local authorLatex="${CONFIG[autores]//,/ \\\\ }"
    local titleEsc="${title//_/\\_}"
    
    # Mapa de reemplazos
    declare -A map=(
        # Título
        ["Título del Proyecto"]="$titleEsc"
        ["Título del Documento"]="$titleEsc"
        ["Project Title"]="$titleEsc"
        ["Título del Ensayo"]="$titleEsc"
        ["Asunto de la carta"]="$titleEsc"
        # Autor
        ["Nombre del Autor"]="$authorLatex"
        ["Author Name"]="$authorLatex"
        ["Your Name"]="$authorLatex"
        ["Autor Principal"]="$authorLatex"
        ["Nombre Completo"]="$authorLatex"
        ["\[Nombre del Remitente\]"]="$authorLatex"
        # Institución
        ["Universidad La Salle"]="${CONFIG[institucion]}"
        ["University Placeholder"]="${CONFIG[institucion]}"
        ["Corporación Unificada Nacional de Educación Superior"]="${CONFIG[institucion]}"
        # Facultad
        ["Maestría en Inteligencia Artificial"]="${CONFIG[facultad]}"
        ["Faculty Placeholder"]="${CONFIG[facultad]}"
        ["Ingeniería Electrónica"]="${CONFIG[facultad]}"
        # Fecha
        ["YYYY-MM-DD"]="$date"
    )
    
    # Campos opcionales
    [[ -n "${CONFIG[departamento]}" ]] && map["Department, University"]="${CONFIG[departamento]}" && map["Cargo o Departamento"]="${CONFIG[departamento]}"
    [[ -n "${CONFIG[email]}" ]] && map["correo@institucional.edu.co"]="${CONFIG[email]}" && map["author@university.edu"]="${CONFIG[email]}" && map["email@correo.com"]="${CONFIG[email]}"
    [[ -n "${CONFIG[codigo_estudiantil]}" ]] && map["Código estudiantil"]="${CONFIG[codigo_estudiantil]}" && map["C.C. Número de cédula"]="${CONFIG[codigo_estudiantil]}"
    [[ -n "${CONFIG[director]}" ]] && map["Nombre del Director"]="${CONFIG[director]}"
    [[ -n "${CONFIG[telefono]}" ]] && map["3001234567"]="${CONFIG[telefono]}"
    [[ -n "${CONFIG[ciudad]}" ]] && map["Bogotá"]="${CONFIG[ciudad]}" && map["CIUDAD"]="${CONFIG[ciudad]}"
    [[ -n "${CONFIG[pais]}" ]] && map["Colombia"]="${CONFIG[pais]}"
    [[ -n "${CONFIG[direccion]}" ]] && map["Calle 123 #45-67"]="${CONFIG[direccion]}"
    [[ -n "${CONFIG[curso]}" ]] && map["Nombre del Curso"]="${CONFIG[curso]}"
    [[ -n "${CONFIG[codigo_curso]}" ]] && map["Código del Curso"]="${CONFIG[codigo_curso]}"
    [[ -n "${CONFIG[semestre]}" ]] && map["Semestre"]="${CONFIG[semestre]}"
    [[ -n "${CONFIG[ano_academico]}" ]] && map["Año Académico"]="${CONFIG[ano_academico]}"
    
    # Procesar archivos .tex
    find "$projectPath" -type f -name "*.tex" | while read -r texFile; do
        local content
        content=$(<"$texFile")
        
        # Reemplazos literales
        for key in "${!map[@]}"; do
            [[ -n "${map[$key]}" ]] && content="${content//$key/${map[$key]}}"
        done
        
        # Reemplazos en \newcommand
        content=$(echo "$content" | sed -E "s/(\\\\newcommand\{\\\\titulo\}\{)[^}]*(})/\1$titleEsc\2/g")
        content=$(echo "$content" | sed -E "s/(\\\\newcommand\{\\\\autor\}\{)[^}]*(})/\1$authorLatex\2/g")
        content=$(echo "$content" | sed -E "s/(\\\\newcommand\{\\\\universidad\}\{)[^}]*(})/\1${CONFIG[institucion]}\2/g")
        content=$(echo "$content" | sed -E "s/(\\\\newcommand\{\\\\programa\}\{)[^}]*(})/\1${CONFIG[facultad]}\2/g")
        
        [[ -n "${CONFIG[director]}" ]] && content=$(echo "$content" | sed -E "s/(\\\\newcommand\{\\\\director\}\{)[^}]*(})/\1${CONFIG[director]}\2/g")
        [[ -n "${CONFIG[email]}" ]] && content=$(echo "$content" | sed -E "s/(\\\\newcommand\{\\\\correo\}\{)[^}]*(})/\1${CONFIG[email]}\2/g")
        [[ -n "${CONFIG[codigo_estudiantil]}" ]] && content=$(echo "$content" | sed -E "s/(\\\\newcommand\{\\\\codigo\}\{)[^}]*(})/\1${CONFIG[codigo_estudiantil]}\2/g")
        
        echo "$content" > "$texFile"
    done
}
