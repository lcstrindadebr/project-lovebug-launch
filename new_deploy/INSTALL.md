# 🚀 Guia Definitivo de Instalação - Bivvo

Este guia foi criado para que **qualquer pessoa**, mesmo sem conhecimento técnico, consiga colocar o sistema Bivvo no ar.

O código-fonte oficial fica em: **https://github.com/lcstrindadebr/project-lovebug-launch**

---

## ⚡ Instalação Automática (RECOMENDADO)

Em **5 minutos** o sistema estará no ar. O instalador faz tudo sozinho:
atualiza o Ubuntu, instala Node.js + Nginx + Certbot, clona o repositório,
configura o `.env`, faz o build, configura o subdomínio e gera o SSL HTTPS.

### Pré-requisitos
1. **VPS Ubuntu 22.04** (DigitalOcean, Hetzner, Contabo, etc.) com acesso root.
2. **Subdomínio** (ex: `app.seudominio.com.br`) apontando (registro A) para o IP da VPS.
3. **Projeto Supabase** já criado (anote URL e chave `anon`).
4. **Conta no Asaas** com API Key.

### Executar o instalador
Conecte na VPS via SSH e cole:

```bash
curl -fsSL https://raw.githubusercontent.com/lcstrindadebr/project-lovebug-launch/main/new_deploy/auto_install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh
```

O script vai perguntar:
- 🌐 Subdomínio
- 📧 Seu e-mail (para o SSL)
- 🔗 URL do Supabase
- 🔑 Chave anon do Supabase

Pronto. Ao final, o site estará rodando em `https://seu-subdominio` com HTTPS ativo.

---

## 🧩 Pós-Instalação (3 passos manuais no Supabase)

O instalador deixa a aplicação no ar, mas o **backend (Supabase)** precisa ser configurado uma única vez no painel:

### 1️⃣ Criar / atualizar as tabelas do banco
- No painel do Supabase, abra **SQL Editor → New Query**
- **Instalação nova:** cole em ordem `new_deploy/database_schema.sql` → `migrations/003` → `004` → `005` → `006` → `007` → `008` → `009` → `010` → `011` → `012`.
- **Atualização de uma instância já existente:** rode apenas as migrations novas em ordem. Todas são idempotentes.
- Clique em **Run** após cada uma.

> 💡 `004_security_and_settings.sql` traz delegação de tarefas por admin, whitelist pública de settings e endurecimento de RLS.
> 💡 `005_task_enhancements.sql` adiciona ao Kanban: **log automático da data de conclusão** (`completed_at`), **subtarefas** (checklist dentro da tarefa) e o marcador **"Aguardando ação de terceiro"** visível nos cards.
> 💡 `006_finance_metrics.sql` cria índices em `expenses(date)` e `expenses(category)` para acelerar os cards do dashboard.
> 💡 `007_bivvo_tenant_and_logs.sql` adiciona Setup Bivvo, suporte PF/PJ, inadimplência e logs de auditoria.
> 💡 `008_missing_admin_and_finance.sql` completa o schema com `admin_secrets` e Dashboards Financeiros.
> 💡 `009_bivvo_api_token.sql` adiciona gerenciamento do Token de API da Bivvo.
> 💡 `010_security_hardening_and_channels.sql` aplica correções de segurança (RLS), permissões de planos e canais dinâmicos.
> 💡 `011_unified_security_policy.sql` unifica as políticas de acesso para administradores em todas as tabelas.
> 💡 `012_eisenhower_matrix.sql` adiciona suporte à Matriz de Eisenhower e departamentos nas tarefas.

### 2️⃣ Cadastrar os Secrets (Asaas)
Vá em **Edge Functions → Secrets** e adicione:

| Nome | Valor |
|------|-------|
| `ASAAS_API_KEY` | Sua chave de API do Asaas |
| `ASAAS_BASE_URL` | `https://api.asaas.com/v3` (produção) ou `https://sandbox.asaas.com/api/v3` |
| `ASAAS_WEBHOOK_SECRET` | Um token/senha que você inventar (anote para o passo 4) |

