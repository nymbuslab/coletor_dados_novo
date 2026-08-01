# PROGRESSO — coletor_dados

Controle de andamento do projeto. Fluxo de 3 seções: **Em Andamento → Próximos Passos → Concluído**.

> **Guardrail da API (regra do projeto):** a API vem pronta de outro sistema; o app
> só **consome** o JSON servido. Nenhuma correção pode alterar o contrato que hoje
> funciona — endpoint, parâmetro, formato de request ou corpo dos POST (incl. `imei: 7829`).
> Mudanças de parsing são **apenas defensivas**: passam a tolerar variações (número
> como string, campo ausente), mas o JSON atual continua lido de forma idêntica.

---

## 🔄 Em Andamento

_(nada no momento)_

---

## 📋 Próximos Passos

Remediação da auditoria geral (2026-07-31/08-01). Um commit por lote, `flutter analyze`
+ testes ao fim de cada. Ordem: bugs de dados → polimento.

- **[P2] Lote 9 — Testes.** Widget tests (Splash/Config/Coleta); teste do `ConfigProvider`;
  teste do retry/backoff; corrigir teste enganoso "API não configurada"; testar redação do
  `LoggerService` e `StorageService`.

### Mitigação sem backend (decidir ao chegar no lote)
- **Duplicação de POST em timeout:** deixar de reenviar POST automaticamente em timeout
  (só no cliente, não muda o envio). Trade-off: evita gravar 2x, mas exige o usuário reenviar
  se realmente cair. Alinhar antes de aplicar.

### Fora de escopo (dependem do backend — não temos acesso)
- Autenticação por requisição (anexar licença/token às escritas). **Descartado.**
- Dedup no backend por UUID. **Descartado** (fica só a mitigação de cliente acima).
- Trocar/remover `imei: 7829`. **Não tocar** (faz parte do POST que funciona).

### Pendências de decisão do usuário
- Tela **Entrada** está implementada e roteada (`/entrada`) mas **sem botão** na navegação —
  é intencional (feature pausada) ou faltou o acesso na Home?

### Pendência externa (backend)
- **[P1] Filtro `?barcode=` no servidor da API.** `GET /api/produtos?barcode=<código>`
  ignora o filtro e devolve a lista inteira (~11.640 itens, ~2,4 MB). O app já filtra no
  cliente (blindado); a raiz é no servidor. Encaminhar a quem mantém a API.

### Pendência de validação em device
- **[P2] `flutter_secure_storage` 9 → 10 (major).** Segurado no Lote 8.3 por ser breaking
  e guardar a licença do dispositivo (muda API/plugins Android). Fazer só com device em mãos:
  revisar migração da v10 e conferir que a licença já gravada nos aparelhos sobrevive ao update.
- **[P2] Revalidar leitura de código de barras.** `mobile_scanner` foi para 7.4.0 sem teste
  em device; confirmar em campo que a câmera/scanner segue lendo normalmente.

---

## ✅ Concluído

- [x] **[Lote 8.3] Deps.** — 2026-08-01 (`0abc18f`)
  Revisadas as 3 dependências diretas atrasadas. **`intl` 0.20.2 → 0.20.3** (patch) e
  **`mobile_scanner` 7.1.2 → 7.4.0** (minor no v7, não-breaking) bumpados. **`flutter_secure_storage`
  9 → 10 segurado** de propósito (major/breaking, guarda a licença — precisa de device; ver
  Pendência de validação em device). `test` (dev) fica travado pela constraint do Flutter SDK.
  Validado: `flutter pub get` ok, `flutter analyze` limpo, 88 testes. Leitura do scanner não
  validada em device.

- [x] **[Lote 8.2] Extrair sub-widgets.** — 2026-08-01 _(3 commits)_
  Três métodos `_build*` que retornavam `Widget` viraram `StatelessWidget` próprios,
  criando fronteira de rebuild por item da lista (antes rebuildavam junto com a tela).
  **`_InfoRow`** (`8d0c0db`) — linha rótulo:valor da Consulta de Preço (9 call sites).
  **`_ItemCard`** (`d626785`) — card de item coletado (Coleta/Inventário/Entrada); recebe
  cor, item e callbacks editar/remover por parâmetro; `_formatarQuantidade` virou função de
  nível superior. **`_ProdutoCard`** (`ebd54ea`) — card de produto na Etiqueta; recebe
  produto, tipo de fallback e callback remover. **UI não validada visualmente** (sem device).
  Validado: `flutter analyze` limpo, 88 testes.

