# .creator/config.ps1 - Lectura y escritura de config.yaml

function Read-Config($configFile) {
    $cfg = @{}
    if (-not (Test-Path $configFile)) { return $cfg }
    foreach ($line in Get-Content $configFile) {
        if ($line -match '^\s*#' -or $line -notmatch ':') { continue }
        $key, $val = $line -split ':', 2
        $cfg[$key.Trim()] = $val.Trim().Trim('"')
    }
    # autores: soporta lista YAML simple (- "valor")
    $raw = Get-Content $configFile -Raw
    if ($raw -match '(?s)autores:(.*?)(\n\w|\z)') {
        $block = $Matches[1]
        $items = [regex]::Matches($block, '-\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        if ($items) { $cfg['autores'] = $items -join ', ' }
    }
    return $cfg
}

function Write-Config($configFile, $cfg) {
    $authorsList = ($cfg['autores'] -split ',\s*' | ForEach-Object { "  - `"$($_.Trim())`"" }) -join "`n"
    @"
autores:
$authorsList

institucion: "$($cfg['institucion'])"
facultad: "$($cfg['facultad'])"
departamento: "$($cfg['departamento'])"
email: "$($cfg['email'])"
telefono: "$($cfg['telefono'])"
codigo_estudiantil: "$($cfg['codigo_estudiantil'])"
director: "$($cfg['director'])"
ciudad: "$($cfg['ciudad'])"
pais: "$($cfg['pais'])"
direccion: "$($cfg['direccion'])"
curso: "$($cfg['curso'])"
codigo_curso: "$($cfg['codigo_curso'])"
semestre: "$($cfg['semestre'])"
ano_academico: "$($cfg['ano_academico'])"
"@ | Set-Content $configFile -Encoding UTF8
    Write-Host "   Configuracion guardada." -ForegroundColor Green
}

function Prompt-Config($cfg) {
    function Ask($label, $key) {
        $current = $cfg[$key]
        $input = Read-Host "  $label [$current]"
        if ($input) { $cfg[$key] = $input }
    }
    Ask "Autor(es) separados por coma" "autores"
    Ask "Institucion"                  "institucion"
    Ask "Facultad"                     "facultad"
    Ask "Departamento"                 "departamento"
    Ask "Email"                        "email"
    Ask "Telefono"                     "telefono"
    Ask "Codigo estudiantil"           "codigo_estudiantil"
    Ask "Director"                     "director"
    Ask "Ciudad"                       "ciudad"
    Ask "Pais"                         "pais"
    Ask "Direccion"                    "direccion"
    Ask "Curso"                        "curso"
    Ask "Codigo curso"                 "codigo_curso"
    Ask "Semestre"                     "semestre"
    Ask "Ano academico"                "ano_academico"
    return $cfg
}
