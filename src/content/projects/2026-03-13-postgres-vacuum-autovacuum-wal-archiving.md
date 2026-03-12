---
title: "VACUUM não é o que você pensa — e autovacuum vai te trair em produção"
description: "Day 2 do prep Upwork: VACUUM, autovacuum, Visibility Map, XID wraparound e WAL archiving. Com o bônus do cenário que fez um banco congelar 24h depois de uma mudança que 'deu certo'."
pubDate: 2026-03-13T08:00:00-03:00
lang: "pt-BR"
draft: false
tags:
  - postgresql
  - vacuum
  - autovacuum
  - wal
  - database-internals
  - study
categories:
  - engineering
postVersion: "1.0.0"
---

No [Day 1](/projects/2026-03-12-postgres-mvcc-vacuum-para-quem-vem-do-oracle) ficou estabelecido que o Postgres guarda múltiplas versões de cada linha direto na heap. MVCC elegante, sem UNDO tablespace, sem rollback segments.

O que ficou em aberto é: quem faz a limpeza?

Essas versões antigas não somem sozinhas. Elas ficam lá, ocupando espaço, sendo ignoradas pelas queries mas presentes no arquivo. Dead tuples — e o mecanismo responsável por lidar com eles é o VACUUM.

Spoiler: VACUUM não faz o que você imagina que faz. E autovacuum vai falhar silenciosamente numa das suas tabelas mais importantes exatamente quando você menos espera.

---

## Dead tuples: o lixo que ninguém joga fora

Quando você faz `UPDATE` em uma linha no Postgres, o banco não modifica a linha original. Ele:

1. Marca a versão antiga com `xmax = ID da sua transação` (morta para quem vier depois)
2. Insere uma versão nova com `xmin = ID da sua transação` (viva para quem vier depois)
3. Committa — as duas versões coexistem no mesmo arquivo

Transações antigas que precisavam ver a versão velha ainda a enxergam. Transações novas veem só a nova. Consistência garantida, sem lock de leitura.

O problema: quando **ninguém mais precisa** da versão antiga, ela continua lá. Dead tuple. Está morta mas ocupa espaço físico na página. Sem limpeza, sua tabela cresce indefinidamente mesmo que você não insira um byte novo de dado real.

```sql
-- Diagnóstico básico: quanto lixo tem acumulado?
SELECT
  relname,
  n_live_tup,
  n_dead_tup,
  round(n_dead_tup::numeric / nullif(n_live_tup, 0) * 100, 2) AS dead_pct,
  last_autovacuum,
  last_vacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

Se `dead_pct` estiver alto e `last_autovacuum` estiver velho, você tem um problema.

---

## VACUUM: o janitor que organiza mas não joga fora

`VACUUM` marca o espaço das dead tuples como **reutilizável internamente**. Novos dados podem ocupar esse espaço. O arquivo **não encolhe**. O espaço não volta para o sistema operacional.

É como organizar uma gaveta bagunçada — você cria espaço para novas coisas sem comprar uma gaveta menor.

```sql
VACUUM tablename;           -- reclaim dead tuples, sem lock em reads/writes
VACUUM ANALYZE tablename;   -- reclaim + atualiza stats do planejador
ANALYZE tablename;          -- só atualiza stats (sem reclaim)
```

**VACUUM FULL** é diferente. Ele reescreve a tabela inteira em um arquivo novo. O espaço volta para o OS. O arquivo encolhe.

O preço: **lock exclusivo** durante toda a operação. Nada entra, nada sai. Para uma tabela de 50GB em produção, isso é downtime.

```sql
VACUUM FULL tablename;  -- ⚠️ exclusive lock — evite em produção
```

A alternativa online é `pg_repack` — extensão que faz o mesmo resultado do VACUUM FULL sem segurar lock exclusivo por toda a duração. É o que você deveria usar quando realmente precisa encolher o arquivo.

**Mapeamento Oracle:**

- VACUUM regular → sem equivalente direto (Oracle não tem dead tuples na heap)
- VACUUM FULL → `ALTER TABLE MOVE` (reescreve, exclusive lock)
- pg_repack → `ALTER TABLE MOVE ONLINE` (Oracle 12c+)
- Flashback Query → **não existe no Postgres**. PITR restaura um clone em instância separada.

---

## Autovacuum: a fórmula que te trai em tabelas grandes

Autovacuum é o daemon que roda VACUUM automaticamente em background. Por padrão está habilitado. A maioria das pessoas assume que "está habilitado" significa "está funcionando adequadamente". Não está.

O trigger para autovacuum rodar em uma tabela é:

```text
n_dead_tup > autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor × n_live_tup)
```

Com os defaults:

```text
n_dead_tup > 50 + (0.20 × n_live_tup)
```

**O problema**: 20% de uma tabela grande é muita dead tuple tolerada antes de disparar.

Tabela com 100M de linhas → autovacuum só roda quando acumular **20 milhões de dead tuples**. Enquanto isso, bloat crescendo, queries ficando mais lentas, índices fragmentados.

A solução é tunar por tabela:

```sql
-- Tabela de alta escrita: trigger muito mais agressivo
ALTER TABLE orders SET (
  autovacuum_vacuum_scale_factor = 0.01,  -- 1% em vez de 20%
  autovacuum_vacuum_threshold    = 1000   -- mínimo 1000 dead tuples
);

