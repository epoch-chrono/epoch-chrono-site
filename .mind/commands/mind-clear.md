# mind-clear

**v1.0.0** — Limpa o workflow ativo — encerra o ciclo de trabalho.

## O que faz

1. Verifica e exibe resumo de 2 linhas do que está sendo encerrado
2. Deleta `.mind/HANDOVER.md` se existir
3. Limpa arquivos temporários de sessão em `.mind/tmp/` se existirem
4. Confirma o encerramento

## Uso

```text
[mind-clear]
```

Usar após ciclo de trabalho concluído, quando o snapshot já foi gerado e o trabalho está 100% encerrado.

## Fluxo correto

```text
[mind-snapshot]   ← gera o artefato de continuidade
    ↓
[mind-clear]      ← limpa o estado ativo
```

Não usar `[mind-clear]` sem antes rodar `[mind-snapshot]`, a menos que o trabalho realmente não precise de continuidade.

## Output esperado

```text
Encerrando workflow: <descrição>
Última atualização: <data>

✅ Workflow encerrado — HANDOVER.md removido.
```

ou

```text
Nenhum workflow ativo para limpar.
```
