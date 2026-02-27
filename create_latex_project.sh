#!/usr/bin/env bash

# ================================================
# SCRIPT MEJORADO - v8
# Con configuración YAML, path selection mejorado e integración Mermaid
# ================================================

# --- Configuración ---
TEMPLATE_DIR="/mnt/c/Users/PC/Documents/LaTeX_env/templates"
PROJECTS_DIR="/mnt/c/Users/PC/Documents/LaTeX_env/latex_projects"
CONFIG_FILE="/mnt/c/Users/PC/Documents/LaTeX_env/config.yaml"

# --- Funciones ---
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Función para leer valores YAML (soporta listas simples y valores simples)
read_yaml_value() {
    local key="$1"
    local file="$2"
    
    if [ "$key" = "autores" ]; then
        # Manejo especial para lista de autores
        if grep -q "autores:" "$file"; then
            # Verificar si es lista YAML
            if grep -q "^\s*-\s" "$file" <(sed -n '/autores:/,/^[^[:space:]]/p' "$file"); then
                # Es lista YAML - extraer y convertir a cadena separada por comas
                sed -n '/autores:/,/^[^[:space:]]/p' "$file" | \
                grep -E "^\s*-\s*\"" | \
                sed 's/^\s*-\s*"//; s/"$//' | \
                tr '\n' ',' | sed 's/,$//; s/,/, /g'
            else
                # Es valor simple - extraer directamente
                grep "^autores:" "$file" | cut -d':' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//'
            fi
        else
            echo ""
        fi
    else
        # Para valores simples - eliminar comillas si existen
        grep "^$key:" "$file" | cut -d':' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//'
    fi
}

# Función para convertir cadena de autores a formato LaTeX
format_authors_for_latex() {
    local authors_str="$1"
    # Si hay comas, asumimos múltiples autores separados por comas
    if echo "$authors_str" | grep -q ","; then
        # Reemplazar ", " por " \\ " para separación LaTeX
        echo "$authors_str" | sed 's/, / \\\\ /g'
    else
        echo "$authors_str"
    fi
}

# Función para validar nombre del proyecto (solo minúsculas, números y guión bajo)
validate_project_name() {
    local name="$1"
    if ! echo "$name" | grep -qE '^[a-z0-9_]+$'; then
        echo "✗ Nombre inválido. Solo se permiten letras minúsculas, números y guión bajo (_)."
        return 1
    fi
    return 0
}

# Función para escapar título para LaTeX (escapar guión bajo)
escape_latex_title() {
    local title="$1"
    # Escapar guión bajo
    echo "$title" | sed 's/_/\\_/g'
}

