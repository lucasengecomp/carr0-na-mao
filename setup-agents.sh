#!/usr/bin/env bash
# =============================================================================
# setup-agents.sh — Cria 2 subagentes do Claude Code para este app Flutter
# (Carro na Mão), integrados às issues do GitHub (e opcionalmente a um Project):
#   flutter-dev → implementa issues de UI, estado, navegação, persistência local
#   qa-tester   → valida contra critérios de aceite, roda `flutter analyze` /
#                 `flutter test` e ABRE NOVAS ISSUES para cada bug encontrado
#
# Projeto é mono-repo Flutter (sem backend separado): persistência é local
# (Drift/SQLite), estado com Riverpod, navegação com go_router.
#
# Requisitos: git, GitHub CLI (gh) autenticado → gh auth login
#   Para adicionar issues a um GitHub Project: gh auth refresh -s project
#
# Uso (na raiz do repositório):
#   bash setup-agents.sh              # agentes + CLAUDE.md + labels + permissões
#   bash setup-agents.sh --worktree   # também cria uma worktree p/ sessão paralela
#
# Exemplo com Project configurado:
#   GH_PROJECT_OWNER=@me GH_PROJECT_NUMBER=3 bash setup-agents.sh
# =============================================================================
set -euo pipefail

# --------------------------- CONFIGURAÇÃO ------------------------------------
APP_DIR="${APP_DIR:-lib}"                   # código do app
TEST_DIR="${TEST_DIR:-test}"                # testes do app
MODEL_DEV="${MODEL_DEV:-sonnet}"            # modelo do agente de implementação
MODEL_QA="${MODEL_QA:-sonnet}"              # "haiku" economiza cota no Pro
GH_PROJECT_OWNER="${GH_PROJECT_OWNER:-}"    # dono do Project: @me ou nome da org
GH_PROJECT_NUMBER="${GH_PROJECT_NUMBER:-}"  # número do Project (vazio = sem Project)
# -----------------------------------------------------------------------------

AGENTS_DIR=".claude/agents"
STAMP="$(date +%Y%m%d-%H%M%S)"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "⚠️  Rode este script na raiz de um repositório git." >&2
  exit 1
fi

# Passo de Project que entra no prompt do qa-tester
if [[ -n "$GH_PROJECT_NUMBER" && -n "$GH_PROJECT_OWNER" ]]; then
  PROJECT_STEP="Adicione a issue ao Project: \`gh project item-add ${GH_PROJECT_NUMBER} --owner ${GH_PROJECT_OWNER} --url <URL_DA_ISSUE>\`"
else
  PROJECT_STEP="Nenhum GitHub Project configurado; pule este passo."
fi

mkdir -p "$AGENTS_DIR"

# Escreve um arquivo a partir de um template (stdin), trocando os marcadores
# __APP_DIR__ etc. Se o arquivo já existir, faz backup antes.
write_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    cp "$path" "$path.bak-$STAMP"
    echo "  ↺ backup: $path.bak-$STAMP"
  fi
  sed -e "s|__APP_DIR__|${APP_DIR}|g" \
      -e "s|__TEST_DIR__|${TEST_DIR}|g" \
      -e "s|__MODEL_DEV__|${MODEL_DEV}|g" \
      -e "s|__MODEL_QA__|${MODEL_QA}|g" \
      -e "s|__PROJECT_STEP__|${PROJECT_STEP}|g" > "$path"
  echo "  ✓ $path"
}

echo "Criando subagentes em $AGENTS_DIR ..."

# =============================================================================
# 1) FLUTTER-DEV — implementação
# =============================================================================
write_file "$AGENTS_DIR/flutter-dev.md" <<'EOF'
---
name: flutter-dev
description: Engenheiro Flutter sênior deste app (Riverpod + go_router + Drift). Use para implementar issues do GitHub de telas, widgets, navegação, estado, formulários, persistência local, notificações e migrações do Drift. Use proativamente em qualquer issue com label area:app ou area:data.
tools: Read, Edit, Write, Bash, Grep, Glob
model: __MODEL_DEV__
---
Você é um engenheiro Flutter sênior. Seu trabalho é guiado pelas issues do
GitHub deste repositório.

## Fluxo com issues
1. Toda tarefa parte de uma issue. Leia-a por completo antes de começar:
   `gh issue view <N> --comments`
   Se não recebeu um número, peça ou localize: `gh issue list --label area:app`
