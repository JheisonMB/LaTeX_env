#!/usr/bin/env bash
# setup-latex-mermaid.sh - Instalación y validación de dependencias (macOS/Linux)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Configuración de LaTeX + Mermaid ===${NC}\n"

# ── Detección de sistema operativo ──────────────────────────────────────────
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    PKG_MANAGER="brew"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    else
        PKG_MANAGER="unknown"
    fi
else
    echo -e "${RED}Sistema operativo no soportado: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}Sistema detectado: $OS ($PKG_MANAGER)${NC}\n"

# ── Funciones auxiliares ────────────────────────────────────────────────────
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 instalado"
        return 0
    else
        echo -e "${RED}✗${NC} $1 no encontrado"
        return 1
    fi
}

install_package() {
    local pkg="$1"
    echo -e "${YELLOW}Instalando $pkg...${NC}"
    
    case "$PKG_MANAGER" in
        brew)
            brew install "$pkg"
            ;;
        apt)
            sudo apt-get update && sudo apt-get install -y "$pkg"
            ;;
        dnf)
            sudo dnf install -y "$pkg"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$pkg"
            ;;
        *)
            echo -e "${RED}Gestor de paquetes no soportado. Instala $pkg manualmente.${NC}"
            return 1
            ;;
    esac
}

# ── Validación de LaTeX ─────────────────────────────────────────────────────
echo -e "${BLUE}[1/4] Verificando LaTeX...${NC}"

if ! check_command pdflatex || ! check_command latexmk; then
    echo -e "${YELLOW}LaTeX no está instalado completamente.${NC}"
    read -rp "¿Deseas instalarlo? [s/N] " install_latex
    
    if [[ "$install_latex" =~ ^[Ss]$ ]]; then
        case "$OS" in
            macos)
                echo -e "${YELLOW}Instalando BasicTeX (ligero) o MacTeX (completo)...${NC}"
                echo "Opción 1: brew install --cask basictex (recomendado, ~100MB)"
                echo "Opción 2: brew install --cask mactex (completo, ~4GB)"
                read -rp "Selecciona [1/2]: " tex_option
                if [[ "$tex_option" == "1" ]]; then
                    brew install --cask basictex
                    eval "$(/usr/libexec/path_helper)"
                    sudo tlmgr update --self
                    sudo tlmgr install latexmk
                else
                    brew install --cask mactex
                fi
                ;;
            linux)
                if [[ "$PKG_MANAGER" == "apt" ]]; then
                    install_package texlive-latex-base
                    install_package texlive-latex-extra
                    install_package latexmk
                elif [[ "$PKG_MANAGER" == "dnf" ]]; then
                    install_package texlive-scheme-basic
                    install_package latexmk
                elif [[ "$PKG_MANAGER" == "pacman" ]]; then
                    install_package texlive-core
                    install_package texlive-latexextra
                fi
                ;;
        esac
    fi
fi

# ── Validación de Perl ──────────────────────────────────────────────────────
echo -e "\n${BLUE}[2/4] Verificando Perl...${NC}"

if ! check_command perl; then
    read -rp "¿Deseas instalar Perl? [s/N] " install_perl
    if [[ "$install_perl" =~ ^[Ss]$ ]]; then
        install_package perl
    fi
fi

# ── Validación de Node.js ───────────────────────────────────────────────────
echo -e "\n${BLUE}[3/4] Verificando Node.js...${NC}"

if ! check_command node || ! check_command npm; then
    read -rp "¿Deseas instalar Node.js? [s/N] " install_node
    if [[ "$install_node" =~ ^[Ss]$ ]]; then
        case "$OS" in
            macos)
                brew install node
                ;;
            linux)
                if [[ "$PKG_MANAGER" == "apt" ]]; then
                    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                    install_package nodejs
                else
                    install_package nodejs
                    install_package npm
                fi
                ;;
        esac
    fi
fi

# ── Validación de Mermaid CLI ──────────────────────────────────────────────
echo -e "\n${BLUE}[4/4] Verificando Mermaid CLI...${NC}"

if ! check_command mmdc; then
    read -rp "¿Deseas instalar Mermaid CLI? [s/N] " install_mermaid
    if [[ "$install_mermaid" =~ ^[Ss]$ ]]; then
        npm install -g @mermaid-js/mermaid-cli
    fi
fi

# ── Resumen ─────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}=== Resumen de instalación ===${NC}"
check_command pdflatex && check_command latexmk && echo -e "${GREEN}✓ LaTeX listo${NC}" || echo -e "${RED}✗ LaTeX incompleto${NC}"
check_command perl && echo -e "${GREEN}✓ Perl listo${NC}" || echo -e "${RED}✗ Perl faltante${NC}"
check_command node && check_command npm && echo -e "${GREEN}✓ Node.js listo${NC}" || echo -e "${RED}✗ Node.js faltante${NC}"
check_command mmdc && echo -e "${GREEN}✓ Mermaid CLI listo${NC}" || echo -e "${RED}✗ Mermaid CLI faltante${NC}"

echo -e "\n${GREEN}Configuración completada.${NC}"
echo -e "Ejecuta: ${YELLOW}./create_latex_project.sh${NC} para crear un proyecto."
