#!/bin/bash

###############################################################################
# Script de Instalação do Claude Code CLI na VPS
# Autor: Claude Code
# Descrição: Instala Node.js e Claude Code CLI para uso com n8n
###############################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Claude Code CLI - Instalação na VPS${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Aviso: Rodando como root. É recomendável usar um usuário não-root.${NC}"
fi

echo -e "${GREEN}[1/4] Instalando Node.js via nvm...${NC}"

# Baixar e instalar nvm
if [ ! -d "$HOME/.nvm" ]; then
    echo "Baixando nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
    echo -e "${YELLOW}nvm já está instalado${NC}"
fi

# Carregar nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Adicionar ao .bashrc se ainda não estiver
if ! grep -q 'NVM_DIR' ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo '# NVM Configuration' >> ~/.bashrc
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
fi

# Instalar Node.js 22
echo "Instalando Node.js 22..."
nvm install 22
nvm use 22
nvm alias default 22

# Verificar instalação
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
echo -e "${GREEN}Node.js instalado: $NODE_VERSION${NC}"
echo -e "${GREEN}npm instalado: $NPM_VERSION${NC}"
echo ""

echo -e "${GREEN}[2/4] Instalando Claude Code CLI...${NC}"

# Instalar Claude Code CLI globalmente
npm install -g @anthropic-ai/claude-code

# Verificar instalação
CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "instalado")
echo -e "${GREEN}Claude Code CLI: $CLAUDE_VERSION${NC}"
echo ""

echo -e "${GREEN}[3/4] Configurando diretório de trabalho...${NC}"

# Criar diretório para projetos do Claude Code
CLAUDE_WORKSPACE="$HOME/claude-workspace"
mkdir -p "$CLAUDE_WORKSPACE"
echo -e "${GREEN}Diretório criado: $CLAUDE_WORKSPACE${NC}"
echo ""

echo -e "${GREEN}[4/4] Instalação concluída!${NC}"
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}PRÓXIMOS PASSOS:${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${BLUE}1. Autenticar Claude Code CLI:${NC}"
echo -e "   cd $CLAUDE_WORKSPACE"
echo -e "   claude"
echo -e "   ${YELLOW}(Siga as instruções no terminal)${NC}"
echo ""
echo -e "${BLUE}2. Configurar WhatsApp MCP:${NC}"
echo -e "   Edite o arquivo de configuração do Claude Code"
echo -e "   para adicionar o servidor WhatsApp MCP"
echo ""
echo -e "${BLUE}3. Integrar com n8n:${NC}"
echo -e "   Use 'Execute Command' no n8n para chamar:"
echo -e "   ${GREEN}claude <comando>${NC}"
echo ""
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${BLUE}Comandos úteis:${NC}"
echo -e "  claude --help          - Ver ajuda"
echo -e "  claude --version       - Ver versão"
echo -e "  node -v                - Verificar Node.js"
echo -e "  npm -v                 - Verificar npm"
echo ""
echo -e "${GREEN}Para começar:${NC}"
echo -e "  cd $CLAUDE_WORKSPACE && claude"
echo ""
