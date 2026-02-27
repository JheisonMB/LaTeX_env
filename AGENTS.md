# AGENTS.md - Configuration for AI Agents

## Overview

This repository contains LaTeX templates and academic projects organized by institution and document type. This file provides guidelines for AI agents working in this repository.

## Repository Structure

```
LaTeX/
├── templates/          # Reusable templates
│   ├── apa_unisalle/  # APA La Salle template
│   ├── apa_general/   # Generic APA template
│   ├── ieee/          # IEEE template
│   ├── letter/        # Formal letter template
│   ├── essay/         # Academic essay template
│   ├── general/       # Generic template
│   └── mermaid/      # Mermaid diagrams configuration
├── latex_projects/    # Existing projects (ignored in git)
│   ├── unisalle/     # Universidad La Salle projects
│   ├── cun/          # CUN projects
│   ├── uniminuto/    # Uniminuto projects
│   ├── sena/         # SENA projects
│   └── libro/        # "Eco del Silencio" book
└── CV/               # Resume/CV
```

## Build and Compilation Commands

### Basic LaTeX Compilation
```bash
# Standard compilation
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex  # For cross-references

# Single command compilation
latexmk -pdf main.tex

# Clean auxiliary files
latexmk -c
```

### Project Creation
```bash
# Create new LaTeX project from template
.\create_latex_project.ps1
```

### Mermaid Diagrams Compilation
```bash
# Configurar dependencias automáticamente (Windows)
# Ejecutar como Administrador: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\setup-latex-mermaid.ps1

# Full compilation with Mermaid support
latexmk -pdf document.tex  # Uses .latexmkrc configuration
```

### Viewing Output
```bash
# Linux
xdg-open main.pdf

# WSL
wslview main.pdf

# Windows (from WSL)
explorer.exe main.pdf
```

## Code Style Guidelines

### File Encoding and Format
- **Encoding**: Always use UTF-8 encoding
- **Line endings**: Use Unix line endings (LF)
- **Indentation**: Use spaces (4 spaces per level)
- **File naming**: Use lowercase with underscores for LaTeX files (e.g., `main.tex`, `sections/introduction.tex`)

### LaTeX Document Structure
```latex
% 1. Document class and packages
\documentclass[a4paper,12pt]{article}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[spanish]{babel}

% 2. Package imports (grouped by functionality)
\usepackage{amsmath, amssymb, amsfonts}  % Math
\usepackage{graphicx, float, caption}    % Figures
\usepackage{hyperref, url}               % Links
\usepackage{geometry, fancyhdr}          % Layout

% 3. Document configuration
\geometry{top=3cm,bottom=3cm,left=3cm,right=3cm}
\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,urlcolor=blue}

% 4. Title and metadata
\title{Document Title}
\author{Author Name}
\date{\today}

% 5. Document content
\begin{document}
\maketitle
% Content here
\end{document}
```

### Package Import Guidelines
1. **Order imports logically**: Document class → encoding → language → core packages → specialized packages
2. **Group related packages**: Keep math packages together, graphic packages together, etc.
3. **Use consistent spacing**: One package per line for readability
4. **Comment complex packages**: Add brief comments for non-standard packages

### Naming Conventions
- **Commands**: Use descriptive names with camelCase: `\newcommand{\myCustomCommand}`
- **Labels**: Use prefix notation: `fig:`, `tab:`, `eq:`, `sec:`
- **Files**: Use descriptive names: `introduction.tex`, `references.bib`
- **Variables**: Use meaningful names in math mode: `\theta`, `\mathbf{x}`, `\mathcal{L}`

### Commenting and Documentation
- **Header comments**: Every `.tex` file should start with a header comment describing its purpose
- **Section comments**: Comment major sections and complex formulas
- **TODO comments**: Use `% TODO: description` for incomplete sections
- **Excessive commenting**: This codebase values detailed comments for educational purposes

### Error Handling and Best Practices
1. **Use relative paths** for images and includes
2. **Always include error handling** for missing files: `\IfFileExists{file.tex}{\input{file.tex}}{File not found}`
3. **Validate references** before final compilation
4. **Use `\usepackage{hyperref}`** as the last package to avoid conflicts

### Template-Specific Guidelines

#### APA Templates
- Follow APA 7th edition formatting
- Use `\usepackage{csquotes}` for quotations
- Include abstract and keywords sections
- Use hanging indentation for references

