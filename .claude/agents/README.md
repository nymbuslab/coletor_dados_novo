# 🦋 Flutter Agent System

**Multi-Agent System para Desenvolvimento Flutter/Dart**  
**Versão:** 2.0 · 2026

---

## Visão Geral

Sistema de agentes especializados coordenados por um orquestrador central para cobrir todo o ciclo de vida de desenvolvimento Flutter — da arquitetura ao deploy.

---

## Agentes Disponíveis

| # | Arquivo | Agente | Especialidade |
|---|---------|--------|---------------|
| 0 | `00_orchestrator.md` | 🧠 FlutterOrchestrator | Coordenação central e delegação |
| 1 | `01_architect.md` | 🏗️ ArchitectAgent | Clean Architecture, DI, Design Patterns |
| 2 | `02_ui.md` | 🎨 UIAgent | Widgets, temas, animações, responsividade |
| 3 | `03_state.md` | 🔄 StateAgent | BLoC, Riverpod, Provider, GetX |
| 4 | `04_api.md` | 🌐 APIAgent | REST, GraphQL, Dio, OAuth2 |
| 5 | `05_data.md` | 🗄️ DataAgent | Drift, Hive, Firebase, SecureStorage |
| 6 | `06_test.md` | 🧪 TestAgent | Unit, Widget, Integration, Golden Tests |
| 7 | `07_devops.md` | 🚀 DevOpsAgent | CI/CD, Fastlane, Build Flavors, Deploy |
| 8 | `08_security.md` | 🔒 SecurityAgent | Biometria, SSL Pinning, OWASP, Criptografia |

---

## Como Usar

### 1. Orquestrador para features completas

```
Agente: FlutterOrchestrator (00_orchestrator.md)

Feature: "Implementar carrinho de compras com persistência offline
         e sincronização ao reconectar"

→ O orquestrador analisa e delega para:
   1. ArchitectAgent → estrutura e contratos
   2. UIAgent → widgets do carrinho
   3. StateAgent → CartBloc com estados
   4. DataAgent → Drift para persistência local
   5. APIAgent → sincronização com backend
   6. TestAgent → testes de todos os flows
   7. DevOpsAgent → build e deploy
```

### 2. Agente especialista para tarefas focadas

```
Agente: StateAgent (03_state.md)

Tarefa: "Criar um BLoC para busca de produtos com debounce
        de 400ms e paginação infinita"

→ O StateAgent entrega:
   - SearchEvent, SearchState
   - SearchBloc com EventTransformer debounce
   - Paginação com cursor
   - Estados: initial, loading, success, failure, loadingMore
```

---

## Pipeline de Orquestração

```
Feature Request
      │
      ▼
┌─────────────────┐
│ 🧠 Orchestrator │  ← Analisa e planeja
└────────┬────────┘
         │
    ┌────┴─────────────────┐
    │                      │
    ▼                      ▼
┌───────────┐       ┌─────────────┐
│🏗️ Architect│       │🔒 Security  │
└─────┬─────┘       └──────┬──────┘
      │                    │
 ┌────┴──────────┐         │
 │               │         │
 ▼               ▼         │
🎨 UI          🔄 State     │
 │               │         │
 └───────┬───────┘         │
         │                 │
    ┌────┴────┐            │
    │         │            │
    ▼         ▼            │
  🌐 API    🗄️ Data         │
    │         │            │
    └────┬────┘            │
         │                 │
         ▼                 │
       🧪 Test             │
         │                 │
         └────────┬────────┘
                  │
                  ▼
              🚀 DevOps
                  │
                  ▼
           Output Final
```

---

## Stack de Referência

### Arquitetura
- Clean Architecture (Data / Domain / Presentation)
- Feature-first structure
- Dependency Injection: `get_it` + `injectable`

### Estado
- `flutter_bloc` + `bloc_test`
- `riverpod` (alternativa)
- `equatable` + `hydrated_bloc`

### Rede
- `dio` + interceptors
- `json_annotation` + `freezed`
- `dio_cache_interceptor`

### Dados
- `drift` (SQLite TypeSafe)
- `hive_flutter` (cache NoSQL)
- `flutter_secure_storage` (dados sensíveis)

### Testes
- `mocktail` (unit tests)
- `bloc_test` (BLoC tests)
- `golden_toolkit` (visual tests)
- `patrol` (integration tests)

### DevOps
- GitHub Actions
- Fastlane (iOS + Android)
- Firebase App Distribution
- Crashlytics + Performance

### Segurança
- `local_auth` (biometria)
- `encrypt` (AES-256)
- Certificate Pinning (Dio)
- Dart obfuscation
