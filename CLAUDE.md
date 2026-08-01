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
Plataformas: Android, iOS
```

**Gerenciamento de estado:** _(BLoC / Riverpod / Provider — preencha)_  
**Banco local:** _(Drift / Hive / SQLite — preencha)_  
**HTTP:** _(Dio / http — preencha)_  
**Injeção de dependência:** _(get_it + injectable — preencha)_

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

Clean Architecture com Feature-first:

```
lib/
├── core/
│   ├── di/                  # Injeção de dependências (get_it)
│   ├── error/               # Failures e Exceptions
│   ├── network/             # DioClient + interceptors
│   └── usecases/            # Interface base UseCase
│
├── features/
│   └── [feature]/
│       ├── data/            # Models, DataSources, RepositoryImpl
│       ├── domain/          # Entities, Repository (abstract), UseCases
│       └── presentation/    # BLoC/Notifier, Pages, Widgets
│
└── main.dart
```

**Regra de dependência:** `presentation → domain ← data`  
Domain nunca importa Flutter ou pacotes externos.

---

## Convenções de código

- **Nomenclatura:** `snake_case` para arquivos, `PascalCase` para classes
- **Widgets:** sempre `const` quando possível; extrair sub-widgets em vez de métodos
- **Estados BLoC:** usar `sealed class` + `final class` (Dart 3+)
- **Retornos de repository:** sempre `Either<Failure, T>` de dartz
- **Imports:** agrupar por (1) dart:, (2) flutter, (3) packages, (4) projeto
- **Testes:** padrão Arrange/Act/Assert, um arquivo de test por arquivo de prod

---

## Endpoints conhecidos

_(Preencha à medida que integrar APIs)_

```
Base URL (dev):     http://localhost:3000/api
Base URL (staging): https://staging.suaapi.com/api
Base URL (prod):    https://api.suaapi.com/api

GET  /coletas          — lista coletas
POST /coletas          — cria coleta
GET  /coletas/:id      — detalhe
```

---

## Banco de dados local

_(Preencha com suas tabelas)_

```
Schema version: 1

Tabelas:
- coletas (id, titulo, data, sincronizado)
- (adicione conforme criar)
```

---

## Notas e decisões arquiteturais

_(Use este espaço para registrar decisões importantes)_

- [DATA] Decisão: ...motivo...
- [DATA] Problema encontrado: ...solução...
- [2026-07-31] Gotcha API: `GET /api/produtos?barcode=<cod>` **ignora o filtro** e devolve a lista inteira (~11.6k itens, ~2,4 MB). Por isso `buscarProdutoPorBarcode` filtra pelo `cod_barras` no cliente (via `_buscarNaLista`) — **nunca usar `data.first`**, senão o "Valor Ult. Compra" vem do produto errado. Correção do servidor pendente (ver PROGRESSO.md).