- [x] **[Lote 8.1] Lints adiados religados.** — 2026-08-01 (`3fcf401`)
  Ligadas as duas regras que ficaram fora do Lote 8, com os 13 findings corrigidos sem
  mudança de comportamento: **`unawaited_futures`** (8 sites fire-and-forget — navegação e
  busca disparada — envolvidos em `unawaited()` + import `dart:async`; **não** troquei por
  `await`, para não alterar timing) e **`strict-inference`** (5 sites `Future.delayed(...)`
  → `Future<void>.delayed(...)`). Validado: `flutter analyze` limpo, 88 testes.

- [x] **[Lote 8] Qualidade/consistência.** — 2026-08-01 _(4 commits)_
  **Commit 1 (`501ba59`) — dead code:** removidos `ConfigProvider.sincronizar`,
  `ApiService.buscarProduto` não-FV, a classe `Licenca` inteira, e os desserializadores
  usados só em testes (`InventarioItem.fromJson/copyWith`, `InventarioRequest.fromJson`,
  `EtiquetaColetor.fromJson`) + os testes correspondentes (101→88 testes). Envio à API
  intacto. **Commit 2 (`9415a1c`) — retry 5xx:** `_get` re-tenta respostas 5xx (GET é
  idempotente) e devolve a última ao esgotar; `_post` **inalterado** de propósito (nunca
  re-tenta 5xx, evita gravação dupla). **Commit 3 (`94412f3`) — lints:** conjunto estrito
  sobre `flutter_lints` (avoid_void_async, prefer_single_quotes, unnecessary_lambdas, etc.)
  + 11 auto-fixes seguros. **Commit 4 (`6c5fabb`) — UI:** `IntrinsicHeight`→`Container` com
  `Border(left: 4px)` em `_buildItemCard`/`_buildProdutoCard` (some o passe de layout extra
  por card; offset do conteúdo idêntico). **UI não validada visualmente** (sem device).
  Validado em cada etapa: `flutter analyze` limpo, 88 testes.

- [x] **[Lote 7] Robustez do app.** — 2026-08-01
  **Captura global de erro** (`main.dart`): `runApp` dentro de `runZonedGuarded` +
  `WidgetsFlutterBinding.ensureInitialized()`; `FlutterError.onError` manda todo erro
  não tratado para o `LoggerService.e` (que já mascara dados sensíveis) e ainda pinta a
  tela vermelha em debug — antes um erro solto sumia sem registro. **`setUnauthorizedHandler`
  movido para o `main()`** (fora do `build()` do `MyApp`): registrado uma vez só, não mais a
  cada rebuild; comportamento do 401/403 (redirecionar ao Login) idêntico. **Cleartext HTTP**:
  novo `android/app/src/main/res/xml/network_security_config.xml` (`base-config
  cleartextTrafficPermitted="true"`, IP dinâmico → sem domínio fixo) referenciado no
  `AndroidManifest` — blinda o HTTP da rede local contra o bloqueio padrão do Android 9+
  (aditivo, não muda o caso que funciona). **Cast defensivo** na rota `/inventario-update`
  (`as Produto?` + guarda → Splash) para não estourar sem argumento. Zero contato com a API.
  Validado: `flutter analyze` limpo, 101 testes.

- [x] **[Lote 6] UX + navegação.** — 2026-08-01
  **6A (navegação/snackbar):** Config volta para a Home existente com `pop()` (não empilha
  outra Home); `PopScope` na Home manda o back do sistema para o Login (igual à seta);
  `FeedbackService.showSnack` chama `hideCurrentSnackBar()` (não empilha e sobrevive à
  navegação via messenger do `MaterialApp`). **6B (a11y):** botões editar/remover dos cards
  ganharam `tooltip` e alvo de toque mínimo (40dp). **6C (cores→tema):** nas 3 telas de busca,
  `Colors.blue/green/orange/grey[...]` → tokens do `AppColors` (etiqueta/consulta/success/
  warning/danger/info/surfaceSubtle). Resíduo menor: AppBar azul do `scanner_service`
  (exigiria novo import) ficou fora. Validado: `flutter analyze` limpo, 101 testes.

