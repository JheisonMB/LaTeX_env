# .creator/placeholders.ps1 - Reemplazo de placeholders en archivos .tex

function Replace-Placeholders($projectPath, $cfg, $title, $date) {
    $authorLatex = $cfg['autores'] -replace ',\s*', ' \\ '
    $titleEsc    = $title -replace '_', '\\_'

    $map = [ordered]@{
        # Título
        'Título del Proyecto'   = $titleEsc
        'Título del Documento'  = $titleEsc
        'Project Title'         = $titleEsc
        'Título del Ensayo'     = $titleEsc
        'Asunto de la carta'    = $titleEsc
        # Autor
        'Nombre del Autor'      = $authorLatex
        'Author Name'           = $authorLatex
        'Your Name'             = $authorLatex
        'Autor Principal'       = $authorLatex
        'Nombre Completo'       = $authorLatex
        '\[Nombre del Remitente\]' = $authorLatex
        # Institución
        'Universidad La Salle'                              = $cfg['institucion']
        'University Placeholder'                            = $cfg['institucion']
        'Corporación Unificada Nacional de Educación Superior' = $cfg['institucion']
        # Facultad
        'Maestría en Inteligencia Artificial' = $cfg['facultad']
        'Faculty Placeholder'                 = $cfg['facultad']
        'Ingeniería Electrónica'              = $cfg['facultad']
        # Fecha
        'YYYY-MM-DD' = $date
    }

    # Campos opcionales
    if ($cfg['departamento']) { $map['Department, University'] = $cfg['departamento']; $map['Cargo o Departamento'] = $cfg['departamento'] }
    if ($cfg['email'])        { $map['correo@institucional.edu.co'] = $cfg['email']; $map['author@university.edu'] = $cfg['email']; $map['email@correo.com'] = $cfg['email'] }
    if ($cfg['codigo_estudiantil']) { $map['Código estudiantil'] = $cfg['codigo_estudiantil']; $map['C.C. Número de cédula'] = $cfg['codigo_estudiantil'] }
    if ($cfg['director'])     { $map['Nombre del Director'] = $cfg['director'] }
    if ($cfg['telefono'])     { $map['3001234567'] = $cfg['telefono'] }
    if ($cfg['ciudad'])       { $map['Bogotá'] = $cfg['ciudad']; $map['CIUDAD'] = $cfg['ciudad'] }
    if ($cfg['pais'])         { $map['Colombia'] = $cfg['pais'] }
    if ($cfg['direccion'])    { $map['Calle 123 #45-67'] = $cfg['direccion'] }
    if ($cfg['curso'])        { $map['Nombre del Curso'] = $cfg['curso'] }
    if ($cfg['codigo_curso']) { $map['Código del Curso'] = $cfg['codigo_curso'] }
    if ($cfg['semestre'])     { $map['Semestre'] = $cfg['semestre'] }
    if ($cfg['ano_academico']){ $map['Año Académico'] = $cfg['ano_academico'] }

    Get-ChildItem $projectPath -Recurse -Filter "*.tex" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -Encoding UTF8
        foreach ($k in $map.Keys) {
            if ($map[$k]) { $content = $content -replace [regex]::Escape($k), $map[$k] }
        }
        # \newcommand updates
        $content = $content -replace '(\\newcommand\{\\titulo\}\{)[^}]*(})',   "`${1}$titleEsc`$2"
        $content = $content -replace '(\\newcommand\{\\autor\}\{)[^}]*(})',    "`${1}$authorLatex`$2"
        $content = $content -replace '(\\newcommand\{\\universidad\}\{)[^}]*(})', "`${1}$($cfg['institucion'])`$2"
        $content = $content -replace '(\\newcommand\{\\programa\}\{)[^}]*(})', "`${1}$($cfg['facultad'])`$2"
        if ($cfg['director'])          { $content = $content -replace '(\\newcommand\{\\director\}\{)[^}]*(})', "`${1}$($cfg['director'])`$2" }
        if ($cfg['email'])             { $content = $content -replace '(\\newcommand\{\\correo\}\{)[^}]*(})',   "`${1}$($cfg['email'])`$2" }
        if ($cfg['codigo_estudiantil']){ $content = $content -replace '(\\newcommand\{\\codigo\}\{)[^}]*(})',  "`${1}$($cfg['codigo_estudiantil'])`$2" }
        Set-Content $_.FullName $content -Encoding UTF8
    }
}
