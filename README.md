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
