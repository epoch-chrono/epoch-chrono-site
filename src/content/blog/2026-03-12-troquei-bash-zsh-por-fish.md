---
title: "Troquei bash/zsh por fish e agora meu shell tem opiniões"
description: "Tudo que quebra, tudo que muda e tudo que ninguém te avisa quando você decide largar o bash para um shell que acha que sabe mais que você."
pubDate: 2026-03-12
tags: ["fish", "shell", "linux", "tooling", "workflow"]
categories: ["tooling"]
draft: false
postVersion: "1.0.0"
---

Você estava feliz com seu `.bashrc` de 400 linhas que nem você entende mais.
Tinha uns aliases, umas funções copiadas do Stack Overflow em 2014, um `export PATH` suspeito.
Funcionava. Mais ou menos. Na maior parte do tempo.

Aí alguém falou "cara, usa fish" e você foi lá olhar.
Autocompletion que funciona de verdade. Syntax highlighting em tempo real. Sem configuração.

E você pensou: *quanto pode custar?*

Spoiler: custa sua sanidade por uns três dias e todos os seus scripts legados.

---

## O que é o fish e por que ele é diferente de verdade

bash e zsh são POSIX-compatible. Isso significa que eles seguem um padrão de 1992 para garantir que scripts escritos quando você ainda usava fraldas ainda rodem hoje.

fish não é POSIX-compatible. Ele jogou o padrão no lixo e decidiu ser consistente, legível e sensato. Isso é ótimo para uso interativo. É péssimo para quem tem 10 anos de muscle memory em bash.

A promessa do fish é: **menos configuração, mais funcionalidade out-of-the-box**. E ele cumpre. O problema é o preço da transição.

---

## O que muda nos conceitos básicos

### Variáveis

No bash você define variável assim:

```bash
NOME="valor"
export NOME="valor"
```

No fish:

```fish
set nome "valor"
set -x nome "valor"  # -x é o export
```

Perceba: sem `$` na atribuição. Você vai errar isso umas 40 vezes antes de gravar.
E o nome da variável é case-sensitive mas por convenção vai tudo minúsculo no fish.

Esqueça `export VAR=valor`. Não existe. Não funciona. Vai dar erro silencioso ou não vai fazer nada dependendo do contexto. Use `set -x`.

Para variáveis de ambiente permanentes (equivalente a colocar no `.bashrc`):

```fish
set -Ux EDITOR hx  # -U = universal, persiste entre sessões
```

### Sem `$()` nem `${}`

Essa é a que mais dói.

No bash, substituição de comando é `$()`:

```bash
DATA=$(date +%Y-%m-%d)
UPPER=$(echo "$NOME" | tr '[:lower:]' '[:upper:]')
```

No fish, é `()` diretamente:

```fish
set data (date +%Y-%m-%d)
set upper (echo $nome | tr '[:lower:]' '[:upper:]')
```

E `${}` para manipulação de string? Não existe. Para slices, substituições e expansões de string você usa outras abordagens — o builtin `string`, pipes, ou aceita que vai ser diferente.

O builtin `string` do fish é surpreendentemente poderoso:

```fish
string upper $nome
string replace "foo" "bar" $texto
string split "," $lista
```

---

## Estruturas de controle

### if

Bash:

```bash
if [ "$VAR" = "valor" ]; then
  echo "sim"
fi
```

Fish:

```fish
if test $var = "valor"
  echo "sim"
end
```

Dois detalhes que vão te enlouquecer:

1. Sem `then`. Sem `fi`. Usa `end`.
2. Sem `[[ ]]` nem `[ ]`. Usa `test` ou a forma longa.

Comparações numéricas:

```fish
if test $n -gt 10
  echo "maior"
end
```

### for

Bash:

```bash
for i in 1 2 3; do
  echo $i
done
```

Fish:

```fish
for i in 1 2 3
  echo $i
end
```

Para ranges, fish tem `seq`:

```fish
for i in (seq 1 10)
  echo $i
end
```

### while

Bash:

```bash
while [ $i -lt 10 ]; do
  echo $i
  i=$((i + 1))
done
```

Fish:

```fish
while test $i -lt 10
  echo $i
  set i (math $i + 1)
end
```

Sim, tem `math` builtin. Sem `$(( ))`. Aritmética é `math`.

### switch/case

Isso o fish faz melhor que o bash. Juro.

```fish
switch $opcao
  case "start"
    echo "iniciando"
  case "stop"
    echo "parando"
  case "*"
    echo "opção inválida"
end
```

No bash o equivalente é uma abominação com `;;` e `esac` que parece que alguém estava bêbado quando inventou.

---

