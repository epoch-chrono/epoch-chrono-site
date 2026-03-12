# mind-read

**v1.0.0** — Exibe o estado atual do workflow da sessão.

## O que faz

Lê `.mind/HANDOVER.md` e resume o estado em 3–5 linhas:

- De onde veio (sessão anterior, agente, data)
- O que foi feito (contexto acumulado)
- O que falta (próximo passo)

Se não existe HANDOVER.md, informa que não há workflow ativo.

## Uso

```text
[mind-read]
```

Executar no início de uma nova sessão para verificar se há contexto acumulado antes de começar qualquer trabalho.

## Output esperado

```text
Workflow ativo encontrado:
- Objetivo: <descrição>
- Última sessão: <data>
- Contexto: <resumo>
- Próximo passo: <ação>
```

ou

```text
⚠️ Sem workflow ativo — .mind/HANDOVER.md não existe.
Use [mind-save] para iniciar.
```
