# mind-save

**v1.0.0** — Persiste o estado do workflow em `.mind/HANDOVER.md`.

## O que faz

Gera um resumo compacto da sessão atual e salva em `.mind/HANDOVER.md`.
Se já existe um HANDOVER.md anterior, **incorpora** o contexto acumulado — nunca sobrescreve, sempre faz append.

## Uso

```text
[mind-save]
```

Usar em marcos intermediários: após PR mergeado, feature concluída, decisão arquitetural tomada.

## Estrutura do HANDOVER.md gerado

```markdown
---
updated_at: "<timestamp ISO BRT>"
workflow: "<descrição curta do objetivo>"
---

## Contexto acumulado
<o que já foi feito no workflow — cresce a cada save, nunca é apagado>

## Output desta sessão
<resumo do que foi entregue/decidido>

## Próximo passo
<o que deve ser feito na próxima sessão>

## Arquivos relevantes
<paths tocados/criados nesta sessão>
```

## Regras

- Máximo 30 linhas de conteúdo (sem contar frontmatter)
- Telegráfico — paths, decisões, status. Sem explicações longas
- Contexto acumulado: append, nunca replace
- Criar `.mind/` se não existir