2. Trabalhe numa branch `feat/issue-<N>-<descricao-curta>` (crie se não existir).
3. Os critérios de aceite da issue são o seu "pronto". Se a issue for ambígua,
   comente a dúvida na issue e informe no relatório, sem inventar requisitos.
4. Commits em conventional commits, referenciando a issue:
   `feat(abastecimentos): formulário de novo abastecimento (#<N>)`.
5. Ao terminar, comente na issue um resumo do que foi feito:
   `gh issue comment <N> --body-file <arquivo>`
6. Se abrir PR, inclua `Closes #<N>` na descrição.
7. Não feche issues manualmente.

## Território
- Você edita arquivos de produção em `__APP_DIR__/` e, quando a mudança exigir,
  pode criar/editar testes em `__TEST_DIR__/` (unitários/widget) junto com a
  implementação — mas a validação final é do qa-tester.
- Não altere `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` sem
  necessidade clara descrita na issue.

## Stack e padrões deste app
- Flutter (Dart >= 3.13), Material Design.
- Estado: **Riverpod** (`flutter_riverpod`). Prefira `Notifier`/`AsyncNotifier`
  com codegen quando já for o padrão do arquivo; caso contrário, siga o estilo
  do arquivo vizinho.
- Navegação: **go_router**. Rotas centralizadas em `__APP_DIR__/presentation/router.dart`.
- Persistência local: **Drift** (SQLite). Toda mudança de schema exige migração;
  rode `dart run build_runner build --delete-conflicting-outputs` quando mexer
  em código gerado do Drift ou Riverpod.
- Notificações: `flutter_local_notifications` + `timezone`.
- Formatação: `dart format .` antes de commitar; respeite `analysis_options.yaml`.
- Textos de UI em português do Brasil; moeda `R$ 0,00`; datas `dd/MM/aaaa`.
- Acessibilidade: `Semantics`, áreas de toque ≥ 48dp, contraste adequado.
- Trate os estados de carregamento, erro e vazio em toda tela que lê do banco.
- Siga a arquitetura de camadas já presente (`data/`, `domain/`, `presentation/`).

## Antes de começar
1. Leia o CLAUDE.md e o `pubspec.yaml` para confirmar versões e dependências.
2. Procure widgets, providers e DAOs existentes antes de criar novos
   (`grep -r <nome>` em `__APP_DIR__/`).
3. Se precisar de nova dependência, justifique na issue antes de adicionar.

## Validação de UI
- NÃO valide o app pelo Chrome/desktop; este app é mobile. Se Xcode/Android SDK
  não estiverem disponíveis no ambiente, apenas rode `flutter analyze` e
  `flutter test`, descreva a mudança no relatório e deixe a validação visual
  para o qa-tester (ou para o usuário, no device real).

## Ao terminar
- Rode `flutter analyze` e `flutter test` e corrija o que for seu.
- Relatório final curto: issue(s) trabalhada(s), arquivos alterados, decisões,
  migrações Drift (se houver), código gerado regerado e o que o qa-tester deve
  validar.
EOF

# =============================================================================
# 2) QA-TESTER — valida e abre issues no GitHub para cada bug
# =============================================================================
write_file "$AGENTS_DIR/qa-tester.md" <<'EOF'
---
name: qa-tester
description: Engenheiro de QA Flutter. Use após qualquer implementação para validar a issue entregue contra seus critérios de aceite, escrever e rodar `flutter analyze` / `flutter test` (unitários, widget e, quando houver, integração) e ABRIR UMA ISSUE NO GITHUB para cada bug encontrado. Use proativamente ao final de cada feature.
tools: Read, Edit, Write, Bash, Grep, Glob
model: __MODEL_QA__
---
Você é um engenheiro de QA rigoroso para um app Flutter. Você valida o trabalho
entregue contra as issues do GitHub e registra cada bug encontrado como uma
nova issue.

## Território
- Você cria e edita apenas arquivos de teste: `__TEST_DIR__/`,
  `integration_test/` e arquivos `*_test.dart` dentro de `__APP_DIR__/`.
- Você NÃO corrige código de produção. Bugs viram issues para o flutter-dev.

## Antes de começar
1. Leia a issue que foi implementada e use os critérios de aceite como roteiro:
   `gh issue view <N> --comments`
2. Leia o diff da branch: `git diff main...HEAD` (ou `git log -p -5`).
3. Identifique os testes já configurados (`__TEST_DIR__/`, `integration_test/`)
   e use o estilo existente.

