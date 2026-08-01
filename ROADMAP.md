# ROADMAP — coletor_dados

Direção futura do projeto: fases, prioridades e escopo planejado.
Não é lista de tarefas do dia a dia (isso fica no `PROGRESSO.md`), nem histórico
de entregas (isso fica no `CHANGELOG.md`).

---

## Objetivo do produto

App Flutter para **coleta de dados em campo** integrado ao sistema de PDV/estoque
via API. Funções atuais: consulta de preço, etiquetas, inventário, entrada e coleta,
com configuração de servidor (IP/porta) e validação de licença.

_(Refine esta descrição com a visão de longo prazo do produto — a preencher)_

---

## Prioridades atuais

- **[P1] Corrigir filtro `?barcode=` no servidor da API.**
  O endpoint `GET /api/produtos?barcode=` ignora o filtro e devolve a lista inteira
  (~11.6k itens, ~2,4 MB) a cada consulta, deixando a consulta de preço lenta.
  Depende do time que mantém o backend. Quando resolvido, a consulta fica instantânea.
  (Detalhe em `PROGRESSO.md` › Próximos Passos.)

---

## Fases

### Fase atual — Estabilização
- Corrigir defeitos de dados exibidos ao usuário (ex.: valores da consulta de preço). ✅ em andamento
- _(demais itens a preencher)_

### Próxima fase — _(a preencher)_
- _(a preencher)_

### Futuro / ideias — _(a preencher)_
- _(a preencher)_

---

> Preencha as seções marcadas com `(a preencher)` conforme a direção do produto
> for definida. Mantenha este arquivo enxuto — direção, não tarefas.
