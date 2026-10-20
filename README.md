# Carro na Mão

**Gastos, consumo e lembretes em um só lugar.**

App mobile (iOS + Android) em Flutter para o usuário comum gerir custos de veículos. Offline-first, sem login, sem monetização na V1.

## Stack

- **Flutter** (gerenciado por FVM — veja `.fvmrc`)
- **drift** — persistência local SQLite type-safe
- **riverpod** — gerenciamento de estado
- **go_router** — navegação
- **flutter_local_notifications** — lembretes
- **share_plus** — export CSV

## Rodando o projeto

```bash
fvm install
fvm flutter pub get
fvm flutter run
```

## Mínimos

- iOS 13+
- Android 7 (API 24)+

## Documentação

- [Documento de requisitos V1](https://claude.ai/code/artifact/62b88c1f-8df8-46f0-ba76-1824e5853abe)
- [Board de tasks](https://github.com/users/lucasengecomp/projects/1)

## Privacidade

O aplicativo não coleta nenhum dado pessoal. Nenhuma informação sai do
dispositivo do usuário.

- Documento: [`docs/privacidade/politica-de-privacidade.md`](docs/privacidade/politica-de-privacidade.md)
- URL pública (GitHub Pages): `https://lucasengecomp.github.io/carr0-na-mao/privacidade/`

**Para ativar o GitHub Pages** (passo manual, requer permissão de admin):

1. Acesse **Settings > Pages** no repositório.
2. Em **Source**, selecione **Deploy from a branch**.
3. Escolha a branch `main` e a pasta **`/docs`**.
4. Salve. O site ficará disponível em
   `https://lucasengecomp.github.io/carr0-na-mao/`.

## Base de marcas e modelos

A lista curada vive em `assets/data/marcas_modelos.json` e é 100% offline
(nenhum consumo de API). No boot do app o conteúdo é lido via `rootBundle` e
inserido nas tabelas `marcas`/`modelos` com `INSERT OR IGNORE`, então rodar
várias vezes é idempotente e dados que o usuário adicionou livremente ficam
preservados.

Para atualizar:

1. Edite `assets/data/marcas_modelos.json` adicionando/alterando marcas e
   modelos. Incremente `assetsVersion` por disciplina (hoje não dispara
   nenhum comportamento diferente, mas serve de pista para reseed futuro).
2. Rode `fvm flutter test` para garantir que o seed e os queries continuam
   verdes.
3. Novos itens aparecem automaticamente no form de veículo após o próximo
   boot do app.