-- Verificar configurações atuais por tabela
SELECT relname, reloptions
FROM pg_class
WHERE relname = 'orders';
```

Uma dúvida comum: VACUUM (regular) precisa de lock? Não. Ele usa `ShareUpdateExclusiveLock` — compatível com reads e DML normais. Você pode rodar VACUUM manualmente em produção sem derrubar nada.

---

## Visibility Map e Freeze Map: as otimizações que você nunca viu mas usa todo dia

### Visibility Map

O Postgres mantém um bitmap por tabela — a Visibility Map (VM). Cada página da tabela tem um bit que diz: "todas as tuples aqui são visíveis para todas as transações".

Quando VACUUM passa e limpa uma página, marca esse bit. No próximo VACUUM, páginas marcadas como all-visible são **puladas** — não precisa re-verificar. Vacuum fica exponencialmente mais rápido conforme a tabela vai ficando limpa.

Bônus: **index-only scans**. Se uma página está marcada como all-visible, uma query que acessa dados via índice não precisa tocar a heap para validar visibilidade. Só o índice. Enorme ganho em tabelas de leitura intensiva.

### Freeze Map e XID wraparound

Transaction IDs (XIDs) no Postgres são inteiros de 32 bits. Contador que começa do zero, vai até ~2 bilhões e... volta pro zero.

O problema: se uma tuple antiga tem `xmin = 1000` e o contador deu a volta, o Postgres não sabe mais se essa transação é passada ou futura. Caos.

A solução é **freeze**: VACUUM substitui o `xmin` de tuples muito antigas por `FrozenTransactionId` — um valor especial que significa "sempre visível, para sempre, independente de qual XID a transação atual tiver".

O Freeze Map rastreia quais páginas já foram completamente frozen — autovacuum pula essas.

Se autovacuum ficar para trás e o freeze não acontecer a tempo, o Postgres vai forçar um **autovacuum de emergência** que congela a tabela inteira. Em casos extremos, o banco entra em modo de proteção e **para de aceitar writes**.

Oracle usa SCN de 48 bits — efetivamente nunca dá a volta. Não existe mecanismo equivalente.

---

## WAL Archiving: os três parâmetros que ninguém lembra juntos

PITR (Point-in-Time Recovery) exige três parâmetros, e a ausência de **qualquer um** dos três significa que PITR não funciona:

```ini
wal_level    = replica    # minimum para replicação e archiving
archive_mode = on         # explícito — sem isso, archive_command é ignorado
archive_command = 'aws s3 cp %p s3://meu-bucket/wal/%f'
# %p = path completo do segmento WAL
# %f = só o filename
```

**`wal_level = replica` requer restart completo** — não basta `pg_reload_conf()`. Isso é risco de manutenção em produção: janela de restart, novo base backup depois (o timeline muda).

```sql
-- Onde cada parâmetro está sendo lido (conf vs auto.conf)
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('wal_level', 'archive_mode', 'archive_command');

