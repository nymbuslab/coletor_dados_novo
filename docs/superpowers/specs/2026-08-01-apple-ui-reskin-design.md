# Reskin "Apple" do coletor_dados — Design

**Data:** 2026-08-01
**Autor:** sessão de brainstorming
**Escopo:** camada visual (UI) do app. Zero mudança de lógica, rede ou contrato de API.

---

## Objetivo

Repaginar a UI do app aplicando a **linguagem visual** descrita em
`lib/assets/DESIGN-apple.md` (design da Apple.com), **sem** copiar o layout de site de
marketing. Extraímos o sistema de design (cor, tipografia, formas, sombra, espaçamento) e
aplicamos às telas funcionais atuais, preservando a densidade e o fluxo de trabalho de campo.

## Decisões (aprovadas pelo usuário)

1. **Direção:** "cara Apple, usabilidade de app". Extrair tokens; manter layout funcional
   (listas, formulários, scanner). **Não** recriar tiles de tela cheia / hero de 56px.
2. **Tema:** light-dominant. Fundo branco/parchment nas telas de trabalho; near-black
   (`#272729`) apenas em momentos de destaque (Splash, header da Home). Sem modo escuro completo.
3. **Cor por função:** abolida. **Um único matiz de ação — azul** — expresso em três tons
   contextuais do documento (não são cores concorrentes, é o mesmo azul em três funções):
   `#0066cc` (ação em superfície clara), `#0071e3` (anel de foco e borda de selecionado) e
   `#2997ff` (ação/link em superfície escura). As 4 funções (Etiqueta/Consulta/Inventário/Entrada)
   passam a se distinguir por **ícone + título**, não por cor. Nenhum segundo matiz (verde/laranja
   etc.) é usado como ação — success/warning/danger ficam só para estados de sistema.
4. **Fonte:** incluir **Inter** (.ttf, licença SIL OFL) como asset em `assets/fonts/`
   — funciona offline; substituto do SF Pro indicado no próprio documento.
5. **Entrada:** re-skinada junto, mesmo sem botão na Home (não adicionar botão — decisão separada).
6. **Ritmo:** Fase 1 (fundação) primeiro → revisão do usuário → telas uma a uma.

## Guardrail (não-negociável)

Isto é 100% camada visual. **Nenhuma** mudança em:
- endpoints, parâmetros, formato de request ou corpo dos POST (incl. `imei: 7829`);
- lógica de providers/services;
- os 126 testes existentes devem continuar passando sem alteração de asserção de comportamento
  (ajustes só se um teste dependia de uma cor/estrutura visual trocada — documentar se ocorrer).

Validação a cada passo: `flutter analyze` limpo + `flutter test` verde.

---

## Arquitetura da mudança

A camada de design é centralizada em `lib/core/theme/app_theme.dart` (`AppTheme` + `AppColors`).
Mantemos os **nomes semânticos** de `AppColors` (`etiqueta`, `consulta`, `inventario`, `entrada`,
`success`, etc.) para não quebrar os 34 call-sites de uma vez — só mudamos os **valores**. As 4
cores de função passam a apontar todas para Action Blue.

### 1. Tokens de cor (`AppColors`)

| Token | Valor novo | Uso |
|---|---|---|
| `seed` | `#0066CC` | semente do ColorScheme |
| `action` (novo) | `#0066CC` | ação/link em superfície **clara** (botões-pílula, links, ícones) |
| `actionFocus` (novo) | `#0071E3` | anel de **foco** (teclado/a11y) e **borda de selecionado** |
| `actionOnDark` (novo) | `#2997FF` | ação/link em superfície **escura** (Splash, header da Home) |
| `etiqueta` / `consulta` / `inventario` / `entrada` | `#0066CC` (todas) | ícone da função (mesma cor) |
| `ink` (novo) | `#1D1D1F` | texto principal |
| `inkMuted` (novo) | `#7A7A7A` | texto secundário / disabled |
| `surfaceSubtle` | `#F5F5F7` | parchment (superfície alternada) |
| `dark` (novo) | `#272729` | tiles/splash/header escuro |
| `border` | `#E0E0E0` | hairline 1px |
| `divider` (novo) | `#F0F0F0` | divisor suave |
| `success` / `warning` / `danger` | mantidos | **só** estados de sistema, nunca "ação" |

