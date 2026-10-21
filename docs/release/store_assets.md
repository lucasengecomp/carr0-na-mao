# Checklist de Assets de Loja — Carro na Mão

Este documento lista o que ainda precisa ser produzido manualmente antes de
publicar o app na App Store e no Google Play.

## Assets de ícone e splash

- [ ] `assets/icon/icon.png` — ícone master, 1024x1024 px, PNG sem transparência
- [ ] `assets/icon/icon_foreground.png` — camada de frente do ícone adaptativo Android
      (seguir [Material Design adaptive icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive))
- [ ] `assets/splash/splash_logo.png` — logo para a splash screen (tema claro)
- [ ] `assets/splash/splash_logo_dark.png` — logo para a splash screen (tema escuro)

## Screenshots de loja

Mínimo recomendado:

| Tela | iPhone 6.5" | Pixel 7 |
|------|-------------|---------|
| Home / Dashboard | obrigatória | obrigatória |
| Lista de Abastecimentos | obrigatória | obrigatória |
| Formulário de Abastecimento | obrigatória | obrigatória |
| Comparador de Postos | recomendada | recomendada |
| Configurações | recomendada | recomendada |

## Textos de loja

- [ ] Descrição curta (até 80 caracteres) — usada no Google Play
- [ ] Descrição longa — até 4000 caracteres (App Store e Google Play)
- [ ] Palavras-chave (App Store: até 100 chars separados por vírgula)

## Como gerar ícones e splash depois que a arte estiver pronta

1. Coloque os arquivos PNG nos caminhos listados acima.
2. Descomente os blocos `flutter_launcher_icons` e `flutter_native_splash`
   no final do `pubspec.yaml`.
3. Execute:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

4. Confirme que os ícones foram gerados em
   `android/app/src/main/res/mipmap-*/` e
   `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
5. Faça commit dos arquivos gerados junto com os assets originais.

## Nota sobre os blocos comentados no pubspec.yaml

Os blocos de configuração de `flutter_launcher_icons` e `flutter_native_splash`
estão comentados no final do `pubspec.yaml` para não causar erros enquanto os
arquivos de arte não existem. Descomente-os apenas na etapa 2 acima.
