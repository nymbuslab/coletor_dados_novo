# PROGRESSO — coletor_dados

Controle de andamento do projeto. Fluxo de 3 seções: **Em Andamento → Próximos Passos → Concluído**.

---

## 🔄 Em Andamento

_(nada em curso)_

---

## 📋 Próximos Passos

- **[P1] Corrigir filtro `?barcode=` no servidor da API.**
  O endpoint `GET /api/produtos?barcode=<código>` **ignora o filtro** e devolve a
  lista inteira (~11.640 produtos, ~2,4 MB) a cada consulta. Isso deixa a consulta
  de preço lenta e pesada (ainda mais no coletor via Wi-Fi). O app já foi blindado
  para não usar o valor errado (ver Concluído), mas a raiz está no servidor —
  encaminhar para quem mantém a API. Quando corrigido, a consulta fica instantânea.

---

## ✅ Concluído

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
