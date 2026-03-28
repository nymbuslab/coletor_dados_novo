# Coletor de Dados

Aplicativo Flutter para coleta de dados em campo, voltado para operações de inventário, entrada de estoque e impressão de etiquetas em ambientes de varejo/atacado.

---

## Funcionalidades

- **Consulta de Produtos** — busca por código de barras com exibição de preço e estoque
- **Inventário** — coleta e envio de contagens de estoque
- **Entrada de Mercadoria** — registro de recebimento de produtos
- **Etiquetas** — consulta e impressão de etiquetas por tipo
- **Configuração** — configuração do servidor via IP/porta e validação de licença
- **Scanner integrado** — leitura de código de barras via câmera

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Framework | Flutter 3.24.x / Dart 3.5.x |
| Estado | Provider |
| HTTP | `http` com retry e cache em memória |
| Armazenamento local | SharedPreferences + FlutterSecureStorage |
| Scanner | mobile_scanner |
| Plataforma alvo | Android |

---

## Pré-requisitos

- Flutter SDK `^3.24`
- Dart SDK `^3.5`
- Android Studio ou VS Code com extensão Flutter
- Dispositivo ou emulador Android

---

## Instalação

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/coletor_dados.git
cd coletor_dados

# Instale as dependências
flutter pub get

# Rode o app
flutter run
```

---

## Build

```bash
# APK release
flutter build apk --release

# App Bundle (Google Play)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

---

## Configuração

Na primeira execução, o app solicita o endereço do servidor (IP e porta) e valida a licença do dispositivo. As configurações ficam salvas localmente e podem ser alteradas na tela de **Configurações**.

O app se comunica com um backend REST. Endpoints esperados:

```
GET  /produtos               — lista de produtos
GET  /produtos?barcode=X     — busca por código
GET  /fv/produtos            — visão financeira de produtos
GET  /etiquetas/tipos        — tipos de etiquetas disponíveis
POST /coletor                — envio de inventário / entrada / etiquetas
GET  /ping                   — teste de conectividade
POST /licenca/validar        — validação de licença
```

---

## Arquitetura

```
lib/
├── core/              # Utilitários, tema, constantes
├── models/            # Entidades e DTOs
├── providers/         # ConfigProvider (Provider)
├── router/            # Configuração de rotas
├── screens/           # Telas do app
└── services/          # ApiService, StorageService, ScannerService, etc.
```

**Destaques de implementação:**
- `ApiService` — singleton com retry (até 3 tentativas, backoff exponencial), cache em memória (TTL 10 min) e timeouts por tipo de operação
- `ColetaScreen` — tela genérica reutilizada por Inventário e Entrada
- `BarcodeUtils.sanitize()` — sanitização centralizada de códigos de barras
- Licença armazenada em `FlutterSecureStorage`

---

## Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para mais detalhes.