#### IEEE Template
- Use `\documentclass[10pt,journal]{IEEEtran}`
- Include `\IEEEmembership{}` for author affiliations
- Use `\IEEEPARstart{}{}` for paragraph starts
- Follow IEEE citation style

#### Mermaid Integration
- Store `.mmd` files in `assets/mermaid/`
- Generated diagrams go to `assets/diagrams/`
- Include `.latexmkrc` for automatic compilation
- Use `\usepackage{graphicx}` for diagram inclusion

## Project Organization

### Creating New Projects
1. Use `create_latex_project.ps1` for new projects
2. Follow existing template structure
3. Place projects in appropriate institution directory
4. Update documentation if adding new template types

### File Organization
```
project/
├── main.tex              # Main document
├── sections/             # Document sections
│   ├── introduction.tex
│   ├── methodology.tex
│   └── conclusion.tex
├── assets/               # Media and diagrams
│   ├── images/
│   ├── mermaid/
│   └── diagrams/
├── references.bib        # Bibliography
└── config.yaml           # Project configuration (optional)
```

### Git Practices
- **Ignore generated files**: Follow `.gitignore` for LaTeX auxiliary files
- **Commit messages**: Use descriptive commit messages
- **Branch naming**: Use feature/ prefix for new features
- **Never commit**: `.pdf`, `.aux`, `.log`, `.out`, or other generated files

## Testing and Validation

### Compilation Testing
```bash
# Test compilation without errors
pdflatex -interaction=nonstopmode main.tex

# Check for undefined references
pdflatex main.tex
bibtex main
pdflatex main.tex | grep -E "undefined|multiply defined"

# Validate bibliography
bibtex main | grep -E "Warning|Error"
```

### Linting and Style Checking
```bash
# Check for common LaTeX errors
chktex main.tex

# Validate syntax
lacheck main.tex

# Check spelling (Spanish)
aspell --lang=es --check main.tex
```

### Cross-Reference Validation
```bash
# Generate cross-reference report
pdflatex main.tex
makeindex main.idx
pdflatex main.tex | grep -E "Label.*multiply defined|Reference.*undefined"
```

## Agent-Specific Instructions

### When Editing LaTeX Files
1. **Always preserve UTF-8 encoding**
2. **Maintain Spanish language settings** for academic projects
3. **Follow existing commenting patterns** (this codebase values detailed comments)
4. **Use consistent spacing** (blank lines between sections)
5. **Update all cross-references** when modifying structure

### When Creating New Templates
1. **Study existing templates** for patterns
2. **Include comprehensive documentation**
3. **Test compilation** with multiple LaTeX engines
4. **Add to `create_latex_project.ps1`** if it's a general-purpose template

### When Working with Projects
1. **Respect institution-specific requirements**
2. **Maintain academic formatting standards**
3. **Use appropriate bibliography styles**
4. **Include necessary institutional branding**

### Security and Safety
- **Never include sensitive information** in templates
- **Use relative paths** to avoid system dependencies
- **Validate external package sources**
- **Avoid shell command injection** in LaTeX documents

## Troubleshooting

### Common Issues
1. **Encoding problems**: Ensure `\usepackage[utf8]{inputenc}` is present
2. **Missing packages**: Check `tlmgr` or package manager for missing LaTeX packages
3. **Bibliography errors**: Run `bibtex` multiple times if needed
4. **Cross-reference issues**: Compile multiple times to resolve references

### WSL-Specific Notes
- Use `wslview` to open PDFs from WSL
- Paths may need Windows-style escaping in some cases
- Ensure LaTeX distribution is installed in WSL (e.g., `texlive-full`)

## Quick Reference

### Essential Commands
```bash
# Create project
.\create_latex_project.ps1

# Compile
pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex

# Clean
rm -f *.aux *.log *.out *.toc *.bbl *.blg

# View
wslview main.pdf
```

### Key Files
- `templates/` - Source for all templates
- `latex_projects/` - Completed projects by institution (ignored in git)
- `create_latex_project.ps1` - Project creation script
- `.gitignore` - Git ignore rules for LaTeX
- `.latexmkrc` - Mermaid compilation configuration

### Contact
For issues or improvements to this AGENTS.md file, update it directly or create an issue in the repository.