- [x] **[Lote 5] Mensagens amigáveis + encoding.** — 2026-08-01 _(2 commits)_
  Parte A (`3487702`): `FeedbackService.friendlyError` traduz erro técnico
  (timeout/rede/401/403/5xx/JSON) em português; as 3 telas de busca passam a exibir a
  mensagem amigável no lugar do texto cru da `Exception` — o detalhe técnico segue no log.
  Parte B: corrigido o mojibake (`Ã£`→`ã`, `Ã§`→`ç`, etc.) em 8 arquivos de `lib/`
  (comentários, logs e mensagens de `Exception`) — regra única em nível de byte
  (`c3 83 c2 XX` → `c3 XX`); diff simétrico, nada trafega para a API. Validado:
  `flutter analyze` limpo, 101 testes.

- [x] **[Lote 4] Services (cache/licença/scanner).** — 2026-08-01
  `ApiService.configure` invalida o cache em memória quando a URL base muda de fato
  (mesma URL não invalida — cache normal preservado) → não devolve mais produto do
  servidor anterior após troca. `StorageService.loadOrCreateLicense` não gera licença
  nova em falha **transitória** de leitura do secure storage (flag `readThrew` → retorna
  vazio) — evita sobrescrever a licença real do dispositivo. Scanner protege
  `capture.barcodes.first` de lista vazia. URL de licença via `Uri.encodeComponent`
  (byte-idêntica p/ os valores reais; só blinda caractere especial). Contrato da API
  intacto. Validado: `flutter analyze` limpo, 101 testes.

- [x] **[Lote 3] Corridas e estado nas telas.** — 2026-08-01
  Numeração retomada pelo maior `item` existente (não pelo `length`) em `coleta_screen`
  — remover item do meio e reabrir não gera mais número duplicado (Inventário/Entrada).
  `etiqueta_screen`: lista salva agora carrega **antes** de adicionar o produto vindo da
  Consulta de Preço (`_inicializarLista` sequencia o `await`), acabando com a corrida que
  apagava as etiquetas salvas; `mounted` checado no `addPostFrameCallback`. Consulta de
  Preço ganhou sequência (`_consultaSeq`): resposta atrasada de um código antigo (inclusive
  o `valor_compra` assíncrono) não sobrescreve mais um código consultado depois. Tudo
  telas/estado, zero contato com a API. Validado: `flutter analyze` limpo, 101 testes.

- [x] **[Lote 2] Código de barras / parse defensivo.** — 2026-08-01
  `BarcodeUtils.normalizeForCompare` (UPC-A 12 díg. → EAN-13 com zero à esquerda, canônico)
  usado em `_buscarNaLista` — leitor de 12 díg. passa a casar com base de 13. `InventarioItem.fromJson`
  e `TipoEtiqueta.fromJson` com parse defensivo (número como string/nulo/ausente não quebra mais).
  `Produto.qtdEstoque` preserva `null` → "N/A" quando a API não manda o campo. Tudo aditivo (JSON
  atual lido igual). Validado: `flutter analyze` limpo, 101 testes.

- [x] **[Lote 1] Configuração: gate de `isConfigured` + mensagem única.** — 2026-08-01
  `isConfigured` só grava `true` após validar conexão/licença (`saveConfig` ganhou
  `markConfigured`; o teste salva `false`, só o botão Salvar grava `true`) — antes o app
  liberava telas com servidor nunca validado. Banner de status unificado (removido o 2º
  banner que repetia `configProvider.errorMessage` — bug do print) e snackbar de sucesso
  redundante removido. Banner decide cor/ícone por tipo (`isSuccess`), não mais pelo `✓`;
  glifos `✓/✗` retirados do texto (o ícone Material já comunica). Só `config_provider.dart`
  + `config_screen.dart`, zero contato com a API. Validado: `flutter analyze` limpo, 101 testes.

- [x] **Fix: "Valor Ult. Compra" errado na Consulta de Preço.** — 2026-07-31
  O endpoint `/api/produtos?barcode=` retorna a lista inteira ignorando o filtro,
  e o app pegava o **primeiro item** da lista (`data.first`) como valor de compra —
  mostrando sempre o preço de compra do produto errado para qualquer código
  consultado. Corrigido em `buscarProdutoPorBarcode` ([api_service.dart](lib/services/api_service.dart#L318)):
  agora filtra pelo `cod_barras` (reusando `_buscarNaLista`) e retorna `null` se não
  encontrar. Adicionado grupo de testes de regressão em
  [test/services/api_service_test.dart](test/services/api_service_test.dart).
  Validado: `flutter analyze` limpo, 36 testes passando, e conferido contra os dados
  reais da API (valor de compra correto da abraçadeira 7897186005683 = R$ 2,70).
