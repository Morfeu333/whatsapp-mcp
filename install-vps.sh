#!/bin/bash

###############################################################################
# Script de Instalação do WhatsApp MCP para VPS Ubuntu 24.04
# Autor: Claude Code
# Descrição: Instala e configura o WhatsApp MCP na VPS
###############################################################################

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}WhatsApp MCP - Instalação para VPS${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Por favor, execute como root (use sudo)${NC}"
    exit 1
fi

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${YELLOW}Diretório do projeto: $PROJECT_DIR${NC}"

echo ""
echo -e "${GREEN}[1/7] Atualizando sistema e instalando dependências básicas...${NC}"
apt update && apt upgrade -y
apt install -y build-essential ffmpeg git curl wget

echo ""
echo -e "${GREEN}[2/7] Instalando Go 1.24.1...${NC}"
if command -v go &> /dev/null; then
    CURRENT_GO_VERSION=$(go version | awk '{print $3}')
    echo -e "${YELLOW}Go já instalado: $CURRENT_GO_VERSION${NC}"
    read -p "Deseja reinstalar? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
        rm go1.24.1.linux-amd64.tar.gz
    fi
else
    wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
    rm go1.24.1.linux-amd64.tar.gz
fi

# Adicionar Go ao PATH se não estiver
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
fi

source ~/.bashrc 2>/dev/null || true
export PATH=$PATH:/usr/local/go/bin

GO_VERSION=$(/usr/local/go/bin/go version)
echo -e "${GREEN}Go instalado: $GO_VERSION${NC}"

echo ""
echo -e "${GREEN}[3/7] Instalando Python e UV...${NC}"
if command -v uv &> /dev/null; then
    echo -e "${YELLOW}UV já instalado${NC}"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Adicionar UV ao PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    if ! grep -q ".cargo/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    fi
fi

source "$HOME/.cargo/env" 2>/dev/null || true
export PATH="$HOME/.cargo/bin:$PATH"

echo -e "${GREEN}UV instalado: $(uv --version)${NC}"

echo ""
echo -e "${GREEN}[4/7] Compilando WhatsApp Bridge...${NC}"
cd "$PROJECT_DIR/whatsapp-bridge"

echo "Baixando dependências do Go..."
/usr/local/go/bin/go mod tidy

echo "Compilando o binário..."
/usr/local/go/bin/go build -o whatsapp-bridge main.go

echo -e "${GREEN}WhatsApp Bridge compilado com sucesso!${NC}"

echo ""
echo -e "${GREEN}[5/7] Configurando dependências Python (MCP Server)...${NC}"
cd "$PROJECT_DIR/whatsapp-mcp-server"
uv sync

echo ""
echo -e "${GREEN}[6/7] Criando serviço systemd...${NC}"

# Criar arquivo de serviço systemd
cat > /etc/systemd/system/whatsapp-bridge.service << EOF
[Unit]
Description=WhatsApp MCP Bridge
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR/whatsapp-bridge
ExecStart=$PROJECT_DIR/whatsapp-bridge/whatsapp-bridge
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo -e "${GREEN}Serviço systemd criado!${NC}"

echo ""
echo -e "${GREEN}[7/7] Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}PRÓXIMOS PASSOS:${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "1. ${GREEN}Autenticar o WhatsApp (escanear QR Code):${NC}"
echo -e "   cd $PROJECT_DIR/whatsapp-bridge"
echo -e "   ./whatsapp-bridge"
echo -e "   ${YELLOW}Escaneie o QR Code com seu WhatsApp${NC}"
echo -e "   ${YELLOW}Após conectar, pressione Ctrl+C${NC}"
echo ""
echo -e "2. ${GREEN}Iniciar o serviço:${NC}"
echo -e "   systemctl start whatsapp-bridge"
echo -e "   systemctl enable whatsapp-bridge"
echo ""
echo -e "3. ${GREEN}Verificar status:${NC}"
echo -e "   systemctl status whatsapp-bridge"
echo ""
echo -e "4. ${GREEN}Ver logs:${NC}"
echo -e "   journalctl -u whatsapp-bridge -f"
echo ""
echo -e "5. ${GREEN}Configurar Claude Desktop no seu computador local:${NC}"
echo -e "   Execute: $PROJECT_DIR/generate-claude-config.sh"
echo ""
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${GREEN}Instalação concluída com sucesso! ✓${NC}"
echo ""
