---
title: "Postgres não tem UNDO tablespace. E agora?"
description: "MVCC no PostgreSQL é elegante na teoria e surpreendente na prática. O que acontece com seus dados quando um UPDATE roda — e por que isso explica o VACUUM."
pubDate: 2026-03-12T11:50:00-03:00
lang: "pt-BR"
draft: false
tags:
  - postgresql
  - mvcc
  - vacuum
  - database-internals
  - study
categories:
  - engineering
postVersion: "1.0.0"
---

Quem vem do Oracle chega no Postgres com um modelo mental já formado sobre como bancos de dados lidam com concorrência. UNDO tablespace, redo logs, SCN, rollback segments — tudo aquilo faz sentido junto. É um sistema coerente.

Então você descobre que o Postgres não tem nada disso. Sem UNDO tablespace. Sem rollback segments. E a primeira pergunta que aparece é legítima: como ele não explode?

A resposta curta é MVCC. A resposta longa é o que esse post é.

---

## O problema que o MVCC resolve

Imagine dois processos acessando a mesma linha ao mesmo tempo. Um está lendo, outro está escrevendo. Sem nenhum mecanismo de controle, o leitor vê um dado parcialmente modificado — o que é inaceitável.

A solução clássica é lock. Você bloqueia a linha enquanto ela está sendo escrita e ninguém lê no meio do caminho. Funciona. É lento.

Outra solução é manter múltiplas versões do dado. Quem lê, lê uma versão consistente. Quem escreve, cria uma versão nova. Eles nunca travam um ao outro. Isso é Multi-Version Concurrency Control.

Oracle e Postgres implementam MVCC. A diferença está *onde* eles guardam essas versões.

---

## Oracle: as versões ficam fora da tabela

No Oracle, quando você faz `UPDATE` em uma linha, o banco:

1. Copia o valor antigo para o **UNDO tablespace**
2. Escreve o novo valor no bloco da tabela
3. Guarda no undo o suficiente para "desfazer" a mudança se alguém precisar do dado como era antes

Um leitor que precisa da versão antiga vai buscar no UNDO. A tabela em si fica com só uma versão — a atual. Limpa. Compacta.

O custo: se uma transação longa precisar de uma versão muito antiga e o UNDO tiver sido sobrescrito, você leva `ORA-01555: snapshot too old`. Esse é o tributo que o modelo Oracle cobra.

---

## Postgres: as versões ficam dentro da tabela

O Postgres faz diferente. Quando você faz `UPDATE`:

1. A linha antiga **permanece no heap** (a estrutura de armazenamento da tabela)
2. Uma nova linha é inserida no mesmo espaço com os valores atualizados
3. Cada linha carrega dois campos ocultos: `xmin` e `xmax`

`xmin` é o ID da transação que criou aquela versão da linha. `xmax` é o ID da transação que a "deletou" — ou zero, se a linha ainda é ativa.

Quando uma query roda, ela sabe seu próprio ID de transação e enxerga apenas as linhas cujo `xmin` é de uma transação que já commitou antes dela começar. As versões mais novas, invisíveis. As mais antigas, disponíveis. Consistência garantida sem lock.

A vantagem: sem `ORA-01555`. A versão antiga sempre está lá.

O custo: a tabela acumula versões antigas. Linhas que ninguém mais precisa, mas que continuam ocupando espaço em disco. São as **dead tuples**.

---

## O que são dead tuples e por que importam

Toda linha deletada ou substituída por um `UPDATE` vira uma dead tuple. Ela continua no heap até que alguém limpe.

Você pode ver isso em tempo real:

```sql
SELECT
  relname,
  n_live_tup,
  n_dead_tup,
  round(n_dead_tup::numeric / nullif(n_live_tup + n_dead_tup, 0) * 100, 1) AS dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

Em tabelas com muita escrita e sem manutenção adequada, `dead_pct` sobe. O que significa que suas queries estão varrendo páginas com dado que não serve mais. Seus índices também apontam para essas linhas. É bloat — inchaço.

Tabelas de 50GB com 10GB de dado vivo acontecem. Não é catástrofe, mas é sinal de que o mecanismo de limpeza não está funcionando.

---

## VACUUM: o lixeiro que você precisa entender

`VACUUM` é o processo responsável por marcar dead tuples como espaço reutilizável. Não é um defragmentador — ele não devolve espaço para o sistema operacional (isso é `VACUUM FULL`, que tem outros trade-offs). Ele apenas marca aquele espaço como disponível para novas inserções.

Rodando manualmente:

```sql
VACUUM ANALYZE nome_da_tabela;
```

`ANALYZE` junto atualiza as estatísticas do planner. Vale sempre fazer os dois.

Mas você não deveria precisar rodar isso manualmente. O **autovacuum** existe exatamente para isso — um processo de background que monitora as tabelas e roda VACUUM quando o acúmulo de dead tuples passa de um threshold.

Os parâmetros principais:

```sql
-- Quando autovacuum dispara (padrão: 20% de dead tuples)
autovacuum_vacuum_scale_factor = 0.2

-- Número mínimo de dead tuples antes de considerar o scale factor
autovacuum_vacuum_threshold = 50

-- Quantidade de workers simultâneos
autovacuum_max_workers = 3
```

Para tabelas grandes com alta rotatividade de dados, o padrão de 20% é tarde demais. Uma tabela com 10 milhões de linhas precisa acumular 2 milhões de dead tuples antes do autovacuum agir. Faz sentido reduzir o `scale_factor` para essas tabelas específicas:

```sql
ALTER TABLE eventos
  SET (autovacuum_vacuum_scale_factor = 0.05);
```

---

## O trade-off honesto

O modelo do Postgres não é melhor nem pior que o do Oracle. É diferente, com implicações diferentes.

No Oracle, você gerencia UNDO tablespace — precisa dimensionar, monitorar, evitar `ORA-01555`. A tabela fica limpa.

No Postgres, você gerencia bloat — precisa que o autovacuum funcione bem, monitorar `n_dead_tup`, ajustar parâmetros por tabela. Em troca, nunca perde uma versão antiga por falta de espaço no UNDO.

Para a maioria dos casos, o autovacuum bem configurado resolve. O problema aparece quando ele está desabilitado (sim, algumas pessoas fazem isso), quando os thresholds estão muito conservadores para o volume de dados, ou quando existe uma transação longa mantendo versões antigas vivas por horas.

Esse último caso é o mais comum em produção e merece um post próprio.

---

## O que fica

Se você saiu de um banco Oracle e está entrando num ambiente Postgres, o mapa mental muda em um ponto fundamental: a tabela não é mais "o dado atual". É um heap com múltiplas versões, e a visibilidade de cada uma depende de quando sua transação começou.

VACUUM não é opcional. É parte do funcionamento do banco. Entender quando e por que ele roda é tão importante quanto entender índices.

E `pg_stat_user_tables` é seu amigo. Coloca no dashboard desde o dia um.