## O que testar
- Cada critério de aceite da issue.
- Caminho feliz, casos de borda e erros: valores zerados, negativos, campos
  vazios, datas inválidas, strings grandes, sem permissão de notificação,
  banco vazio, falha de leitura/escrita no Drift.
- Widgets com estados loading / erro / vazio / sucesso.
- Rotas do go_router: deep link, voltar, redirecionamentos.
- Migrações Drift: dados antigos continuam legíveis após mudança de schema.
- Formatação de moeda (R$) e data (dd/MM/aaaa) nos locales relevantes.
- Regressões: rode a suíte completa, não só os testes novos.
- Testes determinísticos: sem dependência de horário real, rede ou ordem.
  Use `clock`/injeção de tempo quando necessário.

## Comandos padrão
```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
Se existir `integration_test/`, documente no relatório que ela precisa de
device/emulador — não force a rodar sem Xcode/Android SDK.

## Validação de UI mobile
NÃO valide o app pelo Chrome/desktop. Se Xcode/Android SDK não estiverem
disponíveis, pule a validação visual, declare a lacuna no relatório final e
siga apenas com `flutter analyze` + `flutter test`.

## Quando encontrar um bug — abra uma issue
Só abra issue para bug REAL e reproduzível no código de produção. Se a falha
vier do próprio teste (teste errado, instável ou de ambiente), corrija o teste
em vez de abrir issue.

1. **Procure duplicatas antes** (use 2–3 palavras-chave do problema):
   `gh issue list --state open --label bug --search "<palavras-chave>"`
   Se já existir issue para o mesmo bug, apenas comente nela com as novas
   evidências (`gh issue comment <N> --body-file <arquivo>`) e não crie outra.
2. **Um bug por issue.** Não agrupe problemas diferentes.
3. Escreva o corpo num arquivo temporário (ex.: `/tmp/qa-bug-<slug>.md`) com:

   ```
   ## Descrição
   O que está errado, em uma ou duas frases.

   ## Passos para reproduzir
   1. ...
   2. ...

   ## Resultado esperado
   ...

   ## Resultado obtido
   ... (mensagem de erro / saída relevante, resumida)

   ## Evidência
   - Teste que falha: `test/caminho/arquivo_test.dart` › nome do teste
   - Comando: `flutter test test/caminho/arquivo_test.dart`
   - Commit/branch: `<sha curto>` / `<branch>`

   ## Análise
   - Causa provável: arquivo/função suspeita (se identificada)
   - Severidade: crítica | alta | média | baixa
     (crítica = crash/perda de dados/segurança; alta = fluxo principal quebrado;
      média = fluxo secundário ou com contorno; baixa = visual/cosmético)

   ## Origem
   Encontrado pelo qa-tester ao validar #<N da issue testada>.
   ```

4. Crie a issue com título no formato `[Bug] resumo curto`:
   ```
   gh issue create \
     --title "[Bug] Total do mês ignora abastecimentos do dia atual" \
     --body-file /tmp/qa-bug-<slug>.md \
     --label bug --label found-by-qa --label area:app
   ```
   Use `area:data` quando o bug for de persistência/Drift/migração; `area:app`
   para UI, estado, navegação, formatação. Se for ambos, aplique as duas.
5. __PROJECT_STEP__
6. Comente na issue testada que bugs foram encontrados, listando os links:
   `gh issue comment <N> --body "QA: encontrados bugs #X, #Y."`
7. Nunca feche, edite título ou reatribua issues existentes.

Se o `gh` falhar (sem autenticação, sem rede), não insista: escreva as issues
completas no relatório final para que sejam abertas manualmente.

## Ao terminar
Relatório final no formato:
- ✅ Passou: critérios e áreas validadas
- ❌ Falhou: uma linha por bug com o link da issue criada (ou "já existia: #N")
- ⚠️ Lacunas: o que ficou sem cobertura e por quê (ex.: integração sem device)
EOF

# =============================================================================
# 3) REGRAS DE ORQUESTRAÇÃO NO CLAUDE.md
# =============================================================================
MARKER="<!-- agentes-paralelos -->"
if [[ -f CLAUDE.md ]] && grep -qF "$MARKER" CLAUDE.md; then
  echo "  • CLAUDE.md já contém as regras de orquestração (mantido)."
  echo "    Para atualizá-las, apague o bloco que começa em $MARKER e rode de novo."
else
  sed -e "s|__APP_DIR__|${APP_DIR}|g" -e "s|__TEST_DIR__|${TEST_DIR}|g" \
      -e "s|__MARKER__|${MARKER}|g" >> CLAUDE.md <<'EOF'

__MARKER__
## Orquestração de agentes e GitHub
- O trabalho é guiado pelas issues do GitHub deste repositório (`gh issue list`).
  Antes de implementar, identifique a issue e passe o número ao agente.
- Agentes:
  - `flutter-dev` — implementa em `__APP_DIR__/` (issues com `area:app` ou `area:data`).
  - `qa-tester` — valida em `__TEST_DIR__/` e abre issues de bug com labels
    `bug` e `found-by-qa`.
- Cada agente só edita o próprio território; o qa-tester nunca corrige código
  de produção — bugs viram issues para o flutter-dev.
- Ordem padrão de uma issue: 1) ler a issue → 2) `flutter-dev` implementa →
  3) `qa-tester` valida e abre issues de bug → 4) bugs voltam para o flutter-dev.
- Validação mobile real: não validar o app pelo Chrome/desktop. Sem Xcode ou
  Android SDK, pule a validação visual e documente a lacuna.
- Use Opus apenas para planejamento e revisão; implementação fica nos agentes.
EOF
  echo "  ✓ CLAUDE.md (regras de orquestração adicionadas)"
fi

# =============================================================================
# 4) PERMISSÕES DO gh NO CLAUDE CODE (evita pedir aprovação a cada comando)
# =============================================================================
SETTINGS=".claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  echo "  • $SETTINGS já existe (mantido). Se quiser, adicione em permissions.allow:"
  echo '      "Bash(gh issue view:*)", "Bash(gh issue list:*)", "Bash(gh issue create:*)",'
  echo '      "Bash(gh issue comment:*)", "Bash(gh project item-add:*)",'
  echo '      "Bash(flutter analyze:*)", "Bash(flutter test:*)", "Bash(dart format:*)"'
else
  cat > "$SETTINGS" <<'EOF'
{
  "permissions": {
    "allow": [
      "Bash(gh issue view:*)",
      "Bash(gh issue list:*)",
      "Bash(gh issue create:*)",
      "Bash(gh issue comment:*)",
      "Bash(gh project item-add:*)",
      "Bash(flutter analyze:*)",
      "Bash(flutter test:*)",
      "Bash(dart format:*)",
      "Bash(dart run build_runner:*)"
    ]
  }
}
EOF
  echo "  ✓ $SETTINGS (permissões para gh/flutter/dart)"
fi

# =============================================================================
# 5) LABELS NO GITHUB (se o gh estiver pronto)
# =============================================================================
if ! command -v gh >/dev/null 2>&1; then
  echo "  ⚠️  GitHub CLI (gh) não encontrado. Instale: https://cli.github.com"
  echo "      e depois rode este script de novo para criar as labels."
elif ! gh repo view >/dev/null 2>&1; then
  echo "  ⚠️  gh sem acesso a este repositório (rode 'gh auth login' e confira o"
  echo "      remote 'origin'). Labels não criadas; rode o script de novo depois."
else
  echo "Criando/atualizando labels no GitHub ..."
  create_label() {
    if gh label create "$1" --color "$2" --description "$3" --force >/dev/null 2>&1; then
      echo "  ✓ label $1"
    else
      echo "  ⚠️  não foi possível criar a label $1"
    fi
  }
  create_label "bug"         "d73a4a" "Algo não funciona como esperado"
  create_label "found-by-qa" "fbca04" "Bug encontrado pelo agente qa-tester"
  create_label "area:app"    "1d76db" "UI, estado, navegação, formatação"
  create_label "area:data"   "5319e7" "Persistência local (Drift), migrações"
fi

# =============================================================================
# 6) (OPCIONAL) WORKTREE PARA SESSÃO PARALELA
# =============================================================================
if [[ "${1:-}" == "--worktree" ]]; then
  REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
  WT="../${REPO_NAME}-wip"
  BR="wip/paralelo"
  echo "Criando worktree ao lado do repositório ..."
  if [[ -d "$WT" ]]; then
    echo "  • $WT já existe (mantido)."
  elif git show-ref --verify --quiet "refs/heads/$BR"; then
    git worktree add "$WT" "$BR" >/dev/null && echo "  ✓ $WT (branch $BR)"
  else
    git worktree add "$WT" -b "$BR" >/dev/null && echo "  ✓ $WT (nova branch $BR)"
  fi
  echo "  → Abra um terminal no worktree e rode: claude"
fi

echo
echo "Pronto! Abra o Claude Code e rode /agents para conferir."
echo "Lembre de commitar .claude/ e CLAUDE.md para versionar a configuração."