# Función para actualizar config.yaml
update_config_yaml() {
    # Convertir cadena de autores a lista YAML
    local authors_yaml=""
    if [ -n "$AUTHORS_STR" ]; then
        # Separar por comas y crear lista YAML
        IFS=',' read -ra authors_array <<< "$AUTHORS_STR"
        authors_yaml="autores:"
        for author in "${authors_array[@]}"; do
            # Limpiar espacios y agregar a lista
            clean_author=$(echo "$author" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
            authors_yaml="$authors_yaml\n  - \"$clean_author\""
        done
    else
        authors_yaml="autores:\n  - \"\""
    fi
    
    cat > "$CONFIG_FILE" << EOF
# Configuración predeterminada para proyectos LaTeX
$(echo -e "$authors_yaml")

institucion: "$INSTITUTION"
facultad: "$FACULTY"
departamento: "$DEPARTMENT"
email: "$EMAIL"
telefono: "$PHONE"
codigo_estudiantil: "$STUDENT_ID"
director: "$DIRECTOR"
fecha: "auto"

# Campos adicionales para cartas formales
ciudad: "$CITY"
pais: "$COUNTRY"
direccion: "$ADDRESS"

# Campos adicionales para documentos académicos
curso: "$COURSE"
codigo_curso: "$COURSE_CODE"
semestre: "$SEMESTER"
ano_academico: "$ACADEMIC_YEAR"
EOF
    echo "✓ Configuración actualizada en $CONFIG_FILE"
}

# ================================================
# INICIO DEL SCRIPT
# ================================================

echo "================================================"
echo "  CREADOR DE PROYECTOS LaTeX - v8"
echo "================================================"
echo ""

# --- Cargar configuración desde YAML ---
echo "📋 Cargando configuración..."
if [ -f "$CONFIG_FILE" ]; then
    # Cargar valores desde YAML
    DEFAULT_AUTHORS_STR=$(read_yaml_value "autores" "$CONFIG_FILE")
    DEFAULT_INSTITUTION=$(read_yaml_value "institucion" "$CONFIG_FILE")
    DEFAULT_FACULTY=$(read_yaml_value "facultad" "$CONFIG_FILE")
    DEFAULT_DEPARTMENT=$(read_yaml_value "departamento" "$CONFIG_FILE")
    DEFAULT_EMAIL=$(read_yaml_value "email" "$CONFIG_FILE")
    DEFAULT_PHONE=$(read_yaml_value "telefono" "$CONFIG_FILE")
    DEFAULT_STUDENT_ID=$(read_yaml_value "codigo_estudiantil" "$CONFIG_FILE")
    DEFAULT_DIRECTOR=$(read_yaml_value "director" "$CONFIG_FILE")
    
    # Campos adicionales
    DEFAULT_CITY=$(read_yaml_value "ciudad" "$CONFIG_FILE")
    DEFAULT_COUNTRY=$(read_yaml_value "pais" "$CONFIG_FILE")
    DEFAULT_ADDRESS=$(read_yaml_value "direccion" "$CONFIG_FILE")
    DEFAULT_COURSE=$(read_yaml_value "curso" "$CONFIG_FILE")
    DEFAULT_COURSE_CODE=$(read_yaml_value "codigo_curso" "$CONFIG_FILE")
    DEFAULT_SEMESTER=$(read_yaml_value "semestre" "$CONFIG_FILE")
    DEFAULT_ACADEMIC_YEAR=$(read_yaml_value "ano_academico" "$CONFIG_FILE")
    
    # Fecha siempre automática
    DEFAULT_DATE=$(date +"%Y-%m-%d")
    
    echo "✓ Configuración cargada desde $CONFIG_FILE"
    
    # Mostrar configuración actual
    echo ""
    echo "📋 Configuración actual:"
    echo "   • Autor(es): $DEFAULT_AUTHORS_STR"
    echo "   • Institución: $DEFAULT_INSTITUTION"
    echo "   • Facultad: $DEFAULT_FACULTY"
    [ -n "$DEFAULT_DEPARTMENT" ] && echo "   • Departamento: $DEFAULT_DEPARTMENT"
    [ -n "$DEFAULT_EMAIL" ] && echo "   • Email: $DEFAULT_EMAIL"
    [ -n "$DEFAULT_PHONE" ] && echo "   • Teléfono: $DEFAULT_PHONE"
    [ -n "$DEFAULT_STUDENT_ID" ] && echo "   • Código estudiantil: $DEFAULT_STUDENT_ID"
    [ -n "$DEFAULT_DIRECTOR" ] && echo "   • Director: $DEFAULT_DIRECTOR"
    [ -n "$DEFAULT_CITY" ] && echo "   • Ciudad: $DEFAULT_CITY"
    [ -n "$DEFAULT_COUNTRY" ] && echo "   • País: $DEFAULT_COUNTRY"
    echo "   • Fecha: $DEFAULT_DATE"
    echo ""
    
    # Preguntar si desea cambiar valores
    read -p "¿Desea cambiar algún valor? [s/N]: " change_config
    if [[ "$change_config" =~ ^[Ss]$ ]]; then
        echo ""
        echo "📝 Editar configuración (dejar vacío para mantener valor actual):"
        
        read -p "Autor(es) [$DEFAULT_AUTHORS_STR]: " authors_input
        AUTHORS_STR=${authors_input:-$DEFAULT_AUTHORS_STR}
        
        read -p "Institución [$DEFAULT_INSTITUTION]: " institution_input
        INSTITUTION=${institution_input:-$DEFAULT_INSTITUTION}
        
        read -p "Facultad [$DEFAULT_FACULTY]: " faculty_input
        FACULTY=${faculty_input:-$DEFAULT_FACULTY}
        
        read -p "Departamento [$DEFAULT_DEPARTMENT]: " department_input
        DEPARTMENT=${department_input:-$DEFAULT_DEPARTMENT}
        
        read -p "Email [$DEFAULT_EMAIL]: " email_input
        EMAIL=${email_input:-$DEFAULT_EMAIL}
        
        read -p "Teléfono [$DEFAULT_PHONE]: " phone_input
        PHONE=${phone_input:-$DEFAULT_PHONE}
        
        read -p "Código estudiantil [$DEFAULT_STUDENT_ID]: " student_id_input
        STUDENT_ID=${student_id_input:-$DEFAULT_STUDENT_ID}
        
        read -p "Director [$DEFAULT_DIRECTOR]: " director_input
        DIRECTOR=${director_input:-$DEFAULT_DIRECTOR}
        
        read -p "Ciudad [$DEFAULT_CITY]: " city_input
        CITY=${city_input:-$DEFAULT_CITY}
        
        read -p "País [$DEFAULT_COUNTRY]: " country_input
        COUNTRY=${country_input:-$DEFAULT_COUNTRY}
        
        read -p "Dirección [$DEFAULT_ADDRESS]: " address_input
        ADDRESS=${address_input:-$DEFAULT_ADDRESS}
        
        read -p "Curso [$DEFAULT_COURSE]: " course_input
        COURSE=${course_input:-$DEFAULT_COURSE}
        
        read -p "Código curso [$DEFAULT_COURSE_CODE]: " course_code_input
        COURSE_CODE=${course_code_input:-$DEFAULT_COURSE_CODE}
        
        read -p "Semestre [$DEFAULT_SEMESTER]: " semester_input
        SEMESTER=${semester_input:-$DEFAULT_SEMESTER}
        
        read -p "Año académico [$DEFAULT_ACADEMIC_YEAR]: " academic_year_input
        ACADEMIC_YEAR=${academic_year_input:-$DEFAULT_ACADEMIC_YEAR}
        
        # Fecha siempre automática
        DATE=$(date +"%Y-%m-%d")
        
        # Actualizar config.yaml automáticamente
        update_config_yaml
    else
        # Usar valores predeterminados
        AUTHORS_STR="$DEFAULT_AUTHORS_STR"
        INSTITUTION="$DEFAULT_INSTITUTION"
        FACULTY="$DEFAULT_FACULTY"
        DEPARTMENT="$DEFAULT_DEPARTMENT"
        EMAIL="$DEFAULT_EMAIL"
        PHONE="$DEFAULT_PHONE"
        STUDENT_ID="$DEFAULT_STUDENT_ID"
        DIRECTOR="$DEFAULT_DIRECTOR"
        DATE="$DEFAULT_DATE"
        CITY="$DEFAULT_CITY"
        COUNTRY="$DEFAULT_COUNTRY"
        ADDRESS="$DEFAULT_ADDRESS"
        COURSE="$DEFAULT_COURSE"
        COURSE_CODE="$DEFAULT_COURSE_CODE"
        SEMESTER="$DEFAULT_SEMESTER"
        ACADEMIC_YEAR="$DEFAULT_ACADEMIC_YEAR"
    fi
else
    # Si no existe config.yaml, solicitar todos los valores
    echo "⚠ No se encontró config.yaml. Por favor ingrese la configuración inicial:"
    echo ""
    
    read -p "Autor(es) (separados por comas): " AUTHORS_STR
    [ -z "$AUTHORS_STR" ] && error_exit "El autor no puede estar vacío."
    
    read -p "Institución: " INSTITUTION
    [ -z "$INSTITUTION" ] && error_exit "La institución no puede estar vacía."
    
    read -p "Facultad: " FACULTY
    [ -z "$FACULTY" ] && error_exit "La facultad no puede estar vacía."
    
    read -p "Departamento (opcional): " DEPARTMENT
    
    read -p "Email (opcional): " EMAIL
    
    read -p "Teléfono (opcional): " PHONE
    
    read -p "Código estudiantil (opcional): " STUDENT_ID
    
    read -p "Director (opcional): " DIRECTOR
    
    read -p "Ciudad (opcional) [Bogotá]: " CITY
    CITY=${CITY:-"Bogotá"}
    
    read -p "País (opcional) [Colombia]: " COUNTRY
    COUNTRY=${COUNTRY:-"Colombia"}
    
    read -p "Dirección (opcional): " ADDRESS
    
    read -p "Curso (opcional): " COURSE
    
    read -p "Código curso (opcional): " COURSE_CODE
    
    read -p "Semestre (opcional): " SEMESTER
    
    read -p "Año académico (opcional): " ACADEMIC_YEAR
    
    # Fecha siempre automática
    DATE=$(date +"%Y-%m-%d")
    
    # Crear config.yaml con los valores proporcionados
    update_config_yaml
fi



# Formatear autores para LaTeX
AUTHOR_LATEX=$(format_authors_for_latex "$AUTHORS_STR")

echo ""
echo "================================================"
echo ""

# --- Nombre del proyecto (carpeta) ---
while true; do
    read -p "Nombre del proyecto (solo minúsculas, números y guión bajo _): " project_name
    [ -z "$project_name" ] && echo "✗ El nombre no puede estar vacío." && continue
    if validate_project_name "$project_name"; then
        break
    fi
done

# --- Título del documento ---
read -p "Título del documento (texto libre, puede usar mayúsculas, espacios, etc.): " DOCUMENT_TITLE
[ -z "$DOCUMENT_TITLE" ] && error_exit "El título del documento no puede estar vacío."

# Escapar título para LaTeX (escapar guión bajo)
DOCUMENT_TITLE_ESCAPED=$(escape_latex_title "$DOCUMENT_TITLE")

# --- Ruta de destino (mostrar opciones) ---
echo ""
echo "📁 Directorios existentes en 'latex_projects/':"
existing_dirs=()
if [ -d "$PROJECTS_DIR" ]; then
    existing_dirs=($(find "$PROJECTS_DIR" -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | grep -v '^\.$' | grep -v '^latex_projects$' | sort))
fi

if [ ${#existing_dirs[@]} -gt 0 ]; then
    for i in "${!existing_dirs[@]}"; do
        echo "$((i+1))) ${existing_dirs[$i]}"
    done
    last_option=$(( ${#existing_dirs[@]} + 1 ))
    echo "$last_option) Otro (especificar ruta personalizada)"
    echo ""
    
    read -p "Seleccione destino [1-$last_option]: " dir_choice
    
    if [[ "$dir_choice" =~ ^[0-9]+$ ]] && [ "$dir_choice" -le "${#existing_dirs[@]}" ]; then
        selected_dir="${existing_dirs[$((dir_choice-1))]}"
        project_subdir="$selected_dir/$project_name"
        echo "✓ Creando en: $selected_dir/$project_name"
    elif [[ "$dir_choice" =~ ^[0-9]+$ ]] && [ "$dir_choice" -eq "$last_option" ]; then
        read -p "Ruta personalizada en 'latex_projects/': " custom_path
        project_subdir="$custom_path"
    else
        error_exit "✗ Selección inválida."
    fi
else
    read -p "Ruta destino en 'latex_projects/' [default: $project_name]: " project_subdir
    project_subdir=${project_subdir:-$project_name}
fi

# Limpiar y validar ruta
project_subdir=$(echo "$project_subdir" | sed 's|^/||; s|/$||')
base_path="$PROJECTS_DIR/$project_subdir"

if [ -d "$base_path" ]; then
    project_path="$base_path/$project_name"
    echo "✓ Creando en directorio existente: $project_path"
elif [ -e "$base_path" ]; then
    error_exit "✗ La ruta existe pero no es directorio."
else
    project_path="$base_path"
fi

[ -d "$project_path" ] && error_exit "✗ El directorio ya existe."
mkdir -p "$project_path" || error_exit "✗ No se pudo crear directorio."
echo "✓ Directorio creado: $project_path"
echo ""

# --- Seleccionar plantilla ---
echo "Plantillas disponibles:"
templates=($(ls "$TEMPLATE_DIR" | grep -v mermaid))
for i in "${!templates[@]}"; do
    echo "$((i+1))) ${templates[$i]}"
done
echo ""

read -p "Seleccione plantilla [1-${#templates[@]}]: " template_choice
if ! [[ "$template_choice" =~ ^[0-9]+$ ]] || [ "$template_choice" -lt 1 ] || [ "$template_choice" -gt "${#templates[@]}" ]; then
    error_exit "✗ Selección inválida."
fi

selected_template="${templates[$((template_choice-1))]}"
SOURCE_TEMPLATE_DIR="$TEMPLATE_DIR/$selected_template"
echo "✓ Plantilla: $selected_template"
echo ""

# --- Soporte Mermaid ---
read -p "¿Incluir soporte para diagramas Mermaid? [s/N]: " use_mermaid
if [[ "$use_mermaid" =~ ^[Ss]$ ]]; then
    MERMAID_TEMPLATE_DIR="$TEMPLATE_DIR/mermaid"
    
    # Copiar .latexmkrc
    if [ -f "$MERMAID_TEMPLATE_DIR/.latexmkrc" ]; then
        cp "$MERMAID_TEMPLATE_DIR/.latexmkrc" "$project_path/"
        echo "✓ .latexmkrc copiado"
    fi
    
    # Crear estructura de directorios
    mkdir -p "$project_path/assets/mermaid" "$project_path/assets/diagrams" "$project_path/assets/images"
    echo "✓ Directorios assets/ creados"
    
    # Mostrar advertencia sobre dependencias
    echo ""
    echo "⚠ ADVERTENCIA: Para usar Mermaid necesita las siguientes dependencias:"
    echo "   1. Node.js, npm y Mermaid CLI (instalación automática en Windows)"
    echo "   2. Perl (para latexmk)"
    echo "   3. En Windows, ejecute como Administrador: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\setup-latex-mermaid.ps1"
    echo ""
    
    MERMAID_ENABLED=true
else
    MERMAID_ENABLED=false
fi

# --- Copiar plantilla ---
echo "📂 Copiando plantilla..."
cp -r "$SOURCE_TEMPLATE_DIR"/* "$project_path/" 2>/dev/null

# Limpiar archivos temporales
[ -f "$project_path/temp_main.tex" ] && rm "$project_path/temp_main.tex"
find "$project_path" -name "*.aux" -delete 2>/dev/null
find "$project_path" -name "*.log" -delete 2>/dev/null
find "$project_path" -name "*.out" -delete 2>/dev/null

echo "✓ Plantilla copiada."
echo ""

# --- Configurar archivos .tex ---
echo "⚙️  Configurando archivos .tex..."
    
# SOLUCIÓN SEGURA: Solo reemplazar texto plano, NO comandos LaTeX
echo "  Reemplazando placeholders en texto..."

# Procesar todos los archivos .tex en el proyecto
find "$project_path" -name "*.tex" -type f | while read -r tex_file; do
    echo "    Procesando: $(basename "$tex_file")"
    
    # 1. Título en texto plano
    sed -i "s|Título del Proyecto|$DOCUMENT_TITLE_ESCAPED|g" "$tex_file"
    sed -i "s|Título del Documento|$DOCUMENT_TITLE_ESCAPED|g" "$tex_file"
    sed -i "s|Project Title|$DOCUMENT_TITLE_ESCAPED|g" "$tex_file"
    sed -i "s|Título del Ensayo|$DOCUMENT_TITLE_ESCAPED|g" "$tex_file"
    sed -i "s|Asunto de la carta|$DOCUMENT_TITLE_ESCAPED|g" "$tex_file"
    
    # 2. Autor e información personal
    sed -i "s|Nombre del Autor|$AUTHOR_LATEX|g" "$tex_file"
    sed -i "s|Author Name|$AUTHOR_LATEX|g" "$tex_file"
    sed -i "s|Your Name|$AUTHOR_LATEX|g" "$tex_file"
    sed -i "s|Autor Principal|$AUTHOR_LATEX|g" "$tex_file"
    sed -i "s|Nombre Completo|$AUTHOR_LATEX|g" "$tex_file"
    sed -i "s|\[Nombre del Remitente\]|$AUTHOR_LATEX|g" "$tex_file"
    
    # 3. Institución y facultad
    sed -i "s|Universidad La Salle|$INSTITUTION|g" "$tex_file"
    sed -i "s|University Placeholder|$INSTITUTION|g" "$tex_file"
    sed -i "s|Corporación Unificada Nacional de Educación Superior|$INSTITUTION|g" "$tex_file"
    
    sed -i "s|Maestría en Inteligencia Artificial|$FACULTY|g" "$tex_file"
    sed -i "s|Faculty Placeholder|$FACULTY|g" "$tex_file"
    sed -i "s|Ingeniería Electrónica|$FACULTY|g" "$tex_file"
    
    # 4. Otros campos
    [ -n "$DEPARTMENT" ] && sed -i "s|Department, University|$DEPARTMENT|g" "$tex_file"
    [ -n "$DEPARTMENT" ] && sed -i "s|Cargo o Departamento|$DEPARTMENT|g" "$tex_file"
    [ -n "$DEPARTMENT" ] && sed -i "s|Departamento de Sistemas|$DEPARTMENT|g" "$tex_file"
    
    [ -n "$EMAIL" ] && sed -i "s|correo@institucional.edu.co|$EMAIL|g" "$tex_file"
    [ -n "$EMAIL" ] && sed -i "s|author@university.edu|$EMAIL|g" "$tex_file"
    [ -n "$EMAIL" ] && sed -i "s|email@correo.com|$EMAIL|g" "$tex_file"
    
    [ -n "$STUDENT_ID" ] && sed -i "s|Código estudiantil|$STUDENT_ID|g" "$tex_file"
    [ -n "$STUDENT_ID" ] && sed -i "s|Student ID Placeholder|$STUDENT_ID|g" "$tex_file"
    [ -n "$STUDENT_ID" ] && sed -i "s|C.C. Número de cédula|$STUDENT_ID|g" "$tex_file"
    
    [ -n "$DIRECTOR" ] && sed -i "s|Nombre del Director|$DIRECTOR|g" "$tex_file"
    
    [ -n "$PHONE" ] && sed -i "s|3001234567|$PHONE|g" "$tex_file"
    
    # 5. Campos para cartas
    [ -n "$CITY" ] && sed -i "s|Bogotá|$CITY|g" "$tex_file"
    [ -n "$CITY" ] && sed -i "s|Ciudad|$CITY|g" "$tex_file"
    [ -n "$CITY" ] && sed -i "s|CIUDAD|$CITY|g" "$tex_file"
    
    [ -n "$COUNTRY" ] && sed -i "s|Colombia|$COUNTRY|g" "$tex_file"
    
    [ -n "$ADDRESS" ] && sed -i "s|Dirección|$ADDRESS|g" "$tex_file"
    [ -n "$ADDRESS" ] && sed -i "s|Calle 123 #45-67|$ADDRESS|g" "$tex_file"
    
    # 6. Campos académicos
    [ -n "$COURSE" ] && sed -i "s|Nombre del Curso|$COURSE|g" "$tex_file"
    [ -n "$COURSE_CODE" ] && sed -i "s|Código del Curso|$COURSE_CODE|g" "$tex_file"
    [ -n "$SEMESTER" ] && sed -i "s|Semestre|$SEMESTER|g" "$tex_file"
    [ -n "$ACADEMIC_YEAR" ] && sed -i "s|Año Académico|$ACADEMIC_YEAR|g" "$tex_file"
    
    # 7. Fecha
    sed -i "s|YYYY-MM-DD|$DATE|g" "$tex_file"
    # NOTA: No reemplazamos \today para mantener fecha dinámica
    
    # 8. Placeholders específicos
    sed -i "s|NOMBRE DEL DESTINATARIO|Destinatario|g" "$tex_file"
    sed -i "s|\[Nombre del Destinatario\]|Destinatario|g" "$tex_file"
    sed -i "s|Destinatario|Destinatario|g" "$tex_file"  # Mantener si ya está
    
done

echo "  ✓ Placeholders reemplazados"
echo ""

# Buscar main.tex para mostrar comandos \newcommand
MAIN_TEX_FILE="$project_path/main.tex"
if [ -f "$MAIN_TEX_FILE" ]; then
    
    # 1. Título en texto plano
    sed -i "s|Título del Proyecto|$DOCUMENT_TITLE_ESCAPED|g" "$MAIN_TEX_FILE"
    sed -i "s|Título del Documento|$DOCUMENT_TITLE_ESCAPED|g" "$MAIN_TEX_FILE"
    sed -i "s|Project Title|$DOCUMENT_TITLE_ESCAPED|g" "$MAIN_TEX_FILE"
    sed -i "s|Título del Ensayo|$DOCUMENT_TITLE_ESCAPED|g" "$MAIN_TEX_FILE"
    
    # 2. Autor e información personal
    sed -i "s|Nombre del Autor|$AUTHOR_LATEX|g" "$MAIN_TEX_FILE"
    sed -i "s|Author Name|$AUTHOR_LATEX|g" "$MAIN_TEX_FILE"
    sed -i "s|Your Name|$AUTHOR_LATEX|g" "$MAIN_TEX_FILE"
    sed -i "s|Autor Principal|$AUTHOR_LATEX|g" "$MAIN_TEX_FILE"
    sed -i "s|Nombre Completo|$AUTHOR_LATEX|g" "$MAIN_TEX_FILE"
    
    # 3. Institución y facultad
    sed -i "s|Universidad La Salle|$INSTITUTION|g" "$MAIN_TEX_FILE"
    sed -i "s|University Placeholder|$INSTITUTION|g" "$MAIN_TEX_FILE"
    sed -i "s|Corporación Unificada Nacional de Educación Superior|$INSTITUTION|g" "$MAIN_TEX_FILE"
    
    sed -i "s|Maestría en Inteligencia Artificial|$FACULTY|g" "$MAIN_TEX_FILE"
    sed -i "s|Faculty Placeholder|$FACULTY|g" "$MAIN_TEX_FILE"
    sed -i "s|Ingeniería Electrónica|$FACULTY|g" "$MAIN_TEX_FILE"
    sed -i "s|Programa|$FACULTY|g" "$MAIN_TEX_FILE"
    # 4. Otros campos
    [ -n "$DEPARTMENT" ] && sed -i "s|Department, University|$DEPARTMENT|g" "$MAIN_TEX_FILE"
    [ -n "$DEPARTMENT" ] && sed -i "s|Cargo o Departamento|$DEPARTMENT|g" "$MAIN_TEX_FILE"
    
    [ -n "$EMAIL" ] && sed -i "s|correo@institucional.edu.co|$EMAIL|g" "$MAIN_TEX_FILE"
    [ -n "$EMAIL" ] && sed -i "s|author@university.edu|$EMAIL|g" "$MAIN_TEX_FILE"
    [ -n "$EMAIL" ] && sed -i "s|email@correo.com|$EMAIL|g" "$MAIN_TEX_FILE"
    
    [ -n "$STUDENT_ID" ] && sed -i "s|Código estudiantil|$STUDENT_ID|g" "$MAIN_TEX_FILE"
    [ -n "$STUDENT_ID" ] && sed -i "s|Student ID Placeholder|$STUDENT_ID|g" "$MAIN_TEX_FILE"
    [ -n "$STUDENT_ID" ] && sed -i "s|C.C. Número de cédula|$STUDENT_ID|g" "$MAIN_TEX_FILE"
    
    [ -n "$DIRECTOR" ] && sed -i "s|Nombre del Director|$DIRECTOR|g" "$MAIN_TEX_FILE"
    [ -n "$PHONE" ] && sed -i "s|3001234567|$PHONE|g" "$MAIN_TEX_FILE"
    
    # 5. Campos para cartas
    [ -n "$CITY" ] && sed -i "s|Bogotá|$CITY|g" "$MAIN_TEX_FILE"
    [ -n "$COUNTRY" ] && sed -i "s|Colombia|$COUNTRY|g" "$MAIN_TEX_FILE"
    [ -n "$ADDRESS" ] && sed -i "s|Dirección|$ADDRESS|g" "$MAIN_TEX_FILE"
    
    # 6. Campos académicos
    [ -n "$COURSE" ] && sed -i "s|Nombre del Curso|$COURSE|g" "$MAIN_TEX_FILE"
    [ -n "$COURSE_CODE" ] && sed -i "s|Código del Curso|$COURSE_CODE|g" "$MAIN_TEX_FILE"
    [ -n "$SEMESTER" ] && sed -i "s|Semestre|$SEMESTER|g" "$MAIN_TEX_FILE"
    [ -n "$ACADEMIC_YEAR" ] && sed -i "s|Año Académico|$ACADEMIC_YEAR|g" "$MAIN_TEX_FILE"
    
    # 7. Fecha
    sed -i "s|YYYY-MM-DD|$DATE|g" "$MAIN_TEX_FILE"
    # NOTA: No reemplazamos \today para mantener fecha dinámica
    
    # 8. Placeholders específicos de plantilla letter
    if [ "$selected_template" = "letter" ]; then
        sed -i "s|\[Nombre del Remitente\]|$AUTHOR_LATEX|g" "$MAIN_TEX_FILE"
        sed -i "s|NOMBRE DEL DESTINATARIO|Destinatario|g" "$MAIN_TEX_FILE"
        [ -n "$CITY" ] && sed -i "s|CIUDAD|$CITY|g" "$MAIN_TEX_FILE"
    fi
    
    echo "  ✓ Placeholders reemplazados"

    # Actualizar comandos \newcommand automáticamente
    if grep -q "\\\\newcommand" "$MAIN_TEX_FILE"; then
        echo "  Actualizando comandos LaTeX..."
        
        # Actualizar cada comando \newcommand
        [ -n "$DOCUMENT_TITLE" ] && sed -i "s|\\\\newcommand{\\\\\\titulo}{[^}]*}|\\\\newcommand{\\\\\\titulo}{$DOCUMENT_TITLE_ESCAPED}|" "$MAIN_TEX_FILE"
        [ -n "$AUTHOR_LATEX" ] && sed -i "s|\\\\newcommand{\\\\\\autor}{[^}]*}|\\\\newcommand{\\\\\\autor}{$AUTHOR_LATEX}|" "$MAIN_TEX_FILE"
        [ -n "$STUDENT_ID" ] && sed -i "s|\\\\newcommand{\\\\\\codigo}{[^}]*}|\\\\newcommand{\\\\\\codigo}{$STUDENT_ID}|" "$MAIN_TEX_FILE"
        [ -n "$FACULTY" ] && sed -i "s|\\\\newcommand{\\\\\\programa}{[^}]*}|\\\\newcommand{\\\\\\programa}{$FACULTY}|" "$MAIN_TEX_FILE"
        [ -n "$INSTITUTION" ] && sed -i "s|\\\\newcommand{\\\\\\\\universidad}{[^}]*}|\\\\newcommand{\\\\\\universidad}{$INSTITUTION}|" "$MAIN_TEX_FILE"
        [ -n "$DIRECTOR" ] && sed -i "s|\\\\newcommand{\\\\\\director}{[^}]*}|\\\\newcommand{\\\\\\director}{$DIRECTOR}|" "$MAIN_TEX_FILE"
        [ -n "$EMAIL" ] && sed -i "s|\\\\newcommand{\\\\\\correo}{[^}]*}|\\\\newcommand{\\\\\\correo}{$EMAIL}|" "$MAIN_TEX_FILE"
        
        echo "  ✓ Comandos LaTeX actualizados"
        echo ""
    fi
    echo ""
    
    # Mostrar instrucciones para comandos LaTeX
    echo "📝 ✅ Comandos LaTeX actualizados automáticamente:"
    echo ""
    
    # Buscar y mostrar comandos \newcommand que necesitan edición
    if grep -q "\\\\newcommand" "$MAIN_TEX_FILE"; then
        echo "  Comandos encontrados en main.tex:"
        grep "\\\\newcommand" "$MAIN_TEX_FILE" | while read -r line; do
            echo "    $line"
        done
        echo ""
        echo "  Comandos actualizados automáticamente:"
        echo "    • \\newcommand{\\titulo}{...} → \\newcommand{\\titulo}{$DOCUMENT_TITLE_ESCAPED}"
        echo "    • \\newcommand{\\autor}{...} → \\newcommand{\\autor}{$AUTHOR_LATEX}"
        echo "    • \\newcommand{\\universidad}{...} → \\newcommand{\\universidad}{$INSTITUTION}"
        echo "    • \\newcommand{\\programa}{...} → \\newcommand{\\programa}{$FACULTY}"
        echo "    • Otros comandos según sea necesario"
    fi
    
else
    echo "⚠ No se encontró main.tex. Creando básico..."
    
    # Crear autor para documento básico
    BASIC_AUTHOR="$AUTHOR_LATEX"
    if [ -n "$INSTITUTION" ]; then
        BASIC_AUTHOR="$BASIC_AUTHOR \\\\ $INSTITUTION"
    fi
    if [ -n "$FACULTY" ]; then
        BASIC_AUTHOR="$BASIC_AUTHOR \\\\ $FACULTY"
    fi
    
    cat > "$MAIN_TEX_FILE" << EOF
\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[spanish]{babel}
\usepackage{graphicx}
\usepackage{hyperref}

\title{$DOCUMENT_TITLE_ESCAPED}
\author{$BASIC_AUTHOR}
\date{\today}

\begin{document}
\maketitle
% Contenido aquí
\end{document}
EOF
    echo "✓ main.tex creado."
fi
echo ""

# --- Actualizar config.yaml de plantilla si existe ---
PROJECT_CONFIG="$project_path/config.yaml"
if [ -f "$PROJECT_CONFIG" ]; then
    echo "⚙️  Actualizando config.yaml del proyecto..."
    
    # Actualizar campos comunes
    sed -i "s|^author_name:.*|author_name: \"$AUTHORS_STR\"|" "$PROJECT_CONFIG"
    sed -i "s|^university:.*|university: \"$INSTITUTION\"|" "$PROJECT_CONFIG"
    sed -i "s|^faculty:.*|faculty: \"$FACULTY\"|" "$PROJECT_CONFIG"
    
    [ -n "$EMAIL" ] && sed -i "s|^author_email:.*|author_email: \"$EMAIL\"|" "$PROJECT_CONFIG"
    [ -n "$STUDENT_ID" ] && sed -i "s|^author_id:.*|author_id: \"$STUDENT_ID\"|" "$PROJECT_CONFIG"
    [ -n "$DIRECTOR" ] && sed -i "s|^director:.*|director: \"$DIRECTOR\"|" "$PROJECT_CONFIG"
    
    echo "✓ config.yaml actualizado"
    echo ""
fi

# ================================================
# MENSAJE FINAL
# ================================================
echo "================================================"
echo "  ✅ PROYECTO CREADO EXITOSAMENTE"
echo "================================================"
echo ""
echo "📌 Detalles:"
echo "   • Nombre (carpeta): $project_name"
echo "   • Título del documento: $DOCUMENT_TITLE"
echo "   • Ubicación: $project_path"
echo "   • Plantilla: $selected_template"
echo ""

echo "📋 Configuración aplicada:"
echo "   • Autor(es): $AUTHORS_STR"
echo "   • Institución: $INSTITUTION"
echo "   • Facultad: $FACULTY"
[ -n "$DEPARTMENT" ] && echo "   • Departamento: $DEPARTMENT"
[ -n "$EMAIL" ] && echo "   • Email: $EMAIL"
[ -n "$PHONE" ] && echo "   • Teléfono: $PHONE"
[ -n "$STUDENT_ID" ] && echo "   • Código estudiantil: $STUDENT_ID"
[ -n "$DIRECTOR" ] && echo "   • Director: $DIRECTOR"
[ -n "$DATE" ] && echo "   • Fecha: $DATE"
echo ""

if [ "$MERMAID_ENABLED" = true ]; then
    echo "🔧 Configuración Mermaid:"
    echo "   1. Dependencias: Node.js, npm, Mermaid CLI, Perl (instalación automática en Windows)"
    echo "   2. Crear diagramas en assets/mermaid/*.mmd"
    echo "   3. Compilar con: latexmk -pdf main.tex"
    echo "   4. Los diagramas se generan automáticamente en assets/diagrams/"
    echo "   5. En Windows, ejecute como Administrador:"
    echo "      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass"
    echo "      .\setup-latex-mermaid.ps1"
    echo ""
fi
