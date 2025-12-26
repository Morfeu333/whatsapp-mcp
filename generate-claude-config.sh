#!/bin/bash

###############################################################################
# Script para Gerar Configuração do Claude Desktop
# Autor: Claude Code
# Descrição: Gera o JSON de configuração para conectar o Claude Desktop à VPS
###############################################################################

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Gerador de Configuração Claude Desktop${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Detectar informações do sistema
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UV_PATH=$(which uv 2>/dev/null || echo "$HOME/.cargo/bin/uv")
VPS_IP=$(hostname -I | awk '{print $1}')

# Se o IP não for detectado, tenta pegar o IP público
if [ -z "$VPS_IP" ]; then
    VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "SEU_IP_VPS")
fi

echo -e "${YELLOW}Informações Detectadas:${NC}"
echo -e "  - Diretório do projeto: $PROJECT_DIR"
echo -e "  - Caminho do UV: $UV_PATH"
echo -e "  - IP da VPS: $VPS_IP"
echo ""

echo -e "${BLUE}IMPORTANTE:${NC}"
echo -e "  Este JSON deve ser usado no seu ${GREEN}computador local${NC}, não na VPS!"
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Configuração para Claude Desktop${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

cat << EOF
{
  "mcpServers": {
    "whatsapp": {
      "command": "ssh",
      "args": [
        "-i",
        "/caminho/para/sua/chave-privada.pem",
        "root@${VPS_IP}",
        "${UV_PATH}",
        "--directory",
        "${PROJECT_DIR}/whatsapp-mcp-server",
        "run",
        "main.py"
      ]
    }
  }
}
EOF

echo ""
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Instruções de Configuração${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "1. ${GREEN}Copie o JSON acima${NC}"
echo ""
echo -e "2. ${GREEN}Configure autenticação SSH sem senha no seu computador local:${NC}"
echo ""
echo -e "   ${BLUE}No seu computador local:${NC}"
echo -e "   # Gerar chave SSH (se ainda não tiver)"
echo -e "   ssh-keygen -t rsa -b 4096 -f ~/.ssh/vps_whatsapp"
echo ""
echo -e "   # Copiar chave pública para a VPS"
echo -e "   ssh-copy-id -i ~/.ssh/vps_whatsapp.pub root@${VPS_IP}"
echo ""
echo -e "   ${BLUE}Ou manualmente:${NC}"
echo -e "   # Copie o conteúdo de ~/.ssh/vps_whatsapp.pub"
echo -e "   # Cole no arquivo ~/.ssh/authorized_keys da VPS"
echo ""
echo -e "3. ${GREEN}Edite o JSON e substitua:${NC}"
echo -e "   ${YELLOW}\"/caminho/para/sua/chave-privada.pem\"${NC} por:"
echo -e "   - macOS/Linux: ${BLUE}\"$HOME/.ssh/vps_whatsapp\"${NC}"
echo -e "   - Windows: ${BLUE}\"C:/Users/SeuUsuario/.ssh/vps_whatsapp\"${NC}"
echo ""
echo -e "4. ${GREEN}Salve o JSON no local apropriado:${NC}"
echo ""
echo -e "   ${BLUE}Claude Desktop (macOS):${NC}"
echo -e "   ~/Library/Application Support/Claude/claude_desktop_config.json"
echo ""
echo -e "   ${BLUE}Claude Desktop (Windows):${NC}"
echo -e "   %APPDATA%\\Claude\\claude_desktop_config.json"
echo ""
echo -e "   ${BLUE}Cursor (macOS/Linux):${NC}"
echo -e "   ~/.cursor/mcp.json"
echo ""
echo -e "   ${BLUE}Cursor (Windows):${NC}"
echo -e "   %USERPROFILE%\\.cursor\\mcp.json"
echo ""
echo -e "5. ${GREEN}Reinicie o Claude Desktop ou Cursor${NC}"
echo ""
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${GREEN}Teste a conexão SSH:${NC}"
echo -e "ssh -i ~/.ssh/vps_whatsapp root@${VPS_IP} 'echo Conexão OK!'"
echo ""
echo -e "${YELLOW}========================================${NC}"
echo ""