### 3️⃣ Publicar as Edge Functions manualmente
As funções são **autossuficientes** (o código de `_shared` já vem inline em cada `index.ts`), o que permite copiar e colar diretamente no painel do Supabase.

Para cada função:
1. No Supabase, vá em **Edge Functions → Create a new function**
2. Dê o nome exato (ex: `process-payment`)
3. No repositório, abra o arquivo `new_deploy/functions/[NOME-DA-FUNÇÃO]/index.ts`
4. **Copie TODO o conteúdo** e cole no editor do Supabase.
5. Clique em **Deploy** ou **Save**.

Repita para todas as funções da pasta `new_deploy/functions/`:
`asaas-webhook`, `process-payment`, `create-subscription`, `check-payment-status`, `admin-api`, `affiliate-api`, `validate-coupon`, `provision-bivvo-tenant`, `auto-inactivate-overdue`.

> 💡 `provision-bivvo-tenant` cria/atualiza o tenant na API da Bivvo (rotas `tenantApiStoreTenant` / `tenantApiUpdateTenant`).
> 💡 `auto-inactivate-overdue` roda diariamente (agende em **Database → Cron Jobs** no Supabase) e inativa na Bivvo qualquer cliente com 5+ dias de inadimplência.
> 💡 `validate-coupon` valida cupons no checkout (inclui suporte a 100% de desconto na primeira mensalidade).

### 4️⃣ Configurar o Webhook no Asaas
- Painel do Asaas → **Integrações → Webhooks**
- URL: `https://SEU-PROJETO.supabase.co/functions/v1/asaas-webhook`
- Token: o mesmo valor de `ASAAS_WEBHOOK_SECRET`
- Eventos: `Pagamento Confirmado`, `Pagamento Recebido`, `Assinatura Cancelada`

---

## 🔧 Manutenção e Atualização

O script de instalação também serve para manutenção. Se você precisar trocar credenciais ou atualizar o site, basta rodar o mesmo comando novamente:

```bash
sudo ./install.sh
```

