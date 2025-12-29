# Guia de Instalação do Claude Code CLI na VPS

Este guia mostra como instalar e configurar o Claude Code CLI na VPS para integração com n8n e WhatsApp MCP.

## 📋 Índice

1. [Instalação](#instalação)
2. [Autenticação](#autenticação)
3. [Configuração do WhatsApp MCP](#configuração-do-whatsapp-mcp)
4. [Integração com n8n](#integração-com-n8n)
5. [Uso e Exemplos](#uso-e-exemplos)

## 🚀 Instalação

### Passo 1: Execute o script de instalação

```bash
cd ~/whatsapp-mcp
chmod +x install-claude-code-cli.sh
./install-claude-code-cli.sh
```

Isso instalará:
- Node.js 22 via nvm
- Claude Code CLI globalmente
- Criará o diretório de trabalho `~/claude-workspace`

### Passo 2: Recarregue o shell

```bash
source ~/.bashrc
```

### Verificar instalação

```bash
node -v    # Deve mostrar v22.x.x
npm -v     # Deve mostrar a versão do npm
claude --version  # Deve mostrar a versão do Claude Code
```

## 🔐 Autenticação

### Primeiro uso

```bash
cd ~/claude-workspace
claude
```

**O que vai acontecer:**
1. O CLI perguntará sobre preferências de terminal (modo escuro, etc.)
2. Mostrará uma URL e um código temporário
3. Você precisa abrir a URL no navegador
4. Fazer login com sua conta Claude.ai ou Anthropic Console
5. Autorizar o dispositivo
6. Copiar o código de volta no terminal

**IMPORTANTE:** Como você está em uma VPS sem interface gráfica:

1. O CLI mostrará algo como:
   ```
   Visit: https://claude.ai/activate
   Code: ABCD-1234
   ```

2. **No seu computador local**, abra o navegador e acesse a URL
3. Insira o código mostrado
4. Complete a autenticação
5. Volte ao terminal da VPS e pressione Enter

### Verificar autenticação

```bash
claude --help
```

Se autenticado corretamente, você verá todos os comandos disponíveis.

## 🔧 Configuração do WhatsApp MCP

### Localizar arquivo de configuração

O Claude Code CLI usa um arquivo de configuração similar ao Claude Desktop:

```bash
# Criar diretório de configuração se não existir
mkdir -p ~/.config/claude-code

# Criar ou editar arquivo de configuração
nano ~/.config/claude-code/config.json
```

### Adicionar configuração do WhatsApp MCP

Cole o seguinte JSON:

```json
{
  "mcpServers": {
    "whatsapp": {
      "command": "/root/.local/bin/uv",
      "args": [
        "--directory",
        "/root/whatsapp-mcp/whatsapp-mcp-server",
        "run",
        "main.py"
      ]
    }
  }
}
```

**Ajuste os caminhos:**
- Verifique o caminho do `uv`: `which uv`
- Verifique o caminho do projeto: `pwd` dentro de `~/whatsapp-mcp`

### Testar configuração

```bash
cd ~/claude-workspace
claude
```

Pergunte ao Claude: "Quais servidores MCP estão disponíveis?"

Você deve ver "whatsapp" na lista.

## 🔗 Integração com n8n

### Opção 1: Execute Command Node

No n8n, use o node **Execute Command**:

**Configuração básica:**
```json
{
  "command": "claude",
  "arguments": "Olá, liste meus contatos do WhatsApp"
}
```

**Com variáveis:**
```json
{
  "command": "bash",
  "arguments": "-c \"source ~/.bashrc && source ~/.nvm/nvm.sh && claude '{{ $json.prompt }}'\""
}
```

### Opção 2: HTTP Request (se expuser API)

Você pode criar um wrapper HTTP para o Claude Code CLI:

```bash
# Instalar Express.js
cd ~/claude-workspace
npm init -y
npm install express body-parser
```

Criar `claude-api.js`:

```javascript
const express = require('express');
const { exec } = require('child_process');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

app.post('/execute', (req, res) => {
    const { prompt } = req.body;

    if (!prompt) {
        return res.status(400).json({ error: 'Prompt is required' });
    }

    const command = `source ~/.bashrc && source ~/.nvm/nvm.sh && claude "${prompt.replace(/"/g, '\\"')}"`;

    exec(command, { shell: '/bin/bash' }, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: error.message, stderr });
        }
        res.json({ output: stdout, stderr });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Claude API running on port ${PORT}`);
});
```

**Iniciar o servidor:**
```bash
node claude-api.js
```

**No n8n, use HTTP Request:**
```json
{
  "method": "POST",
  "url": "http://localhost:3000/execute",
  "body": {
    "prompt": "{{ $json.message }}"
  }
}
```

### Opção 3: Webhook do n8n

Configure um webhook no n8n que recebe prompts e executa o Claude Code CLI.

## 📚 Uso e Exemplos

### Comandos básicos do Claude Code CLI

```bash
# Modo interativo
claude

# Executar comando direto
claude "Liste os arquivos neste diretório"

# Com contexto específico
claude --project ~/meu-projeto "Analise este código"

# Ver ajuda
claude --help

# Ver versão
claude --version
```

### Exemplos com WhatsApp MCP

```bash
# Listar contatos
claude "Liste meus contatos do WhatsApp"

# Buscar mensagens
claude "Busque mensagens da Maria dos últimos 7 dias"

# Enviar mensagem
claude "Envie uma mensagem para João dizendo 'Olá, tudo bem?'"

# Buscar e resumir
claude "Busque minhas últimas conversas e resuma os pontos principais"
```

### Exemplo de workflow no n8n

**Cenário:** Receber webhook, processar com Claude + WhatsApp MCP, retornar resultado

1. **Webhook Node**: Recebe dados
2. **Execute Command Node**:
   ```json
   {
     "command": "bash",
     "arguments": "-c \"source ~/.bashrc && source ~/.nvm/nvm.sh && cd ~/claude-workspace && claude 'Busque mensagens do WhatsApp sobre {{ $json.topic }} e resuma'\""
   }
   ```
3. **Code Node**: Processar output
4. **Respond to Webhook**: Retornar resultado

## 🔒 Segurança

### Recomendações:

1. **Não exponha a API publicamente sem autenticação**
   ```javascript
   // Adicionar auth token simples
   const AUTH_TOKEN = process.env.AUTH_TOKEN || 'seu-token-secreto';

   app.use((req, res, next) => {
       const token = req.headers['authorization'];
       if (token !== `Bearer ${AUTH_TOKEN}`) {
           return res.status(401).json({ error: 'Unauthorized' });
       }
       next();
   });
   ```

2. **Use variáveis de ambiente para credenciais**
   ```bash
   export ANTHROPIC_API_KEY="sua-chave-aqui"
   ```

3. **Limite de taxa (rate limiting)**
   ```bash
   npm install express-rate-limit
   ```

4. **Use HTTPS se expor externamente**

## 🐛 Troubleshooting

### Problema: `claude: command not found`

**Solução:**
```bash
source ~/.bashrc
source ~/.nvm/nvm.sh
nvm use 22
```

Ou use o caminho completo:
```bash
/root/.nvm/versions/node/v22.x.x/bin/claude
```

### Problema: MCP não conecta ao WhatsApp Bridge

**Verificar:**
1. WhatsApp Bridge está rodando: `systemctl status whatsapp-bridge`
2. Porta 8080 está aberta: `netstat -tuln | grep 8080`
3. Caminho do `uv` está correto no config.json

### Problema: Autenticação expira

**Re-autenticar:**
```bash
cd ~/claude-workspace
claude
# Siga o processo de autenticação novamente
```

### Problema: n8n não consegue executar comando

**Verificar permissões:**
```bash
# Se n8n roda como outro usuário
sudo chmod +x /root/.nvm/versions/node/*/bin/claude
```

**Usar sudo no n8n (não recomendado):**
```json
{
  "command": "sudo",
  "arguments": "-u root bash -c 'source ~/.bashrc && claude \"...\"'"
}
```

## 📊 Monitoramento

### Logs do Claude Code

```bash
# Ver logs de sessão
ls ~/.claude/sessions/

# Ver última sessão
cat ~/.claude/sessions/latest.log
```

### Criar serviço para API HTTP (opcional)

```bash
sudo nano /etc/systemd/system/claude-api.service
```

```ini
[Unit]
Description=Claude Code API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/claude-workspace
ExecStart=/root/.nvm/versions/node/v22.x.x/bin/node claude-api.js
Restart=always
RestartSec=10
Environment="PATH=/root/.nvm/versions/node/v22.x.x/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable claude-api
sudo systemctl start claude-api
sudo systemctl status claude-api
```

## ✅ Checklist de Instalação

- [ ] Node.js 22+ instalado via nvm
- [ ] Claude Code CLI instalado globalmente
- [ ] Claude Code CLI autenticado
- [ ] WhatsApp MCP configurado no config.json
- [ ] Teste de comando básico funcionando
- [ ] Teste de integração com WhatsApp MCP funcionando
- [ ] Integração com n8n configurada
- [ ] (Opcional) API HTTP wrapper criada
- [ ] (Opcional) Serviço systemd configurado

---

**Desenvolvido com ❤️ por Claude Code**
