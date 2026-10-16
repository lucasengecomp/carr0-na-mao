
<!-- agentes-paralelos -->
## Orquestração de agentes e GitHub
- O trabalho é guiado pelas issues do GitHub deste repositório (`gh issue list`).
  Antes de implementar, identifique a issue e passe o número ao agente.
- Agentes:
  - `flutter-dev` — implementa em `lib/` (issues com `area:app` ou `area:data`).
  - `qa-tester` — valida em `test/` e abre issues de bug com labels
    `bug` e `found-by-qa`.
- Cada agente só edita o próprio território; o qa-tester nunca corrige código
  de produção — bugs viram issues para o flutter-dev.
- Ordem padrão de uma issue: 1) ler a issue → 2) `flutter-dev` implementa →
  3) `qa-tester` valida e abre issues de bug → 4) bugs voltam para o flutter-dev.
- Validação mobile real: não validar o app pelo Chrome/desktop. Sem Xcode ou
  Android SDK, pule a validação visual e documente a lacuna.
- Use Opus apenas para planejamento e revisão; implementação fica nos agentes.
