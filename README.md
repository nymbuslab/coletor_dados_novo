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
git clone https://github.com/nymbuslab/coletor_dados_novo.git
cd coletor_dados_novo

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
GET  /fv/produtos            — lista completa p/ consulta de preço (filtro por cod_barras no cliente)
GET  /produtos               — lista geral de produtos
GET  /produtos?barcode=X     — atenção: o servidor ignora o filtro e devolve a lista inteira
GET  /etiquetas              — tipos de etiquetas disponíveis
GET  /licenca/:licenca       — validação de licença (body "ok" = válida)
POST /coletor                — envio de inventário / entrada / etiquetas
POST /dados                  — envio de dados coletados
```

---

## Arquitetura

```
lib/
├── core/              # Tema (theme) e widgets compartilhados
├── models/            # Entidades e DTOs
├── providers/         # ConfigProvider (Provider)
├── screens/           # Telas do app (rotas definidas no main.dart)
├── services/          # ApiService, StorageService, ScannerService, etc.
└── utils/             # BarcodeUtils
```

**Destaques de implementação:**
- `ApiService` — singleton com retry (até 3 tentativas, backoff exponencial), cache em memória (TTL 10 min) e timeouts por tipo de operação
- `ColetaScreen` — tela genérica reutilizada por Inventário e Entrada
- `BarcodeUtils.sanitize()` — sanitização centralizada de códigos de barras
- Licença armazenada em `FlutterSecureStorage`

---

## Licença

Licenciamento a definir — não há arquivo `LICENSE` no repositório.
