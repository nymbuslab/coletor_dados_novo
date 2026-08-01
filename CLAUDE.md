# coletor_dados — CLAUDE.md

> Arquivo de contexto lido automaticamente pelo Claude Code.
> Mantenha este arquivo atualizado conforme o projeto evolui.

---

## O que é este projeto

**coletor_dados** é um app Flutter para coleta de dados em campo.
_(Atualize esta descrição com o que o app realmente faz)_

---

## Stack e versões

```
Flutter: 3.24.x
Dart: 3.5.x
Plataformas: Android
```

**Gerenciamento de estado:** Provider (ChangeNotifier) — ex.: ConfigProvider  
**Persistência local:** SharedPreferences (dados) + flutter_secure_storage (licença)  
**HTTP:** http (pacote oficial), com retry/backoff e cache em memória  
**Injeção de dependência:** nenhuma — services como singleton/estáticos

---

## Comandos do projeto

```bash
# Instalar dependências
flutter pub get

# Gerar código (build_runner)
flutter pub run build_runner build --delete-conflicting-outputs

# Rodar testes
flutter test

# Rodar com cobertura
flutter test --coverage

# Analisar código
flutter analyze

# Formatar código
dart format .

# Rodar em modo dev
flutter run --dart-define=FLAVOR=dev

# Build staging
flutter build apk --release --dart-define=FLAVOR=staging

# Build produção
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

---

## Agentes disponíveis

Este projeto usa sub-agentes especializados em `.claude/agents/`.
Para invocar, use `@nome-do-agente` no chat ou `--agent nome` no CLI.

| @mention | Quando usar |
|----------|-------------|
| `@orchestrator` | **Ponto de entrada para QUALQUER feature nova** — ele analisa e delega |
| `@architect` | Estrutura, interfaces, DI, design patterns |
| `@ui` | Widgets, telas, temas, animações |
| `@state` | BLoC, Riverpod, lógica de negócio, estados |
| `@api` | Dio, endpoints, modelos, autenticação |
| `@data` | Drift, Hive, banco local, SecureStorage |
| `@test` | Unit, widget e integration tests |
| `@devops` | Build, CI/CD, Fastlane, flavors |
| `@security` | Biometria, SSL pinning, OWASP, criptografia |

**Como usar:**
```
# Opção 1 — via @mention no chat
@orchestrator implemente a tela de listagem de coletas com filtro por data

# Opção 2 — iniciar sessão como agente específico
claude --agent architect
claude --agent test
```

---

## Arquitetura

Estrutura plana por tipo (não é Clean Architecture / feature-first):

```
lib/
├── core/
│   ├── theme/       # AppColors, ThemeData
│   └── widgets/     # compartilhados (EmptyState, StatusBadge)
├── models/          # AppConfig, Produto, EtiquetaColetor, InventarioItem, Licenca
├── providers/       # ConfigProvider (Provider/ChangeNotifier)
├── services/        # ApiService, StorageService, LicenseService,
│                    # ScannerService, FeedbackService, LoggerService
├── screens/         # splash, login, home, consulta_preco, etiqueta,
│                    # inventario, entrada, coleta, config
├── utils/           # BarcodeUtils
└── main.dart
```

**Fluxo:** `screens → providers/services → models`. Sem camadas domain/data separadas.

---

## Convenções de código

- **Nomenclatura:** `snake_case` para arquivos, `PascalCase` para classes
- **Widgets:** sempre `const` quando possível; extrair sub-widgets em vez de métodos
- **Estado:** Provider/ChangeNotifier; services estáticos ou singleton
- **Retornos de service:** valor direto ou `null`; erros via `Exception` (sem dartz)
- **Imports:** agrupar por (1) dart:, (2) flutter, (3) packages, (4) projeto
- **Testes:** padrão Arrange/Act/Assert, um arquivo de test por arquivo de prod

---

## Endpoints conhecidos

```
Base URL: http://{endereco}:{porta}/api  (endereço/porta configurados no app)

GET  /fv/produtos        — lista completa p/ consulta de preço (filtro por cod_barras é no cliente)
GET  /produtos           — lista geral de produtos
GET  /produtos?barcode=  — ATENÇÃO: servidor IGNORA o filtro e devolve a lista inteira (ver Notas)
GET  /etiquetas          — tipos de etiquetas
GET  /licenca/:licenca   — valida licença (body "ok" = válida)
POST /coletor            — envia inventário / entrada / etiquetas (campo "coleta")
POST /dados              — envia dados coletados
```

---

## Banco de dados local

```
Não há banco relacional local. Persistência via chave-valor:

SharedPreferences:
- app_config           (endereco, porta, isConfigured — sem a licença)
- etiquetas_pendentes  (lista de Produto)
- inventario_itens     (lista de InventarioItem)
- entrada_itens        (lista de InventarioItem)

flutter_secure_storage:
- secure_license       (licença; fallback base64 em SharedPreferences fora de release)
```

---

## Notas e decisões arquiteturais

_(Use este espaço para registrar decisões importantes)_

- [DATA] Decisão: ...motivo...
- [DATA] Problema encontrado: ...solução...
- [2026-08-01] Decisão: HTTP cleartext liberado via `network_security_config.xml`
  (`base-config cleartextTrafficPermitted="true"`) porque o servidor é IP dinâmico da
  rede local (sem domínio fixo). Sem isso, Android 9+ bloqueia o HTTP puro que o app usa.
  Captura global de erro (`runZonedGuarded` + `FlutterError.onError` no `main.dart`) manda
  erros não tratados para o `LoggerService`; `setUnauthorizedHandler` registrado no `main()`
  (uma vez), fora do `build()`.
- [2026-07-31] Gotcha API: `GET /api/produtos?barcode=<cod>` **ignora o filtro** e devolve a lista inteira (~11.6k itens, ~2,4 MB). Por isso `buscarProdutoPorBarcode` filtra pelo `cod_barras` no cliente (via `_buscarNaLista`) — **nunca usar `data.first`**, senão o "Valor Ult. Compra" vem do produto errado. Correção do servidor pendente (ver PROGRESSO.md).
