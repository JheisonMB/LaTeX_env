@echo off
chcp 65001 >nul
echo ========================================
echo  Verificando dependencias para Mermaid
echo ========================================
echo.

echo [1/3] Verificando Node.js...
echo [1/4] Verificando Perl (para latexmk)...
perl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   Perl NO encontrado.
    echo   Instala desde: https://www.perl.org/get.html (Strawberry Perl recomendado)
    echo   O con winget: winget install Perl.Perl
    goto :error
)
echo   OK: Perl disponible.

echo [2/4] Verificando Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   Node.js NO encontrado.
    echo   Instala desde: https://nodejs.org/ (version LTS)
    echo   O con winget: winget install OpenJS.NodeJS
    goto :error
)
echo   OK: Node.js disponible.

echo [3/4] Verificando npm...
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   npm NO encontrado. Revisa la instalacion de Node.js.
    goto :error
)
echo   OK: npm disponible.

echo [4/4] Verificando Mermaid CLI (mmdc)...
mmdc --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   Instalando Mermaid CLI...
    npm install -g @mermaid-js/mermaid-cli
    if %errorlevel% neq 0 (
        echo   ERROR en instalacion
        goto :error
    )
    echo   Instalacion completada.
) else (
    echo   OK: Mermaid CLI disponible.
)

echo.
echo ========================================
echo  Configurando proyecto
echo ========================================

if not exist "assets" (
    mkdir assets\diagrams
    mkdir assets\mermaid
    echo   Carpetas 'assets/diagrams' y 'assets/mermaid' creadas.
)

if not exist "assets\mermaid\*.mmd" (
    echo No hay archivos .mmd
    goto :skipcompile
)

echo.
echo ========================================
echo  Compilando diagramas
echo ========================================

for %%f in (assets\mermaid\*.mmd) do (
    echo %%~nf.mmd ^> %%~nf.png
    mmdc.cmd -i "%%f" -o "assets\diagrams\%%~nf.png" -w 1200
    if %errorlevel% equ 0 (
        echo   OK
    ) else (
        echo   ERROR
    )
)

:skipcompile
echo.
echo ========================================
echo  Completado
echo ========================================
dir assets\diagrams\*.png 2>nul
exit /b 0

:error
echo.
echo ========================================
echo  ERROR: Faltan dependencias
echo ========================================
exit /b 1
