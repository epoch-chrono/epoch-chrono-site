# mind-snapshot

**v1.0.0** — Gera um snapshot completo da sessão para continuidade cross-sessão.

## O que faz

Gera um artefato estruturado com tudo que um novo contexto precisa para continuar o trabalho sem perda.
Mais rico que `[mind-save]` — inclui git log, decisões, riscos, próximos passos priorizados.
**Após gerar, apaga `.mind/HANDOVER.md`** — o snapshot o substitui.

## Uso

```text
[mind-snapshot]
```

Usar ao encerrar uma sessão de trabalho.

## Estrutura do snapshot gerado

```markdown
---
snapshot: v1.0.0
project: epoch-chrono-site
date: <data ISO BRT>
---

# Snapshot — epoch-chrono-site

## Contexto
<stack, estado atual, o que é o projeto>

## O que foi feito
<lista das ações/decisões desta sessão>

## Estado atual
<onde o trabalho parou, o que funciona, o que não funciona>

## Próximos passos
<tarefas pendentes em ordem de prioridade>

## Decisões tomadas
<decisões arquiteturais ou técnicas relevantes>

## Riscos e bloqueios
<problemas conhecidos, dependências, limitações>
```

## Regras

- Entre 40–80 linhas
- Foco no que é necessário para continuar sem perder contexto
- Após gerar, deletar `.mind/HANDOVER.md`
- O snapshot deve ser adicionado manualmente ao projeto no claude.ai se necessário
