# Matriz de Eisenhower na aba de Tarefas

## Conceito aplicado ao time

Cada tarefa passa a ter dois atributos independentes:

- **Importância** (impacta resultado/receita/cliente): sim ou não
- **Urgência** (prazo curto, bloqueia alguém, risco imediato): sim ou não

Isso gera 4 quadrantes:

```text
                URGENTE            NÃO URGENTE
IMPORTANTE   Q1 FAZER AGORA      Q2 AGENDAR
             (crise, SLA)        (estratégico, prevenção)

NÃO          Q3 DELEGAR          Q4 ELIMINAR
IMPORTANTE   (interrupções)      (ruído, "quando sobrar")
```

Uso prático combinado ao que já existe hoje:
- **Q1** → prioridade Alta, prazo definido, dono obrigatório.
- **Q2** → onde o time deve gastar a maior parte do tempo; exige data agendada.
- **Q3** → candidata natural ao campo `assigned_to` (delegar) ou ao flag "aguardando terceiro".
- **Q4** → não entra no Kanban ativo; vira backlog/arquivo.

Regra operacional sugerida: se um membro tem mais de 3 tarefas em Q1, o time está em modo apagar incêndio — a reunião semanal olha o gráfico de distribuição e puxa esforço para Q2.

## Mudanças no banco

Nova migration adicionando em `public.tasks`:
- `is_important boolean not null default true`
- `is_urgent boolean not null default false`
- `department text` (financeiro, marketing, comercial, suporte, desenvolvimento, outro)
- coluna gerada/derivada opcional não é necessária — o quadrante é calculado no front.

Backfill a partir da prioridade atual:
- `high` → importante + urgente (Q1)
- `medium` → importante, não urgente (Q2)
- `low` → não importante, não urgente (Q4)

O campo `priority` continua existindo (compatibilidade e ordenação), mas passa a ser **derivado automaticamente** do quadrante ao salvar: Q1=alta, Q2=média, Q3=média, Q4=baixa.

Mesma migration replicada em `new_deploy/migrations/012_eisenhower_matrix.sql` para o servidor externo.

## Mudanças na interface (`AdminTasks.tsx`)

1. **Formulário de tarefa**: dois switches — "Importante" e "Urgente" — com o quadrante resultante exibido em tempo real ("Q1 · Fazer agora"). Substituem a escolha manual de prioridade. Adição de campo Select para **Departamento**.
2. **Nova visão "Matriz"**: terceiro botão ao lado de Kanban e Lista, mostrando uma grade 2x2 com as tarefas em cards, contagem por quadrante e cores próprias por quadrante (vermelho/azul/âmbar/cinza, via tokens do design system).
3. **Arrastar entre quadrantes**: soltar um card em outro quadrante atualiza `is_important`/`is_urgent` (mesmo mecanismo de drag já usado no Kanban).
4. **Badge de quadrante** nos cards do Kanban e na tabela da Lista, ao lado da prioridade.
5. **Filtro por quadrante e departamento** na barra de filtros existente, junto de status/prioridade/responsável.
6. **Ordenação**: dentro de cada coluna do Kanban, ordenar primeiro pela data de vencimento (mais próxima antes, vencidas no topo, sem data por último) e só depois por quadrante (Q1→Q2→Q3→Q4).
7. **Indicador de carga**: pequeno resumo no topo — quantas tarefas em cada quadrante e alerta visual quando Q1 passa de 3 por responsável.

## Fora de escopo

- Automatizar urgência com base na data de vencimento (pode virar uma segunda etapa).
- Relatórios históricos de distribuição por quadrante.

## Ordem de execução

1. Migration no Cloud + backfill.
2. Atualizar tipos e `AdminTasks.tsx` (form, matriz, badges, filtro).
3. Copiar migration para `new_deploy/migrations/` e atualizar `INSTALL.md`.
