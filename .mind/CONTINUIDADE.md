# CONTINUIDADE — Protocolo de Sessão

Protocolo para migração e continuidade de sessões de trabalho no projeto epoch-chrono-site.

## Conceito

Sessões com Claude não persistem contexto automaticamente. Para manter continuidade entre conversas — sem precisar re-explicar o estado do projeto — usamos um protocolo baseado em arquivos Markdown versionados em `.mind/`.

O estado de uma sessão fica em `.mind/HANDOVER.md` (temporário, não commitado).
Ao encerrar uma sessão, um snapshot estruturado captura tudo que é necessário para continuar.

## Comandos

### `[mind-read]`

Lê `.mind/HANDOVER.md` e resume o estado atual.
Usar **no início de cada sessão** para verificar se há contexto acumulado.

### `[mind-save]`

Persiste o estado atual em `.mind/HANDOVER.md`.
Usar em **marcos intermediários** — após PR mergeado, feature concluída, decisão tomada.
Acumula contexto: cada save faz append, nunca sobrescreve.

### `[mind-snapshot]`

Gera um artefato completo de handoff e apaga o HANDOVER.md.
Usar ao **encerrar uma sessão** de trabalho.
Mais rico que `[mind-save]` — inclui git log, decisões, riscos, próximos passos priorizados.

### `[mind-clear]`

Limpa o workflow ativo — deleta HANDOVER.md e temporários.
Usar após **ciclo concluído** e snapshot gerado.

## Fluxo típico

```text
início de sessão  →  [mind-read]
                          ↓
              trabalho / commits / PRs
                          ↓
   marco importante  →  [mind-save]   (pode repetir)
                          ↓
      fim de sessão  →  [mind-snapshot]
                          ↓
  ciclo concluído   →  [mind-clear]
```

## Arquivos

| Arquivo | Status | Descrição |
| :------ | :----- | :-------- |
| `.mind/HANDOVER.md` | Não commitado | Estado temporário da sessão ativa |
| `.mind/commands/mind-read.md` | Commitado | Spec do comando `[mind-read]` |
| `.mind/commands/mind-save.md` | Commitado | Spec do comando `[mind-save]` |
| `.mind/commands/mind-snapshot.md` | Commitado | Spec do comando `[mind-snapshot]` |
| `.mind/commands/mind-clear.md` | Commitado | Spec do comando `[mind-clear]` |

Ver specs individuais em `.mind/commands/`.
