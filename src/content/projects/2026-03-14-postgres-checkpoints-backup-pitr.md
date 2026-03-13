---
title: "Checkpoint, pg_dump e PITR — ou: como não perder a tabela que alguém deletou"
description: "Day 3 do prep Upwork: como checkpoints funcionam, quando usar pg_dump vs pg_basebackup vs pgBackRest, e o fluxo completo de PITR — incluindo o recovery.signal que ninguém lembra."
pubDate: 2026-03-14T08:00:00-03:00
lang: "pt-BR"
draft: false
tags:
  - postgresql
  - backup
  - pitr
  - checkpoints
  - database-internals
  - study
categories:
  - engineering
postVersion: "1.0.0"
---

No [Day 2](/projects/2026-03-13-postgres-vacuum-autovacuum-wal-archiving) ficou estabelecido que WAL archiving precisa de três parâmetros e que `archive_command` falha silenciosamente de formas criativas e destrutivas. O Day 3 começa onde isso termina: o que acontece com esses WAL segments arquivados, e como você os usa pra voltar no tempo quando alguém faz `DROP TABLE orders` às 14h32 de uma sexta-feira.

Mas antes do PITR, tem um conceito que une tudo: checkpoint.

---

## Checkpoint: o âncora de recovery que você nunca viu falhar

Checkpoint é um ponto no tempo em que o Postgres garante que todas as dirty pages em memória foram escritas no disco. A partir desse ponto, o WAL antes dele pode ser ignorado para fins de crash recovery — se o banco cair depois do checkpoint, o Postgres só precisa replay WAL a partir do último checkpoint completo.

Sem checkpoints, crash recovery começaria do início do WAL. O banco nunca subiria em tempo hábil.

A sequência completa de um checkpoint:

```text
1. Escreve registro CHECKPOINT no WAL (marca o LSN de início)
2. Varre o shared buffer pool em busca de dirty pages
3. Escreve dirty pages no disco — espalhado ao longo de
   checkpoint_completion_target × checkpoint_timeout
4. Escreve CHECKPOINT COMPLETE no WAL
5. Atualiza pg_control com o novo checkpoint LSN
```

O `pg_control` é o arquivo que o Postgres lê no startup para saber de onde começar o replay. É o equivalente ao arquivo de controle do Oracle.

**BGWriter vs Checkpointer** — a confusão clássica:

- **BGWriter** = janitor contínuo. Fica escrevendo dirty pages no disco o tempo todo, antes mesmo do checkpoint precisar. Suaviza o I/O spike.
- **Checkpointer** = o flush completo agendado. Garante que *tudo* que estava sujo foi pro disco e atualiza o pg_control.

São complementares, não concorrentes. Oracle tem DBWR (≈ BGWriter) e CKPT (≈ Checkpointer) com a mesma divisão.

```sql
-- Estado atual do último checkpoint
SELECT * FROM pg_control_checkpoint();

-- Diagnóstico de checkpoint health
SELECT checkpoints_timed,
       checkpoints_req,    -- ALTO = max_wal_size pequeno demais
       buffers_checkpoint,
       buffers_clean,      -- contribuição do BGWriter
       buffers_backend     -- ALTO = shared_buffers pequeno demais (ruim)
FROM pg_stat_bgwriter;
```

`checkpoints_req` alto significa que o Postgres está forçando checkpoints antes do timeout porque o WAL cresceu além de `max_wal_size`. Sinal de que o parâmetro precisa aumentar.

`buffers_backend` alto significa que backends de usuário estão escrevendo dirty pages diretamente porque BGWriter e Checkpointer não estão dando conta. Isso causa latência irregular nas queries — o usuário paga o I/O no meio da transação.

**Parâmetros principais:**

| Parâmetro | Default | O que faz |
| --- | --- | --- |
| `checkpoint_timeout` | 5min | Trigger por tempo |
| `max_wal_size` | 1GB | Trigger por volume de WAL |
| `checkpoint_completion_target` | 0.9 | Spread de I/O — 90% do intervalo |

---

## Backup: três ferramentas, três casos de uso distintos

A confusão mais comum de quem vem do Oracle é tratar pg_dump como equivalente ao RMAN. Não é.

