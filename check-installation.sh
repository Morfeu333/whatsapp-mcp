#!/bin/bash

###############################################################################
# Script de Diagnóstico do WhatsApp MCP
# Autor: Claude Code
# Descrição: Verifica se a instalação está correta e identifica problemas
###############################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Símbolos
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}WhatsApp MCP - Diagnóstico do Sistema${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Contador de problemas
PROBLEMS=0

# Função para verificar comando
check_command() {
    local cmd=$1
    local name=$2
    local required=$3

    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n1 || echo "versão desconhecida")
        echo -e "${CHECK} ${name}: ${GREEN}Instalado${NC} (${version})"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${CROSS} ${name}: ${RED}NÃO INSTALADO${NC} (obrigatório)"
            ((PROBLEMS++))
        else
            echo -e "${WARN} ${name}: ${YELLOW}Não instalado${NC} (opcional)"
        fi
        return 1
    fi
}

# Função para verificar arquivo
check_file() {
    local file=$1
    local name=$2

    if [ -f "$file" ]; then
        echo -e "${CHECK} ${name}: ${GREEN}Encontrado${NC}"
        return 0
    else
        echo -e "${CROSS} ${name}: ${RED}NÃO ENCONTRADO${NC}"
        ((PROBLEMS++))
        return 1
    fi
}

# Função para verificar diretório
check_dir() {
    local dir=$1
    local name=$2

    if [ -d "$dir" ]; then
        echo -e "${CHECK} ${name}: ${GREEN}Encontrado${NC}"
        return 0
    else
        echo -e "${CROSS} ${name}: ${RED}NÃO ENCONTRADO${NC}"
        ((PROBLEMS++))
        return 1
    fi
}

# Função para verificar serviço
check_service() {
    local service=$1

    if systemctl is-active --quiet $service; then
        echo -e "${CHECK} Serviço ${service}: ${GREEN}Rodando${NC}"

        # Mostrar uptime
        local uptime=$(systemctl show $service --property=ActiveEnterTimestamp --value)
        echo -e "   ${BLUE}Iniciado em:${NC} $uptime"

        return 0
    elif systemctl is-enabled --quiet $service 2>/dev/null; then
        echo -e "${WARN} Serviço ${service}: ${YELLOW}Parado${NC} (mas habilitado)"
        ((PROBLEMS++))
        return 1
    else
        echo -e "${CROSS} Serviço ${service}: ${RED}NÃO CONFIGURADO${NC}"
        ((PROBLEMS++))
        return 1
    fi
}

# Verificações de Sistema
echo -e "${YELLOW}[1] Informações do Sistema${NC}"
echo -e "  Sistema Operacional: $(uname -s)"
echo -e "  Versão: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo -e "  Arquitetura: $(uname -m)"
echo -e "  Hostname: $(hostname)"
echo ""

# Verificações de Dependências
echo -e "${YELLOW}[2] Dependências do Sistema${NC}"
check_command go "Go" true
check_command uv "UV (Python manager)" true
check_command python3 "Python 3" true
check_command ffmpeg "FFmpeg" false
check_command git "Git" true
check_command curl "cURL" true
echo ""

# Verificações de Diretórios e Arquivos
echo -e "${YELLOW}[3] Estrutura do Projeto${NC}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "  Diretório do projeto: ${BLUE}$PROJECT_DIR${NC}"
echo ""

check_dir "$PROJECT_DIR/whatsapp-bridge" "Diretório whatsapp-bridge"
check_dir "$PROJECT_DIR/whatsapp-mcp-server" "Diretório whatsapp-mcp-server"
check_file "$PROJECT_DIR/whatsapp-bridge/main.go" "Código fonte Go"
check_file "$PROJECT_DIR/whatsapp-mcp-server/main.py" "Código fonte Python"
check_file "$PROJECT_DIR/whatsapp-bridge/whatsapp-bridge" "Binário compilado"
echo ""

# Verificações de Banco de Dados
echo -e "${YELLOW}[4] Banco de Dados e Sessão${NC}"
check_dir "$PROJECT_DIR/whatsapp-bridge/store" "Diretório store"

if [ -f "$PROJECT_DIR/whatsapp-bridge/store/whatsapp.db" ]; then
    echo -e "${CHECK} Sessão WhatsApp: ${GREEN}Encontrada${NC}"

    # Verificar tamanho do banco
    local db_size=$(du -h "$PROJECT_DIR/whatsapp-bridge/store/whatsapp.db" | cut -f1)
    echo -e "   ${BLUE}Tamanho:${NC} $db_size"
else
    echo -e "${WARN} Sessão WhatsApp: ${YELLOW}Não encontrada${NC} (QR Code não escaneado)"
fi

if [ -f "$PROJECT_DIR/whatsapp-bridge/store/messages.db" ]; then
    echo -e "${CHECK} Banco de mensagens: ${GREEN}Encontrado${NC}"

    local db_size=$(du -h "$PROJECT_DIR/whatsapp-bridge/store/messages.db" | cut -f1)
    echo -e "   ${BLUE}Tamanho:${NC} $db_size"

    # Contar mensagens (se sqlite3 estiver disponível)
    if command -v sqlite3 &> /dev/null; then
        local msg_count=$(sqlite3 "$PROJECT_DIR/whatsapp-bridge/store/messages.db" "SELECT COUNT(*) FROM messages;" 2>/dev/null || echo "?")
        echo -e "   ${BLUE}Mensagens:${NC} $msg_count"
    fi
