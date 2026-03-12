#!/usr/bin/env fish
# bin/setup-buttondown.fish
# Aplica configurações de design e branding no Buttondown via API.
# Roda uma vez; idempotente.
#
# Uso:
#   ./bin/setup-buttondown.fish
#   ./bin/setup-buttondown.fish --dry-run
#
# Requer: BUTTONDOWN_API_KEY no ambiente (via .envrc)

set DRY_RUN false
if contains -- --dry-run $argv
    set DRY_RUN true
    echo "[dry-run] Nenhuma alteração será feita."
end

# ── Validar env ──────────────────────────────────────────────────────────────
if test -z "$BUTTONDOWN_API_KEY"
    echo "Erro: BUTTONDOWN_API_KEY não definida. Carregue o .envrc."
    exit 1
end

set BD_API "https://api.buttondown.email/v1"
set BD_KEY $BUTTONDOWN_API_KEY

# ── Buscar newsletter ID ─────────────────────────────────────────────────────
echo "Buscando newsletter..."
set NEWSLETTER_JSON (xh GET "$BD_API/newsletters" "Authorization:Token $BD_KEY" 2>/dev/null)
set NEWSLETTER_ID (echo $NEWSLETTER_JSON | python3 -c "import json,sys; print(json.load(sys.stdin)['results'][0]['id'])")

if test -z "$NEWSLETTER_ID"
    echo "Erro: não foi possível obter newsletter ID."
    exit 1
end

echo "Newsletter ID: $NEWSLETTER_ID"

# ── Payload ──────────────────────────────────────────────────────────────────
set PAYLOAD (python3 -c "
import json
print(json.dumps({
    'tint_color':  '#00c8e0',
    'description': 'Posts, TILs e notas de um SRE. Sem spam, sem frequência forçada.',
    'footer':      '— Vitor Jr · epoch-chrono.com\nSem spam, sem frequência forçada.',
    'timezone':    'America/Sao_Paulo',
    'locale':      'pt-BR',
    'template':    'modern',
}))
")

if $DRY_RUN
    echo "[dry-run] Payload que seria enviado:"
    echo $PAYLOAD | python3 -m json.tool
    exit 0
end

# ── PATCH ────────────────────────────────────────────────────────────────────
echo "Aplicando configurações..."
set RESULT (echo $PAYLOAD | xh PATCH "$BD_API/newsletters/$NEWSLETTER_ID" \
    "Authorization:Token $BD_KEY" \
    "Content-Type:application/json" \
    @- 2>/dev/null)

echo $RESULT | python3 -c "
import json, sys
d = json.load(sys.stdin)
if d.get('detail'):
    print('Erro:', d['detail'])
    sys.exit(1)
print('tint_color:  ', d.get('tint_color'))
print('template:    ', d.get('template'))
print('timezone:    ', d.get('timezone'))
print('locale:      ', d.get('locale'))
print('description: ', d.get('description','')[:60])
print('footer:      ', d.get('footer','')[:60])
print()
print('✓ Buttondown configurado.')
"

# ── Nota: CSS requer plano pago ──────────────────────────────────────────────
echo ""
echo "Nota: customização de CSS (campo 'css'/'web_css') requer plano Basic ou superior."
echo "      Com o plano free, tint_color (#00c8e0) é o único controle de cor disponível."