-- ALTER SYSTEM escreve em postgresql.auto.conf (tem precedência sobre postgresql.conf)
ALTER SYSTEM SET wal_level = 'replica';
SELECT pg_reload_conf();  -- para params que não precisam de restart
```

`postgresql.auto.conf` tem precedência sobre `postgresql.conf`. É o equivalente ao spfile do Oracle — mudanças via `ALTER SYSTEM` vão para lá, não para o arquivo que você edita manualmente.

---

## O cenário que congelou o banco 24h depois

Este é o tipo de incidente que fica marcado. Você habilita WAL archiving numa instância de produção. Faz o restart. Testa. Tudo ok — banco respondendo, aplicação estável, WAL sendo gerado. Vai dormir tranquilo.

24 horas depois, o banco congela.

O que aconteceu:

`archive_command` estava falhando silenciosamente. O destino estava cheio, ou o mount NFS estava ausente, ou era um problema de permissão. O comando retornava erro, mas ninguém estava olhando.

O mecanismo: quando `archive_command` falha, o Postgres **não descarta o segmento WAL**. Ele espera que o próximo retry funcione. Os segmentos acumulam em `pg_wal/`. Quando `pg_wal/` enche o disco, o Postgres entra em pânico e faz shutdown de emergência.

Diagnóstico:

```bash
# Checar tamanho de pg_wal/ — crescimento contínuo é sinal
du -sh $PGDATA/pg_wal/

# Nos logs: mensagens de archive_command failure perto do horário do freeze
grep "archive" $PGDATA/log/postgresql-*.log | tail -50

# Via SQL: último WAL arquivado com sucesso
SELECT * FROM pg_stat_archiver;
-- archived_count crescendo? last_failed_time recente? last_failed_wal?
```

A fix:

1. Liberar espaço / restaurar o destino de archive
2. Reiniciar o Postgres
3. Monitorar `pg_stat_archiver` continuamente — `last_failed_time` não deve avançar

A prevenção: alerta em `pg_stat_archiver.last_failed_time` e em tamanho de `pg_wal/`. Sem esses alertas, o próximo freeze é questão de tempo.

---

## Replication slots: o buraco silencioso

Slots de replicação são ponteiros persistentes que impedem o primary de descartar WAL que o consumer ainda não consumiu. Úteis. Perigosos se mal gerenciados.

Se um consumer desconecta e o slot fica aberto, o primary **continua acumulando WAL indefinidamente** para não perder o que o consumer vai precisar quando voltar. Se o consumer não volta, `pg_wal/` enche. Mesmo cenário do archive_command silencioso, mesma consequência.

```sql
-- Checar slots e lag
SELECT slot_name, active, restart_lsn,
       pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) AS lag_bytes
FROM pg_replication_slots;

-- Slot inativo com lag grande é risco imediato
-- Dropar com cuidado — sem rollback
SELECT pg_drop_replication_slot('nome_do_slot');
```

Alerta obrigatório: `pg_replication_slots` onde `active = false` e lag > threshold configurado.

---

## Referência rápida — Day 2

```sql
-- VACUUM básico (sem lock em DML)
VACUUM tablename;
VACUUM ANALYZE tablename;

-- Bloat: diagnóstico
SELECT relname, n_dead_tup, n_live_tup,
       round(n_dead_tup::numeric / nullif(n_live_tup,0) * 100, 2) AS dead_pct,
       last_autovacuum, last_vacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Autovacuum: tunar tabela de alta escrita
ALTER TABLE orders SET (
  autovacuum_vacuum_scale_factor = 0.01,
  autovacuum_vacuum_threshold    = 1000
);

-- WAL archiving: 3 params obrigatórios
-- wal_level = replica  (restart)
-- archive_mode = on    (restart)
-- archive_command = '...'

-- Monitorar archiver
SELECT * FROM pg_stat_archiver;

-- Replication slots: lag e status
SELECT slot_name, active,
       pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) AS lag_bytes
FROM pg_replication_slots;
```

**Mental model em 60 segundos:**

```text
Dead tuples (MVCC leftovers) → acumulam na heap → VACUUM reclaim interno
VACUUM = reusa espaço (sem shrink) | VACUUM FULL = reescreve (exclusive lock)
Autovacuum trigger: n_dead > threshold + (scale_factor × n_live) → tune por tabela
Bloat apesar de autovacuum → checar: txns longas / idle-in-txn / replication slots
WAL archiving exige OS TRÊS: wal_level=replica + archive_mode=on + archive_command
wal_level change = RESTART (não reload) → plan de manutenção
archive_command silent failure → pg_wal/ enche → banco congela
```

---

*Day 1: [Postgres não tem UNDO tablespace. E agora?](/projects/2026-03-12-postgres-mvcc-vacuum-para-quem-vem-do-oracle)*