else
    echo -e "${WARN} Banco de mensagens: ${YELLOW}Não encontrado${NC}"
fi
echo ""

# Verificações de Serviço
echo -e "${YELLOW}[5] Serviço Systemd${NC}"
if [ -f "/etc/systemd/system/whatsapp-bridge.service" ]; then
    check_service "whatsapp-bridge"

    # Mostrar logs recentes se houver erros
    if ! systemctl is-active --quiet whatsapp-bridge; then
        echo ""
        echo -e "${YELLOW}Últimas 10 linhas do log:${NC}"
        journalctl -u whatsapp-bridge -n 10 --no-pager 2>/dev/null | sed 's/^/   /'
    fi
else
    echo -e "${CROSS} Arquivo de serviço: ${RED}NÃO ENCONTRADO${NC}"
    echo -e "   ${YELLOW}Execute:${NC} ./install-vps.sh para criar"
    ((PROBLEMS++))
fi
echo ""

# Verificações de Rede
echo -e "${YELLOW}[6] Conectividade${NC}"

# Verificar se a porta 8080 está em uso
if netstat -tuln 2>/dev/null | grep -q ":8080"; then
    echo -e "${CHECK} Porta 8080: ${GREEN}Em uso${NC} (WhatsApp Bridge)"
elif ss -tuln 2>/dev/null | grep -q ":8080"; then
    echo -e "${CHECK} Porta 8080: ${GREEN}Em uso${NC} (WhatsApp Bridge)"
else
    echo -e "${WARN} Porta 8080: ${YELLOW}Não está em uso${NC}"
    echo -e "   ${YELLOW}O serviço pode não estar rodando${NC}"
fi

# Verificar conexão com internet
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${CHECK} Conexão com internet: ${GREEN}OK${NC}"
else
    echo -e "${CROSS} Conexão com internet: ${RED}FALHOU${NC}"
    ((PROBLEMS++))
fi

# Obter IP público
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Não detectado")
echo -e "${BLUE}IP Público da VPS:${NC} $PUBLIC_IP"
echo ""

# Verificações de Recursos
echo -e "${YELLOW}[7] Recursos do Sistema${NC}"

# Memória
total_mem=$(free -h | awk '/^Mem:/ {print $2}')
used_mem=$(free -h | awk '/^Mem:/ {print $3}')
echo -e "  Memória Total: ${BLUE}$total_mem${NC}"
echo -e "  Memória Usada: ${BLUE}$used_mem${NC}"

# Disco
disk_usage=$(df -h "$PROJECT_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
disk_avail=$(df -h "$PROJECT_DIR" | awk 'NR==2 {print $4}')
echo -e "  Espaço em disco usado: ${BLUE}${disk_usage}%${NC}"
echo -e "  Espaço disponível: ${BLUE}$disk_avail${NC}"

if [ "$disk_usage" -gt 90 ]; then
    echo -e "  ${WARN} ${YELLOW}Pouco espaço em disco!${NC}"
fi
echo ""

# Resumo Final
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Resumo do Diagnóstico${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $PROBLEMS -eq 0 ]; then
    echo -e "${GREEN}✓ Nenhum problema encontrado!${NC}"
    echo ""
    echo -e "${GREEN}Seu WhatsApp MCP está configurado corretamente.${NC}"
    echo ""
    echo -e "Próximos passos:"
    echo -e "  1. Se o serviço não está rodando: ${BLUE}systemctl start whatsapp-bridge${NC}"
    echo -e "  2. Configure o Claude Desktop: ${BLUE}./generate-claude-config.sh${NC}"
else
    echo -e "${RED}✗ Encontrados $PROBLEMS problema(s)${NC}"
    echo ""
    echo -e "${YELLOW}Recomendações:${NC}"

    if ! command -v go &> /dev/null; then
        echo -e "  • Instale o Go: ${BLUE}./install-vps.sh${NC}"
    fi

    if ! command -v uv &> /dev/null; then
        echo -e "  • Instale o UV: ${BLUE}curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
    fi

    if [ ! -f "$PROJECT_DIR/whatsapp-bridge/whatsapp-bridge" ]; then
        echo -e "  • Compile o WhatsApp Bridge: ${BLUE}cd whatsapp-bridge && go build -o whatsapp-bridge main.go${NC}"
    fi

    if [ ! -f "/etc/systemd/system/whatsapp-bridge.service" ]; then
        echo -e "  • Configure o serviço: ${BLUE}./install-vps.sh${NC}"
    fi

    if [ ! -f "$PROJECT_DIR/whatsapp-bridge/store/whatsapp.db" ]; then
        echo -e "  • Autentique o WhatsApp: ${BLUE}cd whatsapp-bridge && ./whatsapp-bridge${NC}"
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# Comandos úteis
echo -e "${YELLOW}Comandos Úteis:${NC}"
echo -e "  Ver logs em tempo real: ${BLUE}journalctl -u whatsapp-bridge -f${NC}"
echo -e "  Reiniciar serviço: ${BLUE}systemctl restart whatsapp-bridge${NC}"
echo -e "  Ver status: ${BLUE}systemctl status whatsapp-bridge${NC}"
echo -e "  Reexecutar diagnóstico: ${BLUE}./check-installation.sh${NC}"
echo ""

exit $PROBLEMS
