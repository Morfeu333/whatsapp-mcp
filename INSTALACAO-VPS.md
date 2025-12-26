# Guia de Instalação do WhatsApp MCP na VPS

Este guia fornece instruções passo a passo para instalar e configurar o WhatsApp MCP em uma VPS Ubuntu 24.04 (testado na Hostinger).

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Instalação Automatizada](#instalação-automatizada)
4. [Instalação Manual](#instalação-manual)
5. [Autenticação do WhatsApp](#autenticação-do-whatsapp)
6. [Configuração do Claude Desktop](#configuração-do-claude-desktop)
7. [Gerenciamento do Serviço](#gerenciamento-do-serviço)
8. [Solução de Problemas](#solução-de-problemas)

## 🎯 Visão Geral

A arquitetura do WhatsApp MCP consiste em dois componentes que rodam na VPS:

1. **WhatsApp Bridge (Go)**: Mantém conexão com WhatsApp e expõe API na porta 8080
2. **MCP Server (Python)**: Conecta-se à bridge e traduz comandos para o formato MCP

```
[Claude Desktop] ──SSH──> [VPS: MCP Server] ──Local──> [VPS: WhatsApp Bridge] ──Internet──> [WhatsApp]
```

## ✅ Pré-requisitos

### Na VPS:
- Ubuntu 24.04 (ou similar)
- Acesso root via SSH
- Pelo menos 1GB de RAM
- 2GB de espaço em disco

### No Computador Local:
- Claude Desktop instalado
- Cliente SSH configurado
- Chave SSH para autenticação

## 🚀 Instalação Automatizada

### Passo 1: Acesse sua VPS via SSH

```bash
ssh root@SEU_IP_VPS
```

### Passo 2: Clone o repositório

Se ainda não clonou:

```bash
cd ~
git clone https://github.com/lharries/whatsapp-mcp.git
cd whatsapp-mcp
```

Ou se já está na pasta do projeto:

```bash
cd ~/whatsapp-mcp
```

### Passo 3: Execute o script de instalação

```bash
chmod +x install-vps.sh
./install-vps.sh
```

O script irá:
- ✅ Atualizar o sistema
- ✅ Instalar Go 1.24.1
- ✅ Instalar Python e UV
- ✅ Compilar o WhatsApp Bridge
- ✅ Configurar dependências Python
- ✅ Criar serviço systemd

### Passo 4: Autenticar o WhatsApp

Após a instalação, você precisa escanear o QR Code:

```bash
cd ~/whatsapp-mcp/whatsapp-bridge
./whatsapp-bridge
```

**Instruções:**
1. Abra o WhatsApp no seu celular
2. Vá em **Dispositivos Conectados** → **Conectar Dispositivo**
3. Escaneie o QR Code que aparece no terminal
4. Aguarde a mensagem "Connected to WhatsApp!"
5. Pressione `Ctrl+C` para parar

A sessão foi salva e não será necessário escanear novamente (exceto após ~20 dias).

### Passo 5: Iniciar o serviço

```bash
systemctl start whatsapp-bridge
systemctl enable whatsapp-bridge
systemctl status whatsapp-bridge
```

Se tudo estiver correto, você verá `active (running)` em verde.

## 📱 Configuração do Claude Desktop

### Passo 1: Gerar configuração

Na VPS, execute:

```bash
cd ~/whatsapp-mcp
chmod +x generate-claude-config.sh
./generate-claude-config.sh
```

Copie o JSON gerado.

### Passo 2: Configurar autenticação SSH (no seu computador local)

**Linux/macOS:**

```bash
# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/vps_whatsapp

# Copiar para a VPS
ssh-copy-id -i ~/.ssh/vps_whatsapp.pub root@SEU_IP_VPS
```

**Windows (PowerShell):**

```powershell
# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\vps_whatsapp

# Copiar manualmente o conteúdo de vps_whatsapp.pub
# e adicionar em ~/.ssh/authorized_keys na VPS
```

### Passo 3: Testar conexão SSH

```bash
ssh -i ~/.ssh/vps_whatsapp root@SEU_IP_VPS 'echo "Conexão OK!"'
```

Se aparecer "Conexão OK!", a autenticação está funcionando.

### Passo 4: Configurar Claude Desktop

Edite o JSON copiado no Passo 1 e substitua o caminho da chave SSH.

**macOS:**

```bash
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Cole o JSON, substituindo `/caminho/para/sua/chave-privada.pem` por:
- `~/.ssh/vps_whatsapp` (caminho completo, ex: `/Users/seunome/.ssh/vps_whatsapp`)

**Windows:**

Edite: `%APPDATA%\Claude\claude_desktop_config.json`

Substitua por: `C:/Users/SeuUsuario/.ssh/vps_whatsapp`

**Para Cursor:**

- macOS/Linux: `~/.cursor/mcp.json`
- Windows: `%USERPROFILE%\.cursor\mcp.json`

### Passo 5: Reiniciar Claude Desktop

Feche completamente o Claude Desktop e reabra. Você deverá ver "WhatsApp" nos servidores MCP disponíveis.

## 🔧 Instalação Manual

Se preferir instalar manualmente, siga os passos abaixo.

### 1. Instalar dependências básicas

```bash
apt update && apt upgrade -y
apt install -y build-essential ffmpeg git curl wget
```

### 2. Instalar Go

```bash
wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version
```

### 3. Instalar UV (gerenciador Python)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source "$HOME/.cargo/env"
```

### 4. Compilar WhatsApp Bridge

```bash
cd ~/whatsapp-mcp/whatsapp-bridge
go mod tidy
go build -o whatsapp-bridge main.go
```

### 5. Configurar MCP Server

```bash
cd ~/whatsapp-mcp/whatsapp-mcp-server
uv sync
```

### 6. Criar serviço systemd

```bash
nano /etc/systemd/system/whatsapp-bridge.service
```

Cole:

```ini
[Unit]
Description=WhatsApp MCP Bridge
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/whatsapp-mcp/whatsapp-bridge
ExecStart=/root/whatsapp-mcp/whatsapp-bridge/whatsapp-bridge
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Ative o serviço:

```bash
systemctl daemon-reload
systemctl enable whatsapp-bridge
```

## 🎮 Gerenciamento do Serviço

### Comandos úteis

```bash
# Iniciar serviço
systemctl start whatsapp-bridge

# Parar serviço
systemctl stop whatsapp-bridge

# Reiniciar serviço
systemctl restart whatsapp-bridge

# Ver status
systemctl status whatsapp-bridge

# Ver logs em tempo real
journalctl -u whatsapp-bridge -f

# Ver logs das últimas 100 linhas
journalctl -u whatsapp-bridge -n 100

# Ver logs desde hoje
journalctl -u whatsapp-bridge --since today
```

## 🔍 Solução de Problemas

### Serviço não inicia

```bash
# Ver logs detalhados
journalctl -u whatsapp-bridge -n 50

# Verificar se a porta 8080 está em uso
netstat -tulpn | grep 8080

# Testar manualmente
cd ~/whatsapp-mcp/whatsapp-bridge
./whatsapp-bridge
```

### QR Code não aparece

```bash
# Verificar se o terminal suporta QR Code
# Tente via SSH com -X para X11 forwarding
ssh -X root@SEU_IP_VPS

# Ou use um terminal que suporte
```

### Mensagens não sincronizam

```bash
# Limpar banco de dados e reautenticar
systemctl stop whatsapp-bridge
cd ~/whatsapp-mcp/whatsapp-bridge/store
rm -f messages.db whatsapp.db
cd ..
./whatsapp-bridge  # Escanear QR Code novamente
# Ctrl+C após conectar
systemctl start whatsapp-bridge
```

### Claude Desktop não conecta

```bash
# Verificar se SSH funciona
ssh -i ~/.ssh/vps_whatsapp root@SEU_IP_VPS 'echo OK'

# Verificar se UV está no caminho correto
ssh -i ~/.ssh/vps_whatsapp root@SEU_IP_VPS 'which uv'

# Verificar logs do Claude Desktop
# macOS:
tail -f ~/Library/Logs/Claude/mcp*.log

# Windows:
# Veja em %APPDATA%\Claude\logs\
```

### Serviço cai após algum tempo

```bash
# Verificar memória
free -h

# Verificar se há erros
journalctl -u whatsapp-bridge --since "1 hour ago" | grep -i error

# Aumentar RestartSec se necessário
nano /etc/systemd/system/whatsapp-bridge.service
# Altere RestartSec=10 para RestartSec=30
systemctl daemon-reload
systemctl restart whatsapp-bridge
```

## 🔒 Segurança

### Recomendações:

1. **Firewall**: Configure UFW para permitir apenas SSH
```bash
ufw allow ssh
ufw enable
```

2. **Fail2ban**: Proteja contra ataques de força bruta
```bash
apt install fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

3. **Autenticação SSH**: Use apenas chaves, desabilite senha
```bash
nano /etc/ssh/sshd_config
# Altere: PasswordAuthentication no
systemctl restart sshd
```

4. **Atualizações**: Mantenha o sistema atualizado
```bash
apt update && apt upgrade -y
```

## 📊 Monitoramento

### Verificar uso de recursos

```bash
# CPU e memória
htop

# Espaço em disco
df -h

# Tamanho do banco de dados
du -sh ~/whatsapp-mcp/whatsapp-bridge/store/
```

## 🆘 Suporte

Se você encontrar problemas:

1. Verifique os logs: `journalctl -u whatsapp-bridge -f`
2. Consulte a [documentação oficial](https://github.com/lharries/whatsapp-mcp)
3. Abra uma issue no GitHub

## 📝 Notas Importantes

- A autenticação do WhatsApp expira após aproximadamente 20 dias
- O banco de dados SQLite cresce com o tempo (faça backups regulares)
- Todas as mensagens ficam armazenadas localmente na VPS
- O Claude Desktop acessa a VPS via SSH a cada requisição

## ✅ Checklist de Instalação

- [ ] VPS configurada e acessível via SSH
- [ ] Script de instalação executado com sucesso
- [ ] QR Code escaneado e WhatsApp conectado
- [ ] Serviço systemd ativo e habilitado
- [ ] Chave SSH configurada no computador local
- [ ] Claude Desktop configurado com JSON correto
- [ ] Teste de conexão SSH bem-sucedido
- [ ] Claude Desktop reconhece o servidor WhatsApp MCP
- [ ] Primeiro teste de envio/recebimento de mensagem

---

**Desenvolvido com ❤️ por Claude Code**