### pg_dump — lógico, portável, sem PITR

```bash
# Formato custom (recomendado — comprimido, restaurável em paralelo)
pg_dump -U postgres -d mydb -F c -f mydb.dump

# Formato SQL puro (legível, maior)
pg_dump -U postgres -d mydb -F p -f mydb.sql

# Tudo: todas as databases + roles + tablespaces
pg_dumpall -U postgres -f all.sql

# Restore paralelo (muito mais rápido em schemas grandes)
pg_restore -U postgres -d mydb -j 4 mydb.dump
```

É um snapshot lógico de um ponto no tempo. Portável entre versões, entre plataformas. Não tem PITR — você restaura o banco como ele estava no momento do dump, sem possibilidade de ir para um ponto intermediário.

Equivalente Oracle: Data Pump (`expdp`/`impdp`).

### pg_basebackup — físico, ponto de partida para PITR

```bash
pg_basebackup -h localhost -U replicator \
  -D /backup/base -Ft -z -P --wal-method=stream
# -Ft = formato tar
# -z  = compressão gzip
# -P  = progresso
# --wal-method=stream = inclui WAL gerado DURANTE o backup
```

Cópia binária do data directory. Resultado: você pode restaurar e depois aplicar WAL arquivado para chegar a qualquer ponto no tempo. É o ponto de partida obrigatório para PITR.

O `--wal-method=stream` é importante: sem ele, o backup pode não incluir os WAL segments gerados durante a própria cópia, deixando um gap irrecuperável.

Equivalente Oracle: `BEGIN BACKUP` / `END BACKUP` + cópia dos datafiles + archivelogs.

### pgBackRest — padrão de produção

```bash
pgbackrest --stanza=main backup --type=full
pgbackrest --stanza=main backup --type=diff
pgbackrest --stanza=main backup --type=incr
pgbackrest --stanza=main restore --target="2026-03-17 12:30:00"
```

Full/diff/incremental, S3/GCS/Azure, retenção configurável, catálogo, restore paralelo. É o que você usa em produção de verdade.

Equivalente Oracle: RMAN. Não tem equivalente nativo no Postgres — pgBackRest é extensão de terceiro, mas é o padrão de facto.

Postgres 17 adicionou incremental nativo via `pg_basebackup --incremental`, mas ainda é novo e pouco adotado.

---

## PITR: o fluxo que você precisa saber de cor

O cenário clássico de entrevista: um developer fez `DELETE FROM orders WHERE 1=1` (ou pior, `DROP TABLE`) às 14h32 de uma sexta. Você tem backups diários + WAL archiving no S3. O que você faz?

**Quatro requisitos — falta qualquer um, PITR não existe:**

1. `wal_level = replica`
2. `archive_mode = on`
3. `archive_command` funcionando e verificado
4. Base backup tirado **depois** dos três anteriores estarem ativos

Se o base backup foi tirado antes de `archive_mode = on`, você não tem como fazer PITR a partir dele.

**Fluxo completo:**

```bash
# 1. Confirmar que a instância de origem está parada
#    Crítico: se o primário ainda estiver escrevendo WAL no archive,
#    você pode sobrescrever segmentos que precisa para o recovery

# 2. Nova instância — porta diferente, mesma versão do Postgres
#    NUNCA restaurar por cima do primário ainda vivo

# 3. Restaurar o base backup para o data directory
pg_basebackup ... -D /var/lib/postgresql/data
# ou: pgbackrest --stanza=main restore

# 4. Configurar recovery no postgresql.conf
restore_command = 'aws s3 cp s3://bucket/wal/%f %p'
recovery_target_time = '2026-03-17 14:31:00'  # 1 min antes do desastre
recovery_target_action = 'promote'

# 5. Criar o signal file (Postgres 12+)
touch /var/lib/postgresql/data/recovery.signal

# 6. Subir — Postgres entra em recovery mode, faz replay, promove no target
pg_ctl start -D /var/lib/postgresql/data

# 7. Verificar
psql -c "SELECT pg_is_in_recovery();"
# false = promovido, online, pronto
```

**`restore_command`** é o espelho invertido do `archive_command`:

