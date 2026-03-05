# Guía de Uso Multiplataforma

## Resumen Rápido

Este sistema ahora funciona en **Windows**, **macOS** y **Linux** con scripts específicos para cada plataforma.

### ⚠️ Importante: Scripts NO son intercambiables

- **Windows**: usa `.bat` y `.ps1`
- **macOS/Linux**: usa `.sh`
- **NO puedes** ejecutar `.sh` desde PowerShell en Windows
- **NO puedes** ejecutar `.bat`/`.ps1` desde bash en macOS/Linux

## Comandos por Plataforma

### Windows (PowerShell)

```powershell
# Setup inicial (como Administrador)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup-latex-mermaid.ps1

# Crear proyecto
.\create_latex_project.bat

# Compilar
cd latex_projects\institucion\proyecto
latexmk -pdf main.tex
```

### macOS / Linux (Terminal)

```bash
# Setup inicial
chmod +x setup-latex-mermaid.sh
./setup-latex-mermaid.sh

# Crear proyecto
./create_latex_project.sh

# Compilar
cd latex_projects/institucion/proyecto
latexmk -pdf main.tex
```

## Estructura de Archivos

```
LaTeX_env/
├── create_latex_project.bat    # Launcher Windows
├── create_latex_project.sh     # Launcher macOS/Linux
├── setup-latex-mermaid.ps1     # Setup Windows
├── setup-latex-mermaid.sh      # Setup macOS/Linux
└── .creator/
    ├── create_latex_project.ps1  # Lógica Windows
    ├── config.ps1                # Config Windows
    ├── placeholders.ps1          # Placeholders Windows
    ├── config.sh                 # Config macOS/Linux
    └── placeholders.sh           # Placeholders macOS/Linux
```

## Funcionalidades Idénticas

Ambas versiones (Windows y macOS/Linux) tienen:

✅ Lectura/escritura de `config.yaml`  
✅ Navegación interactiva de directorios  
✅ Selección de plantillas  
✅ Soporte para Mermaid  
✅ Reemplazo de placeholders  
✅ Validación de nombres de proyecto  

## Diferencias Técnicas

| Aspecto | Windows | macOS/Linux |
|---------|---------|-------------|
| Shell | PowerShell | Bash |
| Extensión | `.ps1`, `.bat` | `.sh` |
| Permisos | Execution Policy | `chmod +x` |
| Paths | `\` backslash | `/` forward slash |
| Encoding | UTF-8 BOM | UTF-8 |

## Troubleshooting

### Windows
**Error: "no se puede cargar porque la ejecución de scripts está deshabilitada"**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### macOS/Linux
**Error: "Permission denied"**
```bash
chmod +x *.sh .creator/*.sh
```

**Error: "command not found: latexmk"**
```bash
# macOS
eval "$(/usr/libexec/path_helper)"

# Linux
sudo apt install latexmk  # Ubuntu/Debian
```

## Migración desde Versión Anterior (solo Windows)

Si ya usabas la versión anterior:

1. Tu `config.yaml` sigue funcionando sin cambios
2. Tus proyectos en `latex_projects/` no se ven afectados
3. Los scripts Windows (`.bat`, `.ps1`) siguen funcionando igual
4. Ahora también puedes usar los scripts en macOS/Linux

## Soporte

- **Windows**: Probado en Windows 10/11 con PowerShell 5.1+
- **macOS**: Probado en macOS 10.15+ con bash 3.2+
- **Linux**: Probado en Ubuntu 20.04+, Fedora 35+, Arch Linux