## Funções

Bash:

```bash
minha_funcao() {
  echo "argumento: $1"
}
```

Fish:

```fish
function minha_funcao
  echo "argumento: $argv[1]"
end
```

`$argv` é o array de argumentos. `$argv[1]` é o primeiro. Sem `$1`, `$2`, etc.

Para salvar a função permanentemente:

```fish
funcsave minha_funcao
# salva em ~/.config/fish/functions/minha_funcao.fish
```

Cada função fica num arquivo separado. É assim que o fish funciona. Você vai aprender a gostar.

---

## O problema do heredoc

Heredoc não existe no fish. Ponto final.

No bash você faz:

```bash
cat <<EOF
linha 1
linha 2
EOF
```

No fish, as alternativas são:

**printf:**

```fish
printf "linha 1\nlinha 2\n"
```

**echo com aspas:**

```fish
echo "linha 1
linha 2"
```

**printf com múltiplos argumentos:**

```fish
printf '%s\n' "linha 1" "linha 2" "linha 3"
```

A falta de heredoc dói especialmente quando você precisa gerar arquivos de configuração inline em scripts. A solução real é: aceita que scripts complexos continuam sendo bash, e fish é para uso interativo e funções simples.

---

## Arrays

No bash, arrays são uma piada de mau gosto:

```bash
arr=("a" "b" "c")
echo "${arr[0]}"
echo "${#arr[@]}"
for item in "${arr[@]}"; do echo $item; done
```

No fish, arrays são cidadãos de primeira classe:

```fish
set arr "a" "b" "c"
echo $arr[1]   # índice começa em 1, não 0. sim, você vai errar.
count $arr     # tamanho
for item in $arr
  echo $item
end
```

O índice começando em 1 vai te pegar. Sempre. Prepare-se.

---

## Configuração: sem `.bashrc`

No bash e zsh você joga tudo no `.bashrc` ou `.zshrc`.

No fish, a configuração fica em `~/.config/fish/config.fish`. Mas você raramente precisa mexer nele porque:

- Funções ficam em `~/.config/fish/functions/`
- Variáveis universais ficam no banco interno do fish (`set -U`)
- "Aliases" são funções — não tem `alias` de verdade

"Alias" no fish:

```fish
# bash: alias ll='ls -la'
# fish:
function ll
  ls -la $argv
end
funcsave ll
```

Tem um atalho com `alias -s` que salva direto:

```fish
alias -s ll 'ls -la'
```

---

## O que você não vai conseguir migrar

Seja honesto consigo mesmo: **scripts bash ficam bash**. Especialmente se:

- Usam heredoc extensivamente
- São chamados por sistemas externos (cron, CI, containers)
- Têm `#!/bin/bash` na primeira linha e precisam ficar portáveis

Fish é para sua experiência interativa no terminal. Para automação complexa, bash continua sendo a ferramenta certa.

A virada mental é: **fish = meu shell do dia a dia**, **bash = scripts que precisam funcionar em qualquer lugar**.

---

## O que você vai ganhar e nunca mais vai querer abrir mão

- Autocompletion baseado em man pages — funciona para qualquer comando, sem configuração
- Syntax highlighting em tempo real — comando que não existe fica vermelho antes de apertar Enter
- Sugestões inline do histórico — aperta `→` para aceitar
- `Alt+.` para reutilizar último argumento
- Sem `source ~/.bashrc` depois de cada mudança — fish recarrega funções automaticamente
- `fish_config` abre um painel web para configurar tema e prompt. Sim, painel web. No shell.

Depois de uma semana você não consegue mais usar bash no terminal sem sentir que está digitando no escuro.

---

## Resumo da migração

| Bash/Zsh | Fish |
| --- | --- |
| `export VAR=valor` | `set -x var valor` |
| `VAR=$(comando)` | `set var (comando)` |
| `${VAR}` | `$var` |
| `if [ ]; then ... fi` | `if test ...; end` |
| `for i in; do ... done` | `for i in; end` |
| `$((expr))` | `math expr` |
| `$1 $2 $@` | `$argv[1] $argv[2] $argv` |
| `source arquivo` | `source arquivo` ✓ igual |
| heredoc `<<EOF` | não existe — usa `printf` |
| `.bashrc` | `~/.config/fish/config.fish` |
| `alias x='...'` | `function x; ...; end` + `funcsave` |
| array base 0 | array base 1 (cuidado) |

---

A transição vai doer por uns dias. Você vai xingar. Vai voltar pro bash uma vez ou outra.

Depois de uma semana, você vai abrir um terminal bash em algum servidor e vai olhar pra ele com pena.

Vale a pena.