```text
archive_command = 'aws s3 cp %p s3://bucket/wal/%f'  # primary → archive
restore_command = 'aws s3 cp s3://bucket/wal/%f %p'  # archive → recovery
```

`%p` = path completo do arquivo WAL. `%f` = só o filename. Os dois são trocados entre archive e restore.

**`recovery.signal`** é um arquivo vazio que você cria no data directory. O Postgres detecta a presença dele no startup e entra em recovery mode. É o mecanismo do Postgres 12+ — antes existia `recovery.conf`, que foi descontinuado. A existência de um arquivo de sinal para controlar o modo de operação é... incomum, mas é o que é.

**`recovery_target_action`** define o que acontece quando o replay atinge o target:

- `promote` (mais comum) — promove para primary, aceita writes
- `pause` — para o replay, deixa em standby read-only para você verificar antes de promover
- `shutdown` — para o servidor (útil para scripts automatizados)

**Opções de `recovery_target`:**

```text
recovery_target_time    = '2026-03-17 14:31:00'  # mais comum
recovery_target_xid     = '12345678'              # transação específica
recovery_target_lsn     = '0/15D3458'             # posição exata no WAL
recovery_target_name    = 'my_savepoint'          # restore point nomeado
recovery_target         = 'immediate'             # para assim que ficar consistente
```

Postgres não tem as fases de startup do Oracle (NOMOUNT/MOUNT/OPEN). É mais simples de automatizar, menos controle granular.

---

## Trap de entrevista: crash no meio do checkpoint

"O servidor caiu no meio de um checkpoint. O que acontece quando volta?"

O Postgres lê o `pg_control` no startup, encontra o LSN do último checkpoint **completo**, e faz replay de todo o WAL a partir daquele ponto. As dirty pages que foram escritas a meio durante o checkpoint interrompido são simplesmente sobrescritas pelo replay — o WAL é a fonte de verdade, não os data pages.

É exatamente por isso que o WAL precisa ser escrito antes dos data pages. Write-Ahead Logging.

Equivalente Oracle: crash recovery usa redo logs da mesma forma — replay desde o último checkpoint do SCN.

---

## Referência rápida — Day 3

```sql
-- Checkpoint: estado atual
SELECT * FROM pg_control_checkpoint();

-- Checkpoint: diagnóstico
SELECT checkpoints_timed, checkpoints_req,
       buffers_checkpoint, buffers_clean, buffers_backend
FROM pg_stat_bgwriter;
```

```bash
# pg_dump — backup lógico
pg_dump -U postgres -d mydb -F c -f mydb.dump
pg_restore -U postgres -d mydb -j 4 mydb.dump

# pg_basebackup — backup físico (ponto de partida PITR)
pg_basebackup -h localhost -U replicator \
  -D /backup/base -Ft -z -P --wal-method=stream

# pgBackRest — produção
pgbackrest --stanza=main backup --type=full
pgbackrest --stanza=main restore --target="2026-03-17 12:30:00"

# PITR: signal file obrigatório (Postgres 12+)
touch /var/lib/postgresql/data/recovery.signal
```

**Mental model em 60 segundos:**

```text
Checkpoint = LSN no pg_control + flush de dirty pages
checkpoints_req alto → max_wal_size pequeno demais
buffers_backend alto → shared_buffers pequeno demais

pg_dump      = lógico, portável, sem PITR
pg_basebackup = físico, ponto de partida para PITR
pgBackRest   = produção: full/diff/incr, S3, retenção

PITR exige OS 4: wal_level=replica + archive_mode=on +
                 archive_command funcionando + base backup pós-ativação
restore_command = archive_command invertido (%p e %f trocados)
recovery.signal = arquivo vazio no data dir → entra em recovery mode
recovery_target_action = promote (default útil) | pause | shutdown
```

---

*Day 1: [Postgres não tem UNDO tablespace. E agora?](/projects/2026-03-12-postgres-mvcc-vacuum-para-quem-vem-do-oracle)*
*Day 2: [VACUUM não é o que você pensa — e autovacuum vai te trair em produção](/projects/2026-03-13-postgres-vacuum-autovacuum-wal-archiving)*
