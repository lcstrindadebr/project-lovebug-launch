# Detecção robusta de instalação existente no autoinstalador

## Problema

O `auto_install.sh` só considera que existe instalação se a pasta `/opt/project-lovebug-launch` existir. Como o repositório mudou de nome, servidores instalados antes ficam com a pasta antiga (ex.: `/opt/bivvo`, `/opt/lovebug-launch`, ou outro nome de clone) e o script mostra "Nenhuma instalação detectada", oferecendo apenas instalação do zero — o que duplica arquivos e perde o `.env`.

## Solução: varredura de detecção

Adicionar uma função `detect_installation()` executada antes do menu, que procura instalações por vários sinais:

1. Caminhos conhecidos verificados primeiro, nesta ordem: `/opt/bivvo-pagamento` (instalações atuais no servidor), `/opt/project-lovebug-launch`, `/opt/bivvo`.
2. Além desses, diretórios candidatos em `/opt` e `/var/www` (qualquer pasta que contenha `package.json` + a pasta `new_deploy/`, ou um `.git` cuja `origin` aponte para o repositório antigo ou novo).
5. Site publicado: existência de `/var/www/bivvo` com `index.html`.
5. Configuração do Nginx: `/etc/nginx/sites-available/bivvo` (extrai o domínio e o `root` configurado, que revela o `WEB_DIR` real).
5. Arquivos `.env` com `VITE_SUPABASE_URL` dentro dos diretórios candidatos.

Se encontrar algo, o script assume modo manutenção mesmo que o caminho não seja o padrão.

## Migração do caminho antigo

Quando a instalação encontrada estiver em pasta diferente de `/opt/project-lovebug-launch`:

- Exibir o que foi encontrado (pasta, domínio, remote git atual).
- Oferecer: **[1] Migrar** (mover a pasta para o novo caminho, preservar `.env` e `supabase-secrets.env`, atualizar `git remote set-url origin` para o repositório novo, ajustar o `root` do Nginx e recarregar), **[2] Continuar usando o caminho antigo** (apenas atualiza o remote e segue), **[3] Reinstalação completa**.
- Se a pasta existir mas o remote for o antigo, corrigir o remote automaticamente antes do `git pull` (evita erro de pull).

## Ajustes adicionais

- `APP_DIR` e `WEB_DIR` passam a ser variáveis preenchidas pela detecção (com os valores padrão atuais como fallback), em vez de constantes fixas.
- Novo item no menu de manutenção: **"Diagnóstico da instalação"**, mostrando caminho do app, remote git, commit atual, domínio do Nginx, presença do `.env`, status do build em `WEB_DIR` e status do serviço Nginx.
- No `git pull`, tratar o caso de repositório com histórico divergente (mensagem clara em vez de falha silenciosa).
- Atualizar `new_deploy/INSTALL.md` com uma seção sobre migração do caminho antigo para o novo.

## Arquivos alterados

- `new_deploy/auto_install.sh`
- `new_deploy/INSTALL.md`

Nenhuma mudança no banco de dados, nas Edge Functions ou no frontend.