Ele detectará que o sistema já está instalado e oferecerá as opções:
1. **Manutenção:** Alterar URL/Chave do Supabase, API Key do Asaas, trocar o subdomínio (reconfigura Nginx e SSL) ou ver o diagnóstico.
2. **Atualizar Código:** Faz um `git pull` e gera um novo build automaticamente.
3. **Atualizar Supabase:** Publica automaticamente as Edge Functions e aplica o SQL do banco usando suas credenciais já salvas (requer um Access Token do Supabase, gerado em https://supabase.com/dashboard/account/tokens).
4. **Reinstalação:** Remove e instala tudo do zero.
5. **Diagnóstico da instalação:** Mostra pasta do app, pasta web, remote git, commit/branch atual, domínio do Nginx, presença do `.env`, data do último build e status do Nginx/Node.

---

## 🔎 Detecção de instalações existentes e migração de caminho

O instalador faz uma varredura antes de exibir o menu, então ele reconhece instalações antigas mesmo depois da troca do repositório:

- Caminhos conhecidos, nesta ordem: `/opt/bivvo-pagamento`, `/opt/project-lovebug-launch`, `/opt/bivvo`.
- Varredura de `/opt/*` e `/var/www/*` procurando pastas com `package.json` + `new_deploy/`, ou um `.git` cujo `origin` aponte para o repositório antigo ou o novo.
- Arquivos `.env` contendo `VITE_SUPABASE_URL`.
- Configuração do Nginx em `/etc/nginx/sites-available/bivvo` (de onde extrai o domínio e o `root` real, usado como pasta web).
- Site publicado em `/var/www/bivvo`.

Se o site/Nginx existirem mas o código-fonte não for encontrado, o script informa **instalação parcial** e oferece reinstalar apenas o código-fonte, preservando o domínio.

**Migração do caminho antigo:** quando a instalação for encontrada fora de `/opt/project-lovebug-launch`, o script mostra o que achou (pasta, domínio, remote) e oferece:

1. **Migrar** para `/opt/project-lovebug-launch`, preservando `.env` e `supabase-secrets.env`, corrigindo o `git remote` e recarregando o Nginx.
2. **Continuar** no caminho atual (apenas corrige o `git remote` para o repositório novo).
3. **Reinstalação completa.**

Se o `origin` ainda apontar para o repositório antigo, ele é corrigido automaticamente antes do `git pull`. Caso o `pull` falhe por histórico divergente, o script explica o motivo e oferece um `fetch + reset --hard origin/main` (o `.env` é preservado).





---

## 🔧 Alternativa: Edge Functions via CLI (mais rápido)

Se preferir publicar as funções de uma vez pelo terminal (exige Docker):

```bash
cd /opt/project-lovebug-launch
# Siga as instruções para logar e linkar o projeto
npx supabase login
npx supabase link --project-ref SEU_PROJECT_ID
npx supabase functions deploy --no-verify-jwt
```

---

## 🗄️ Atualização de Schema e Migrations via CLI

Para atualizar o banco de dados (schema base + migrations incrementais) direto pelo terminal da VPS:

```bash
cd /opt/project-lovebug-launch

# Siga as instruções para logar e linkar o projeto
npx supabase login
npx supabase link --project-ref SEU_PROJECT_ID

# Publica todas as Edge Functions
npx supabase functions deploy --no-verify-jwt
```

Em seguida, aplique o SQL do banco (schema + migrations) usando `psql` (a `SUPABASE_DB_URL` fica no `.env` do projeto). A URL precisa ser a **connection string do banco**, começando com `postgresql://` ou `postgres://` — não use a URL pública da API nem a chave anon:

```bash
# Schema base (apenas para instalação nova; é idempotente)
psql --dbname="$SUPABASE_DB_URL" -f new_deploy/database_schema.sql

# Migrations incrementais em ordem
psql --dbname="$SUPABASE_DB_URL" -f new_deploy/migrations/003_new_features.sql
psql --dbname="$SUPABASE_DB_URL" -f new_deploy/migrations/004_security_and_settings.sql
psql --dbname="$SUPABASE_DB_URL" -f new_deploy/migrations/005_task_enhancements.sql
psql --dbname="$SUPABASE_DB_URL" -f new_deploy/migrations/006_finance_metrics.sql
```

Se aparecer erro tentando conectar no socket local `/var/run/postgresql/.s.PGSQL.5432`, a `SUPABASE_DB_URL` foi colada/salva em formato incorreto. Apague a linha `SUPABASE_DB_URL=` do arquivo `/opt/project-lovebug-launch/.env` e execute o instalador novamente, colando somente a connection string completa do banco.

> 💡 O opção **3 do `auto_install.sh` (Atualizar Supabase)** faz todos esses passos automaticamente (login + link + deploy + schema + migrations).



---

## 🔍 Resolução de problemas (Troubleshooting)

### Erro: "non-2xx status code" ou "Module not found"
Se ao tentar assinar aparecer o erro **non-2xx status code**:
1. Verifique se você cadastrou o **ASAAS_API_KEY** e o **ASAAS_BASE_URL** corretamente em **Edge Functions → Secrets** no painel do Supabase.
2. Certifique-se de que a URL no Asaas está correta (Produção vs Sandbox).
3. Se você copiou o código manualmente, certifique-se de que copiou o código da pasta `new_deploy/functions/`, pois eles são adaptados para funcionar sem arquivos externos.
4. Verifique os logs em **Edge Functions → [Nome da Função] → Logs** para ver o erro exato retornado pela API do Asaas.


---

✅ **Concluído!** Seu Bivvo está no ar.