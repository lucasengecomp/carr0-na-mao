# Assets de Loja — Carro na Mão

## Informações gerais

- **Nome visível:** Carro na Mão
- **Bundle ID (iOS):** com.lucasengecomp.carronamao
- **Application ID (Android):** com.lucasengecomp.carronamao
- **Versão inicial:** 1.0.0 (build 1)

## Descrição curta (Google Play — até 80 caracteres)

> Controle de abastecimentos, manutenções e despesas do seu veículo.

## Descrição longa (App Store e Google Play — até 4000 caracteres)

Carro na Mão é o aplicativo completo para quem quer manter o controle financeiro e de manutenção do seu veículo — tudo offline, sem criar conta, sem anúncios e sem coleta de dados.

**Abastecimentos**
Registre cada abastecimento com data, km, litros, valor e posto. Acompanhe o consumo médio em km/L e o gasto total por período.

**Manutenções**
Cadastre revisões, trocas de óleo, pneus e qualquer serviço realizado. Veja o histórico completo e o custo acumulado de manutenção.

**Despesas**
Anote IPVA, seguro, multas e outras despesas avulsas. Visualize o total gasto com o veículo em qualquer intervalo de tempo.

**Lembretes com notificações**
Configure alertas por data ou por km rodados para não perder a próxima troca de óleo, revisão ou vencimento do seguro. O app avisa quando o prazo estiver próximo.

**Dashboard de gráficos**
Painéis visuais mostram a evolução do consumo, o gasto mensal por categoria e o custo total por veículo, facilitando a tomada de decisão.

**Múltiplos veículos**
Gerencie carro, moto, caminhonete ou qualquer outro veículo cadastrado. Alterne entre eles com um toque.

**Export de dados**
Exporte todo o histórico em XLSX (Excel) ou ZIP com os arquivos separados por categoria — útil para planilhas, imposto de renda ou simplesmente para ter uma cópia.

**Privacidade total**
Zero coleta de dados. Tudo fica armazenado apenas no seu dispositivo. Não há login, nuvem, rastreamento ou publicidade.

---

## Screenshots disponíveis em `docs/release/screenshots/`

| Arquivo | Tela | Uso recomendado |
|---|---|---|
| `inicio_dashboard.png` | Dashboard / Início | 1ª screenshot (obrigatória) |
| `abastecimentos.png` | Lista de abastecimentos | 2ª screenshot (obrigatória) |
| `comparador.png` | Comparador de postos | 3ª screenshot (recomendada) |
| `despesas.png` | Lista de despesas | 4ª screenshot (recomendada) |
| `lembretes.png` | Lista de lembretes | 5ª screenshot (recomendada) |
| `manutencoes.png` | Lista de manutenções | 6ª screenshot (recomendada) |
| `veiculos.png` | Lista de veículos | 7ª screenshot (recomendada) |

> Nota: as screenshots foram capturadas em dispositivo Android. Para App Store,
> é necessário capturar em iPhone 6.5" (1242x2688 px) ou iPhone 6.7" (1290x2796 px).
> As imagens disponíveis servem como referência de conteúdo.

## Palavras-chave (App Store — até 100 chars separados por vírgula)

> carro,abastecimento,gasolina,combustível,manutenção,despesa,km,consumo,lembrete,veículo

## Assets de ícone e splash (gerados automaticamente)

Os arquivos fonte estão em:
- `assets/icon/icon.png` — ícone master 1024x1024 px, sem transparência
- `assets/icon/icon_foreground.png` — camada de frente para adaptive icon Android
- `assets/splash/splash_logo.png` — logo para a splash screen (tema claro)

Os arquivos gerados estão em:
- **Android:** `android/app/src/main/res/mipmap-*/` e `mipmap-anydpi-v26/`
- **iOS:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/` e `LaunchImage.imageset/`

Para regenerar:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Checklist de publicação

### Google Play
- [ ] Criar conta Google Play Console
- [ ] Criar novo app com bundle ID `com.lucasengecomp.carronamao`
- [ ] Build de release: `flutter build appbundle --release`
- [ ] Upload do `.aab` na faixa de produção
- [ ] Preencher ficha do app com descrição curta e longa acima
- [ ] Fazer upload das screenshots (mínimo 2, máximo 8 por tipo de dispositivo)
- [ ] Preencher classificação de conteúdo (app sem coleta de dados)
- [ ] Política de privacidade — linkar a URL pública: <https://castrolftech.com/carro-na-mao/privacidade/>
- [ ] Enviar para revisão

### App Store
- [ ] Criar registro no App Store Connect
- [ ] Bundle ID `com.lucasengecomp.carronamao` já criado no Developer Portal
- [ ] Build de release: `flutter build ipa --release`
- [ ] Upload via Xcode ou Transporter
- [ ] Preencher ficha com título, subtítulo, descrição longa e palavras-chave acima
- [ ] Fazer upload de screenshots em iPhone 6.5" (obrigatório) e iPad 12.9" (se necessário)
- [ ] Declarar coleta de dados: nenhuma (Privacy Nutrition Label)
- [ ] Política de privacidade — linkar a URL pública: <https://castrolftech.com/carro-na-mao/privacidade/>
- [ ] Enviar para revisão

## Política de privacidade pública

A política está publicada em: <https://castrolftech.com/carro-na-mao/privacidade/>

Fonte: `docs/privacidade/politica-de-privacidade.md`. Qualquer atualização aqui
deve ser replicada em `lucasengecomp.github.io` (`carro-na-mao/privacidade/index.html`)
para manter a página pública em sincronia.

## Nota sobre namespace Android

O `namespace` em `android/app/build.gradle` permanece como `carro_na_mao`
(com underscore) porque o `MainActivity.kt` usa esse pacote. O `applicationId`
(que aparece na loja) já está correto: `com.lucasengecomp.carronamao`.
Renomear o namespace exigiria mover diretórios Kotlin — pode ser feito em issue
separada se necessário.
