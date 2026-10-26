# Prompts para geração de assets — Nano Banana (Google)

Prompts prontos para gerar o ícone de launcher, ícones de seção e
ilustrações de empty state do app **Carro na Mão** usando o
**Nano Banana** (modelo `gemini-2.5-flash-image`, disponível no app
Gemini e no Google AI Studio no plano gratuito).

> Dica geral de Nano Banana: ele responde muito bem a instruções em
> linguagem natural e a **edições iterativas** ("agora deixe o fundo
> índigo mais escuro", "mantenha a mesma arte mas troque X por Y"). Não
> precisa de flags estilo Midjourney. Para manter consistência entre
> ícones da mesma família, gere o primeiro, aprove, e peça as próximas
> variações **referenciando a arte anterior** no mesmo chat.

---

## Resumo do projeto (contexto para colar antes dos prompts, se quiser)

App mobile (iOS + Android, Flutter) chamado **Carro na Mão**, para o
motorista brasileiro comum gerenciar os custos do próprio veículo:
abastecimentos, manutenções, despesas e lembretes. Offline-first, sem
login, sem publicidade. Tom prático, cotidiano, confiável — **não é**
app esportivo, de entusiasta, de locadora nem de gestão de frota.
Material 3, cor-semente **Índigo** (`#3F51B5`). Idioma pt-BR.

---

## 1) Ícone de launcher (ícone principal do app)

```
App launcher icon for a Brazilian mobile app called "Carro na Mão"
(a personal car-cost tracker for everyday drivers, not for enthusiasts
or fleets). The app helps regular people track fuel, maintenance,
expenses and reminders for their own car, offline, no login, no ads.

Style: flat vector, modern, friendly, Material You / Material 3
aesthetic. Clean geometric shapes, subtle depth via soft long shadow,
no gradients that look 3D-rendery, no skeuomorphism, no racing / sports
car vibes, no corporate-fleet look.

Concept: a stylized abstract mark combining a car silhouette (compact
hatch/sedan from the front-3/4 or just the roof-line) with a hint of
a steering wheel OR an open palm "holding" the car — chosen to evoke
the Portuguese expression "ter o carro na mão" (having the car under
control, in the palm of your hand). Keep it minimal and iconic, not
illustrative. Must read clearly at 48px.

Color palette: Material 3 seed INDIGO (#3F51B5 / Indigo 500) as the
primary, with a lighter indigo (#9FA8DA, Indigo 200) accent and off-
white (#F7F7FB) negative space. One single warm accent allowed
(amber #FFC107) only if it adds a highlight — otherwise drop it.
Avoid green=money cliché.

Background: solid rounded square (Android adaptive icon safe zone,
66% content area), full-bleed, no transparency. Also produce a
variant with a flat colored background (Indigo 500) and a white/light
foreground mark for iOS.

Output: 1024x1024, no text, no letters, no watermark, centered,
symmetrical, high contrast, works on both light and dark system
backgrounds.
```

### Variação monograma "CM" (favicon / splash)

```
Minimal monogram logo "CM" for the app "Carro na Mão". Rounded
geometric sans-serif, the "C" subtly shaped like a car silhouette or
a steering-wheel arc wrapping the "M". Flat vector, Indigo 500 on
off-white, no gradient, no shadow. 1024x1024, centered, no extra text.
```

### Follow-ups úteis depois de gerar o launcher

Depois da primeira geração, use edições iterativas no mesmo chat:

- `Keep the exact same mark but output only the foreground, centered on a transparent background, 1024x1024 — this will be the Android adaptive icon foreground layer.`
- `Now output only the background: a flat solid Indigo 500 square, 1024x1024, no mark — this will be the Android adaptive icon background layer.`
- `Produce the iOS version: same mark on a solid Indigo 500 background, full-bleed, no transparency, no rounded corners (iOS applies them), 1024x1024.`
- `Make a dark-mode friendly variant: swap the background to near-black (#121212) and the mark to Indigo 200.`

---

## 2) Conjunto de ícones de seção (navbar + telas)

Para a navbar/telas, considere fortemente **usar os Material Symbols
padrão** (o app já faz isso) — eles são grátis, consistentes e com
versão "selected". Se mesmo assim quiser um set autoral, use o
**prompt-base** abaixo e troque apenas o bloco `SUBJECT`.

### Prompt-base (reutilize, mudando só `SUBJECT`)

```
Create a single flat vector icon in a cohesive set for a Material 3
mobile app ("Carro na Mão", Brazilian personal car-cost tracker).

Style rules (identical across the whole set):
- 2px uniform stroke, rounded line caps and joins, outlined style
  (not filled), small filled accents allowed for emphasis
- 24x24 grid, 2px safe padding, pixel-aligned
- Monochrome Indigo 500 (#3F51B5) on transparent background
- Also output a "selected" variant: same shape, filled, Indigo 700
- Friendly, geometric, slightly rounded corners, no gradients, no
  shadows, no 3D, no isometric perspective
- Must sit visually consistent with Material Symbols Rounded

SUBJECT: <trocar aqui>

Output: transparent PNG 512x512, centered, no text, no label.
```

### `SUBJECT` por tela

- **Início / Dashboard** —
  `a simple car dashboard gauge or 4-cell grid card with a tiny car silhouette inside the top-left cell`
- **Abastecimentos** —
  `a fuel pump nozzle with a small drop, clean and minimal (avoid any brand logos)`
- **Manutenções** —
  `a crossed open-end wrench and screwdriver, or a single wrench over a gear, mechanic-friendly but not greasy`
- **Despesas** —
  `a folded paper receipt with a zig-zag bottom edge and three short lines, with a small "R$" symbol as accent`
- **Lembretes** —
  `a bell with a tiny calendar page or a small car silhouette at its base`
- **Veículos** —
  `a compact hatchback car in side view, friendly proportions, no sports styling`
- **Comparador** —
  `two small cars (or two bar-chart bars) side by side with a vs. divider in the middle`

### Dica de consistência no Nano Banana

Gere o primeiro ícone (ex.: Abastecimentos). Quando estiver bom, peça
os próximos **no mesmo chat** assim:

```
Using the exact same visual style, stroke weight, color, corner radius
and grid as the previous icon, generate the next one in the set:
SUBJECT: <novo subject>
```

Isso aproveita o contexto visual do chat e produz um set mais
coerente do que gerar cada ícone isolado.

---

## 3) Ilustrações de empty state (opcional)

```
Set of 4 friendly empty-state illustrations for the "Carro na Mão"
mobile app. Flat vector, 2-color palette (Indigo 500 + Indigo 100)
with a single warm accent (amber #FFC107 used sparingly). Soft rounded
shapes, no faces, no text, generous negative space, square 1024x1024
transparent background. Brazilian everyday context, popular hatch /
sedan body types, no sports cars, no luxury cars.

Scenes:
1. "Nenhum veículo cadastrado" — a small hatch parked with a key
   floating above it.
2. "Sem abastecimentos" — a fuel pump next to a tiny empty list / card.
3. "Sem manutenções" — a wrench and a gear with a calendar page.
4. "Sem lembretes" — a bell next to a sleeping car (zzz above it,
   stylized, not childish).

Keep the four illustrations visually consistent as a family:
same stroke weight, same color ratios, same character of curves.
```

---

## 4) Checklist antes de exportar para o app

- [ ] Launcher legível a **48px** (teste reduzindo a imagem).
- [ ] Launcher **sem texto** / sem letras (regra da App Store e boa
      prática no Android).
- [ ] Versão iOS: **sem transparência**, sem cantos arredondados
      aplicados (o SO aplica).
- [ ] Versão Android: foreground + background separados para
      **adaptive icon** (safe zone central de 66%).
- [ ] Testar como fica em fundo **claro** e **escuro** do sistema.
- [ ] Exportar em **1024×1024 PNG** no mínimo; se o modelo exportar
      SVG, melhor ainda para a navbar.
- [ ] Nenhum logo de marca real (Petrobras, Shell, Michelin, etc.) nos
      ícones — alguns modelos tendem a inserir sozinhos.

---

## 5) Como abrir no app Gemini / Google AI Studio

- **App Gemini (celular ou web)**: cole o prompt no chat. Nano Banana
  é o modelo padrão de imagem agora; não precisa escolher. Para
  edições, continue no mesmo chat com instruções em linguagem natural.
- **Google AI Studio** (`aistudio.google.com`): escolha o modelo
  `gemini-2.5-flash-image` e cole o prompt. Permite múltiplas
  variações numa mesma sessão e exporta direto em PNG.
- Plano gratuito tem limite diário de gerações — gere o launcher
  primeiro, aprove, depois parta para os ícones de seção.

---

## 6) Pacote V1 Android — assets exatos pro release

Produção dos 4 PNGs que a issue #132 (release V1 Android) exige:

| Arquivo | Dimensão | Fundo | Observação |
|---|---|---|---|
| `assets/icon/icon.png` | 1024×1024 | sólido Indigo 500, full bleed | ícone principal — iOS/Android, sem transparência, sem cantos arredondados |
| `assets/icon/icon_foreground.png` | 1024×1024 | transparente | foreground do adaptive icon Android; mark no safe zone central ~66% |
| `assets/splash/splash_logo.png` | 1152×1152 | transparente | splash tema claro |
| `assets/splash/splash_logo_dark.png` | 1152×1152 | transparente | splash tema escuro (item P1 da #132) |

Antes de salvar: `file arquivo.png` deve retornar `PNG image data`, não `JPEG`. Verifique também que o foreground e os splash logos tem alpha real (não branco sólido).

### 6.1) Nano Banana (Gemini) — fluxo iterativo

Rode no **mesmo chat** e nesta ordem. O modelo mantém o estilo visual entre os prompts via contexto da conversa.

#### Prompt 1 — `icon.png`

```
App launcher icon for a Brazilian mobile app called "Carro na Mão" —
a personal car-cost tracker for everyday Brazilian drivers (not for
enthusiasts, racing, or corporate fleets). The app tracks fuel,
maintenance, expenses, and reminders for the user's own car. Tone:
practical, everyday, trustworthy.

Concept: a stylized abstract mark combining a compact hatchback
silhouette (front-3/4 view or just the roof-line) with a hint of an
open palm "holding" the car, evoking the Portuguese expression "ter
o carro na mão" (having your car under control). Keep it iconic and
minimal, not illustrative. Must read clearly at 48px.

Style: flat vector, Material 3 / Material You aesthetic, clean
geometric shapes, friendly, slightly rounded corners. No gradients
that look 3D, no skeuomorphism, no sports-car vibes, no corporate
look. One subtle long shadow for depth is allowed.

Color palette:
- Primary: Material Indigo 500 (#3F51B5)
- Accent: Indigo 200 (#9FA8DA)
- Negative space: off-white (#F7F7FB)
- Avoid green=money cliché, no amber unless strictly needed.

Background: solid Indigo 500 full-bleed square, NO transparency, NO
rounded corners (the OS applies them), NO text, NO letters, NO
watermark.

Output: 1024x1024 PNG, centered, symmetrical, high contrast,
readable on both light and dark system backgrounds. The mark should
occupy roughly 66% of the canvas (Android adaptive safe zone).
```

#### Prompt 2 — `icon_foreground.png`

```
Keep the exact same mark from the previous icon, but output only the
foreground layer:
- Centered on a fully transparent background (RGBA, alpha 0 outside
  the mark).
- The mark must sit inside the central safe area of ~66% of the
  canvas (Android cuts the outer area for different launcher mask
  shapes — circle, squircle, teardrop).
- Same colors, same stroke, same proportions.
- No background shape, no square, no fill behind the mark.

Output: 1024x1024 PNG with transparency.
```

#### Prompt 3 — `splash_logo.png`

```
Keep the same visual identity from the previous icon, but produce a
splash screen logo:
- Only the mark, no background square, fully transparent canvas.
- The mark should be larger than in the icon foreground — target the
  central ~75% of the canvas, since the splash sits over the Android
  system splash which already provides the background color.
- Primary color: Indigo 500 (#3F51B5), as in the icon. Keep the same
  accent and proportions.
- Dark mode: not applicable here (will be generated separately).

Output: 1152x1152 PNG with transparency, centered, pixel-perfect
edges.
```

#### Prompt 4 — `splash_logo_dark.png`

```
Produce a dark-mode variant of the previous splash logo:
- Same mark, same proportions, transparent canvas.
- Swap the primary color to a lighter indigo that reads clearly on
  dark backgrounds: Indigo 200 (#9FA8DA) as the main fill.
- Any inner accents or lines that were dark should become off-white
  (#F7F7FB).
- Shape, size, and composition stay identical to the light version
  so the splash feels like the same brand in dark mode.

Output: 1152x1152 PNG with transparency, centered.
```

---

### 6.2) ChatGPT Free (GPT-4o / DALL·E 3) — prompts standalone

O free tier do ChatGPT **não mantém referência visual confiável entre gerações** no mesmo chat (ao contrário do Nano Banana). Por isso cada prompt abaixo é **completo e autossuficiente** — repete todo o briefing de estilo e conceito. Gere cada um numa conversa separada ou nova.

Limitações a observar:
- DALL·E 3 **não produz transparência real** com fidelidade — o fundo "transparente" pode sair cinza claro ou branco. Para os assets 2, 3 e 4 (que precisam de alpha), **você provavelmente vai precisar remover o fundo manualmente** depois (Photopea, remove.bg, ou Preview do macOS → "Instant Alpha").
- Peça sempre explicitamente "flat vector, no photorealism, no 3D rendering" — DALL·E tende ao foto.
- O output padrão é 1024×1024. Pra 1152×1152 (splash) ou upscale, faça redimensionamento depois num editor; ou aceite 1024×1024 (o `flutter_native_splash` reescalona).

#### Prompt 1 — `icon.png`

```
Create a flat vector app launcher icon for a Brazilian mobile app
called "Carro na Mão" (a personal car-cost tracker for everyday
Brazilian drivers — not racing, not corporate fleet, not luxury).
The app tracks fuel, maintenance, expenses, and reminders for the
user's own car. The tone is practical, everyday, trustworthy.

CONCEPT (what to draw): a stylized abstract mark combining a compact
hatchback silhouette (seen from a 3/4 front angle or just a roof
line) with a hint of an open palm "holding" the car. This evokes the
Portuguese expression "ter o carro na mão" (having your car under
control). Keep it iconic and minimal, like a logo, not an
illustration. The mark must still be legible at 48 pixels.

STYLE RULES (strict):
- Flat vector style, Material 3 / Material You design language
- Clean geometric shapes with slightly rounded corners
- Friendly, approachable, modern
- NO 3D rendering, NO photorealism, NO skeuomorphism
- NO gradient banding that looks like a 3D-rendered sphere
- NO sports car styling, NO motorsport feel, NO corporate fleet look
- NO people, NO text, NO letters, NO numbers, NO brand logos
- One subtle long drop shadow for depth is allowed

COLOR PALETTE (use only these):
- Primary: Material Indigo 500 (hex #3F51B5)
- Secondary accent: Indigo 200 (hex #9FA8DA)
- Negative space / highlights: off-white (hex #F7F7FB)
- No greens (avoid the "money" cliché), no ambers unless strictly
  needed as a tiny highlight

BACKGROUND: a solid Indigo 500 (#3F51B5) full-bleed square. The
background must be fully opaque — NO transparency, NO rounded
corners (the operating system applies them), NO frame or border.

COMPOSITION: the main mark occupies roughly the central 66% of the
canvas (this is the Android adaptive icon safe zone). Centered,
symmetrical, high contrast against the indigo background.

OUTPUT: a single 1024x1024 square image, flat vector aesthetic,
suitable to be read on both light and dark system backgrounds.
```

#### Prompt 2 — `icon_foreground.png`

```
Create a flat vector logomark for a Brazilian mobile app called
"Carro na Mão" (personal car-cost tracker for everyday Brazilian
drivers). This image will become the FOREGROUND layer of the
Android adaptive icon — so the mark must sit alone, with NO
background shape and NO colored square behind it.

CONCEPT: a stylized abstract mark combining a compact hatchback
silhouette (3/4 front angle or roof-line) with a hint of an open
palm "holding" the car. Minimal, logo-style, not illustrative.
Legible at 48px.

STYLE: flat vector, Material 3 aesthetic, clean geometric shapes,
slightly rounded corners, friendly tone. NO 3D rendering, NO
photorealism, NO skeuomorphism, NO gradient 3D sphere look, NO
sports/racing styling, NO corporate feel, NO people, NO text, NO
letters.

COLORS (strict): Primary Indigo 500 (#3F51B5), secondary Indigo 200
(#9FA8DA), highlights off-white (#F7F7FB). Avoid greens and ambers.

BACKGROUND: PURE TRANSPARENT. The canvas outside the mark must be
empty (RGBA alpha = 0). NO colored square, NO frame, NO fill behind
the mark. If the tool cannot output true transparency, use a plain
pure-white (#FFFFFF) background that will be removed later.

COMPOSITION: the mark must fit entirely within the central 66% of
the canvas, leaving a generous outer margin — this is the Android
adaptive icon safe zone. Centered, symmetrical.

OUTPUT: 1024x1024 PNG, flat vector style.
```

#### Prompt 3 — `splash_logo.png`

```
Create a flat vector splash-screen logo for a Brazilian mobile app
called "Carro na Mão" (personal car-cost tracker for everyday
Brazilian drivers — practical, everyday tone, not sporty, not
corporate).

CONCEPT: a stylized abstract mark combining a compact hatchback
silhouette (3/4 front angle or roof-line) with a hint of an open
palm "holding" the car. Minimal, logo-style, not illustrative.
Should feel like the same brand as the app icon.

STYLE: flat vector, Material 3 aesthetic, clean geometric shapes,
slightly rounded corners. NO 3D rendering, NO photorealism, NO
skeuomorphism, NO gradient 3D look, NO sports styling, NO
corporate feel, NO people, NO text, NO letters.

COLORS (strict): Primary Indigo 500 (#3F51B5), secondary Indigo 200
(#9FA8DA), highlights off-white (#F7F7FB). This is the LIGHT theme
variant — primary stays indigo.

BACKGROUND: PURE TRANSPARENT. The splash screen draws this logo on
top of a background color managed by the OS, so there must be no
colored square, no frame, no fill behind the mark. If the tool
cannot output true transparency, use pure-white (#FFFFFF) that will
be removed later.

COMPOSITION: the mark occupies roughly the central 75% of the
canvas (larger than the adaptive icon safe zone, since the splash
has its own layout). Centered, pixel-perfect edges.

OUTPUT: 1024x1024 PNG, flat vector style. (The splash tool will
rescale as needed; 1024 is fine.)
```

#### Prompt 4 — `splash_logo_dark.png`

```
Create a dark-mode variant of a flat vector splash-screen logo for
a Brazilian mobile app called "Carro na Mão" (personal car-cost
tracker). This version will be displayed over a DARK background by
the OS, so colors must be adjusted for legibility on dark surfaces.

CONCEPT (same as the light version): a stylized abstract mark
combining a compact hatchback silhouette (3/4 front angle or
roof-line) with a hint of an open palm "holding" the car. Minimal,
logo-style, not illustrative. Must feel like the exact same brand
mark as the light variant, only recolored.

STYLE: flat vector, Material 3 aesthetic, clean geometric shapes,
slightly rounded corners. NO 3D rendering, NO photorealism, NO
skeuomorphism, NO people, NO text, NO letters, NO numbers.

COLORS (strict — DARK mode palette):
- Primary (main fill): Indigo 200 (hex #9FA8DA) — lighter indigo
  that reads clearly on dark backgrounds
- Secondary highlights / inner accents: off-white (#F7F7FB)
- Do NOT use the regular Indigo 500 as primary here (it goes dark
  on dark)

BACKGROUND: PURE TRANSPARENT (no colored square, no frame). If true
transparency not possible, use pure-black (#000000) for easy later
removal.

COMPOSITION: identical to the light variant — centered, roughly
75% of the canvas, pixel-perfect edges.

OUTPUT: 1024x1024 PNG, flat vector style.
```

### 6.3) Pós-processamento (ambas as rotas)

Depois de gerar os 4 arquivos, antes de passar pro agente:

1. **Confirme formato real:**
   ```bash
   file assets/icon/*.png assets/splash/*.png
   # Esperado: "PNG image data, 1024 x 1024" (ou 1152 pros splashes)
   # Se aparecer "JPEG image data" — não é PNG real, re-exporte.
   ```

2. **Remova fundo branco** (só se o modelo não entregou transparência real nos arquivos 2, 3, 4):
   - macOS Preview: abrir → ferramenta "Instant Alpha" → clicar no branco → Delete → salvar como PNG.
   - remove.bg (gratuito, upload do PNG → baixa com alpha).
   - Photopea.com (grátis, no browser, mesma UI do Photoshop).

3. **Verifique transparência de fato:**
   ```bash
   # Checa se o canal alpha varia (0 = transparente, 255 = opaco):
   sips -g pixelWidth -g pixelHeight -g hasAlpha assets/splash/splash_logo.png
   ```

4. **Confirme dimensões**:
   - icon.png e icon_foreground.png: 1024×1024
   - splash_logo.png e splash_logo_dark.png: 1152×1152 (ou 1024×1024 se o modelo não entregou maior — o `flutter_native_splash` reescalona)

