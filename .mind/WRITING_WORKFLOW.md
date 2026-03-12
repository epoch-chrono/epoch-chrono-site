# Writing Workflow — epoch-chrono

## Fluxo de um post (blog ou TIL)

```text
Ideia → Rascunho → Revisão → Publicação → Amplificação
```

### 1. Capturar ideia

- Notion (conta Epoch) ou arquivo `drafts/inbox.md` no repo (no .gitignore)
- Mínimo necessário: título provisório + uma frase de contexto

### 2. Rascunho

- Criar arquivo com `draft: true` no frontmatter
- Commitar normalmente — `draft: true` garante que não aparece no site
- Branch não necessária para posts; usar `main` direto é aceitável
- Para posts grandes: criar branch `content/slug-do-post`

```bash
# Criar rascunho de post
touch src/content/blog/$(date +%Y-%m-%d)-slug-do-post.md
```

### 3. Preview local

```bash
pnpm dev
# Acessar http://localhost:4321
```

Para visualizar drafts no build local, configurar variável:

```bash
# astro.config.mjs — só em dev mode
# ou usar flag: SHOW_DRAFTS=true pnpm dev
```

### 4. Revisão

- Ler em preview (não só no editor)
- Checar: frontmatter completo, tags ≤ 5, `description` preenchida, OG funcional
- Rodar spell check: `cspell src/content/blog/YYYY-MM-DD-slug.md`

### 5. Publicação

```bash
# Mudar draft: true → false
# Commitar e push para main
git commit -m "content: publish post 'Título do Post'"
git push origin main

# Vercel faz deploy automático em ~60s
```

### 6. Amplificação (checklist pós-publicação)

- [ ] LinkedIn (post curto com link)
- [ ] Slack pessoal ou grupos relevantes
- [ ] Twitter/X (se ativo)
- [ ] Newsletter (se aplicável — ver seção abaixo)
- [ ] Submeter ao lobste.rs / Hacker News se conteúdo relevante internacionalmente

---

## TIL — fluxo acelerado

TIL é intencionalmente mais leve. Sem branch, sem revisão longa.

```bash
# Template rápido
cat > src/content/til/$(date +%Y-%m-%d)-slug.md << 'EOF'
---
title: "TIL: "
pubDate: $(date +%Y-%m-%d)
tags: []
draft: false
---

EOF
```

Comprometer com escrever em < 30 minutos. Se passar disso, virou blog post.

---

## Newsletter

- Plataforma: **Buttondown** (free até 100 inscritos, API simples)
- Frequência: irregular — só quando tiver algo relevante
- Conteúdo: curadoria de 2–3 posts/TILs recentes + um parágrafo de contexto
- API Buttondown:

```bash
BUTTONDOWN_API_KEY='<FILL_ME>'
BUTTONDOWN_API='https://api.buttondown.email/v1'

# Listar inscritos
xh GET "$BUTTONDOWN_API/subscribers" "Authorization:Token $BUTTONDOWN_API_KEY"

# Criar rascunho de email
xh POST "$BUTTONDOWN_API/emails" \
  "Authorization:Token $BUTTONDOWN_API_KEY" \
  subject="Título" \
  body="Conteúdo em Markdown" \
  status="draft"
```

---

## Integração Notion → Post (opcional)

Para quem prefere escrever no Notion e exportar para MD:

1. Escrever no Notion com o template de post
2. Exportar como Markdown
3. Ajustar frontmatter manualmente
4. Revisar imagens (referenciar localmente ou em CDN)

Automação futura: script `bin/notion-to-post.sh` que faz pull via API e converte.

---

## Comandos úteis

```bash
# Dev server
pnpm dev

# Build local (sem drafts)
pnpm build && pnpm preview

# Novo post (interativo — a implementar em bin/new-post.sh)
./bin/new-post.sh blog "Título do Post"
./bin/new-post.sh til "O que aprendi hoje"

# Listar todos os rascunhos
rg "draft: true" src/content/ -l

# Checar links quebrados no build
pnpm build && pnpm check-links
```

---

## bin/new-post.sh (template para criar)

```bash
#!/usr/bin/env fish

set type $argv[1]   # blog | til | project
set title $argv[2]
set date (date +%Y-%m-%d)
set slug (echo $title | tr '[:upper:]' '[:lower:]' | sd ' ' '-' | sd '[^a-z0-9-]' '')
set file "src/content/$type/$date-$slug.md"

echo "---
title: \"$title\"
pubDate: $date
draft: true
tags: []
---

" > $file

echo "Criado: $file"
hx $file
```

---

## Tom e voz — IMPORTANTE

O tom do site é **zoeiro, escrachado e honesto**. Não é blog corporativo. Não é documentação técnica. É uma pessoa real falando de um assunto técnico como falaria para um colega de trabalho que também já perdeu sono por causa de YAML.

**O que isso significa na prática:**

- Começa com uma situação que o leitor reconhece — a dor, o contexto, o momento antes da decisão
- Usa ironia e auto-depreciação sem medo — o autor sabe do que está falando, mas não precisa soar importante
- Spoilers deliberados: anuncia o que vai doer antes de explicar por quê
- Analogias absurdas são bem-vindas quando iluminam o conceito
- Humor não é enfeite — é o mecanismo que mantém o leitor acordado no meio de um bloco de código
- Profissionalismo não exclui personalidade. A área já é doída o suficiente.

**Exemplo de abertura canônica** (post do fish):

> Você estava feliz com seu `.bashrc` de 400 linhas que nem você entende mais.
> Aí alguém falou "cara, usa fish". E você pensou: *quanto pode custar?*
> Spoiler: custa sua sanidade por uns três dias e todos os seus scripts legados.

**O que evitar:**

- "Neste artigo, vamos explorar..." — não é TCC
- "É importante ressaltar que..." — você não é o seu gerente
- Conclusões genéricas do tipo "espero que tenha sido útil"
- Tom neutro demais — se deu sono em você escrever, vai dar no leitor

### Aplicação por tipo de conteúdo

| Tipo | Tom |
| :--- | :--- |
| TIL | Ultra direto. O que era, o que aprendi, o comando/conceito. Sem intro. |
| Blog técnico | Situação reconhecível → problema → solução → opinião honesta |
| Postmortem | Factual no que aconteceu, honesto no que falhou, sem culpa performática |
| Opinião | Tese clara logo no início, argumentos, sem "depende" genérico no final |

### Posts de referência

| Post | O que exemplifica |
| :--- | :--- |
| `2026-03-12-troquei-bash-zsh-por-fish.md` | Tom zoeiro, abertura com dor reconhecível, ironia como ferramenta |
| `2026-03-12-postgres-mvcc-vacuum-para-quem-vem-do-oracle.md` | Técnico denso sem virar documentação, narrativa comparativa, conclusão honesta sem motivacional |
