#!/usr/bin/env bash
# .creator/config.sh - Lectura y escritura de config.yaml

declare -A CONFIG

read_config() {
    local configFile="$1"
    CONFIG=()
    
    [[ ! -f "$configFile" ]] && return
    
    local key="" value="" in_authors=0
    while IFS= read -r line; do
        # Detectar bloque de autores
        if [[ "$line" =~ ^autores: ]]; then
            in_authors=1
            value=""
            continue
        fi
        
        # Leer items de autores
        if [[ $in_authors -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"(.+)\" ]]; then
                [[ -n "$value" ]] && value+=", "
                value+="${BASH_REMATCH[1]}"
                continue
            else
                in_authors=0
                [[ -n "$value" ]] && CONFIG[autores]="$value"
            fi
        fi
        
        # Leer otros campos
        if [[ "$line" =~ ^([a-z_]+):[[:space:]]*\"(.*)\" ]]; then
            CONFIG[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
        fi
    done < "$configFile"
    
    # Valores por defecto
    [[ -z "${CONFIG[ciudad]}" ]] && CONFIG[ciudad]="Bogotá"
    [[ -z "${CONFIG[pais]}" ]] && CONFIG[pais]="Colombia"
}

write_config() {
    local configFile="$1"
    local authorsList=""
    
    IFS=',' read -ra authors <<< "${CONFIG[autores]}"
    for author in "${authors[@]}"; do
        author="$(echo "$author" | xargs)"
        authorsList+="  - \"$author\"\n"
    done
    
    cat > "$configFile" <<EOF
autores:
$(echo -e "$authorsList")
institucion: "${CONFIG[institucion]}"
facultad: "${CONFIG[facultad]}"
departamento: "${CONFIG[departamento]}"
email: "${CONFIG[email]}"
telefono: "${CONFIG[telefono]}"
codigo_estudiantil: "${CONFIG[codigo_estudiantil]}"
director: "${CONFIG[director]}"
ciudad: "${CONFIG[ciudad]}"
pais: "${CONFIG[pais]}"
direccion: "${CONFIG[direccion]}"
curso: "${CONFIG[curso]}"
codigo_curso: "${CONFIG[codigo_curso]}"
semestre: "${CONFIG[semestre]}"
ano_academico: "${CONFIG[ano_academico]}"
EOF
    echo -e "\033[32m   Configuración guardada.\033[0m"
}

prompt_config() {
    ask() {
        local label="$1" key="$2"
        local current="${CONFIG[$key]}"
        read -rp "  $label [$current]: " input
        [[ -n "$input" ]] && CONFIG[$key]="$input"
    }
    
    ask "Autor(es) separados por coma" "autores"
    ask "Institución" "institucion"
    ask "Facultad" "facultad"
    ask "Departamento" "departamento"
    ask "Email" "email"
    ask "Teléfono" "telefono"
    ask "Código estudiantil" "codigo_estudiantil"
    ask "Director" "director"
    ask "Ciudad" "ciudad"
    ask "País" "pais"
    ask "Dirección" "direccion"
    ask "Curso" "curso"
    ask "Código curso" "codigo_curso"
    ask "Semestre" "semestre"
    ask "Año académico" "ano_academico"
}
