# PROGRESSO — coletor_dados

Controle de andamento do projeto. Fluxo de 3 seções: **Em Andamento → Próximos Passos → Concluído**.

> **Guardrail da API (regra do projeto):** a API vem pronta de outro sistema; o app
> só **consome** o JSON servido. Nenhuma correção pode alterar o contrato que hoje
> funciona — endpoint, parâmetro, formato de request ou corpo dos POST (incl. `imei: 7829`).
> Mudanças de parsing são **apenas defensivas**: passam a tolerar variações (número
> como string, campo ausente), mas o JSON atual continua lido de forma idêntica.

---

## 🔄 Em Andamento

- **[Lote 4] Services (cache/licença/scanner).** _(a iniciar)_
  Invalidar cache ao trocar servidor; não regenerar licença em falha transitória
  de leitura; scanner `.first` → `firstOrNull`; URL de licença por `Uri` seguro.

---

## 📋 Próximos Passos

Remediação da auditoria geral (2026-07-31/08-01). Um commit por lote, `flutter analyze`
+ testes ao fim de cada. Ordem: bugs de dados → polimento.

- **[P1] Lote 5 — Mensagens amigáveis + encoding.** Função central que traduz erro
  (rede/timeout/401/500/JSON) em português; corrigir mojibake ("nÃ£o"/"licenÃ§a"/"inventÃ¡rio").
- **[P1] Lote 6 — UX + navegação.** Navegação Home→Config duplicando a Home; back do sistema
  na Home; snackbar limpar anterior + não ser cortado pela navegação; áreas de toque + tooltip;
  cores fixas → tema.
- **[P2] Lote 7 — Robustez do app.** Captura global de erro (`runZonedGuarded`/`FlutterError.onError`);
  `network_security_config.xml` p/ cleartext (rede local); rota `default` do `onGenerateRoute`;
  mover `setUnauthorizedHandler` para fora do `build()`.
- **[P2] Lote 8 — Qualidade/consistência.** Remover dead code (`buscarProduto` não-FV,
  `sincronizar`, factories não usados); `IntrinsicHeight`→layout leve; `_build...()`→widget;
  lints estritos; versões de deps; retry cobrir 5xx (GET).
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

---

## ✅ Concluído

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
