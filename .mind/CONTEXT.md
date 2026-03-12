# Context Map — epoch-chrono-site

Ponteiro central para todos os artefatos do projeto.
Quando precisar de conteúdo de qualquer arquivo abaixo, faça `web_fetch` na URL correspondente.

## Base URL

```text
https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main
```

## Artefatos — leitura sob demanda

| Arquivo | Buscar quando... | URL |
| :------ | :--------------- | :-- |
| `.mind/CONTENT_CONVENTIONS.md` | dúvidas de frontmatter, tags, categorias | [CONTENT_CONVENTIONS.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/CONTENT_CONVENTIONS.md) |
| `.mind/DESIGN_SYSTEM.md` | trabalhar em componentes, cores, tipografia, layout | [DESIGN_SYSTEM.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/DESIGN_SYSTEM.md) |
| `.mind/FOLDER_STRUCTURE.md` | criar arquivos, entender onde algo fica | [FOLDER_STRUCTURE.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/FOLDER_STRUCTURE.md) |
| `.mind/WRITING_WORKFLOW.md` | publicar post, drafts, newsletter | [WRITING_WORKFLOW.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/WRITING_WORKFLOW.md) |
| `.mind/CONTINUIDADE.md` | protocolo de sessão, fluxo dos comandos mind-\* | [CONTINUIDADE.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/CONTINUIDADE.md) |
| `.mind/commands/mind-read.md` | spec do comando `[mind-read]` | [mind-read.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/commands/mind-read.md) |
| `.mind/commands/mind-save.md` | spec do comando `[mind-save]` | [mind-save.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/commands/mind-save.md) |
| `.mind/commands/mind-snapshot.md` | spec do comando `[mind-snapshot]` | [mind-snapshot.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/commands/mind-snapshot.md) |
| `.mind/commands/mind-clear.md` | spec do comando `[mind-clear]` | [mind-clear.md](https://raw.githubusercontent.com/epoch-chrono/epoch-chrono-site/main/.mind/commands/mind-clear.md) |

## Instrução de leitura

Para ler qualquer artefato acima, use `web_fetch(<url>)`.
Os arquivos estão no repo público — nenhuma autenticação necessária.

## Sync com claude.ai

Apenas estes arquivos precisam ser upados manualmente no projeto claude.ai:

| Arquivo | Alvo | Quando re-upar |
| :------ | :--- | :------------- |
| `.mind/PROJECT_INSTRUCTIONS.claude.md` | Project Instructions | Após rodar `gen-claude-instructions` |
| `.mind/CONTEXT.md` (este arquivo) | Project Knowledge | Quando um novo arquivo `.mind/` for criado |

Todo o resto é lido sob demanda via URL acima — nunca precisa ser upado.

## Adicionando novos artefatos

Quando um novo arquivo for criado em `.mind/`:

1. Adicionar linha na tabela "Artefatos — leitura sob demanda" acima
2. Re-upar este `CONTEXT.md` no claude.ai