Tokens antigos sem uso após a migração (`navy`, `darkBlue`, `midBlue`, `cyan`, `info` roxo)
serão removidos ao final (grep antes de remover).

### 2. Tipografia (Inter)

- Adicionar `Inter` pesos **300 / 400 / 600 / 700** (escada da Apple — sem peso 500) em
  `assets/fonts/` e declarar no `pubspec.yaml` (`fontFamily: Inter`).
- Reescrever `TextTheme`:
  - corpo (`bodyLarge`) **17px / 400 / -0.374 tracking** (o "17, não 16" da Apple);
  - títulos **600** com tracking negativo (-0.28 a -0.374) — cadência "Apple tight";
  - remover qualquer peso 500 (labels vão para 400 ou 600).

### 3. Formas / botões / sombra (`ThemeData`)

- **Botão primário:** pílula (`999`), `action` (`#0066cc`), texto branco; `scale(0.95)` no pressed.
- **Botão secundário:** pílula fantasma (borda `action` 1px, fundo transparente, texto `action`).
- **Anel de foco:** `actionFocus` (`#0071e3`) 2px — em botões e inputs (teclado/a11y).
- **Card:** raio **18px**, borda hairline 1px, `elevation: 0` (sem sombra em chrome).
- **Input:** pílula, altura 44px, borda hairline, foco `actionFocus` 2px.
- **AppBar:** fundo branco/parchment, título tinta `#1D1D1F`, `elevation: 0`,
  `scrolledUnderElevation: 0`. (Deixa de ser azul-cheia.) Header escuro só Splash/Home.
- **Superfícies escuras** (Splash, header da Home): toda ação/link usa `actionOnDark`
  (`#2997ff`) — `action` some no fundo `#272729`.
- **Sombra:** a única sombra do sistema Apple é reservada a foto de produto — o app não tem,
  então **nenhuma sombra** em nenhum lugar.

### 4. Componentes reutilizáveis (`lib/core/widgets/`)

Novos:
- `AppPillButton` — variantes `primary` / `secondary`; centraliza a gramática de botão-pílula.
- `AppCard` — card raio-18, hairline, sem sombra (base de listas e da Home).
- `SectionHeader` — título grande "Apple tight" no topo das telas.

Reskin dos existentes:
- `EmptyState` — tipografia/cor nova, ícone em ink-muted.
- `StatusBadge` — chip com a nova paleta (estados de sistema mantêm success/warning/danger).

### 5. Telas (Fase 3, uma a uma, commit atômico cada)

Ordem: `splash → login → home → config → consulta_preco → etiqueta → inventario →
entrada → coleta → inventario_update`.

Cada tela: aplicar `SectionHeader`, botões-pílula, `AppCard`, inputs-pílula, AppBar clara,
cor de ação única. Preservar toda a lógica de estado e chamadas de service.

---

## Fases de implementação

- **Fase 1 — Fundação:** `AppColors` + `TextTheme` + `ThemeData` + assets Inter no `pubspec`.
  Já re-skina muita coisa via tema. **Ponto de revisão do usuário.**
- **Fase 2 — Componentes:** `AppPillButton`, `AppCard`, `SectionHeader` + reskin de
  `EmptyState`/`StatusBadge`.
- **Fase 3 — Telas:** as 10 telas na ordem acima.

## Fora de escopo

- Adicionar botão da Entrada na Home (decisão separada, pendente).
- Modo escuro completo com toggle.
- Qualquer mudança de rede/API/lógica.
- Validação visual em device (sem device nesta sessão — declarar "analyze+testes ok,
  UI não validada visualmente" ao concluir cada tela).

## Testes

- `flutter analyze` limpo e `flutter test` (126) verde a cada commit.
- Se algum widget test dependia de uma cor/estrutura trocada, ajustar o **matcher visual**
  (não o comportamento) e documentar no commit.
