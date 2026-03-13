---
title: "TIL: Importar MBOX do Google Takeout no Gmail free via IMAP + App Password"
pubDate: 2026-03-13
tags:
  - gmail
  - python
  - migration
draft: false
---

Ao migrar de Google Workspace para Gmail gratuito + Cloudflare Email Routing,
o histórico de emails vem pelo Google Takeout como arquivo `.mbox`.

O Thunderbird (ImportExportTools NG) trava com volumes grandes (~37k emails).
O GYB (Got Your Back) exige OAuth verification que contas pessoais não passam.

A solução mais simples: `imaplib` do Python + App Password do Gmail.

```python
#!/usr/bin/env python3
import mailbox
import imaplib
import email.utils
import time

MBOX_PATH = "./All_mail_Including_Spam_and_Trash.mbox"
IMAP_HOST = "imap.gmail.com"
EMAIL = "<seu email aqui>"
APP_PASSWORD = "xxxx xxxx xxxx xxxx"  # App Password da FASE 6

mbox = mailbox.mbox(MBOX_PATH)
total = len(mbox)
print(f"Total: {total} emails")

imap = imaplib.IMAP4_SSL(IMAP_HOST)
imap.login(EMAIL, APP_PASSWORD)
imap.select('"[Gmail]/All Mail"')

# Buscar Message-IDs já existentes
print("Buscando Message-IDs existentes no Gmail...")
_, data = imap.search(None, 'ALL')
existing_ids = set()
if data[0]:
    nums = data[0].split()
    print(f"Emails existentes: {len(nums)}")
    for i in range(0, len(nums), 500):
        batch = b','.join(nums[i:i+500])
        _, msgs = imap.fetch(batch, '(BODY.PEEK[HEADER.FIELDS (MESSAGE-ID)])')
        for item in msgs:
            if isinstance(item, tuple):
                mid = email.message_from_bytes(item[1]).get('Message-ID', '').strip()
                if mid:
                    existing_ids.add(mid)
    print(f"Message-IDs indexados: {len(existing_ids)}")

skipped = 0
uploaded = 0
errors = []
start_time = time.time()
last_report = start_time

for i, msg in enumerate(mbox):
    mid = msg.get('Message-ID', '').strip()
    if mid and mid in existing_ids:
        skipped += 1
    else:
        try:
            imap.append('"[Gmail]/All Mail"', None, None, msg.as_bytes())
            uploaded += 1
        except Exception as e:
            errors.append((i, str(e)))
            print(f"ERRO #{i}: {e}")

    now = time.time()
    if now - last_report >= 300:  # 5 minutos
        elapsed = now - start_time
        processed = i + 1
        remaining = total - processed
        rate = processed / elapsed * 60  # emails/min
        eta_min = remaining / (processed / elapsed) / 60 if processed > 0 else 0
        print(f"[{int(elapsed/60)}min] {processed}/{total} ({remaining} restam) | "
              f"Uploaded: {uploaded} | Skipped: {skipped} | Erros: {len(errors)} | "
              f"~{rate:.0f}/min | ETA: ~{eta_min:.0f}min")
        last_report = now

elapsed = time.time() - start_time
print(f"\nConcluído em {int(elapsed/60)}min. Uploaded: {uploaded} | Skipped: {skipped} | Erros: {len(errors)}")
```

Para evitar duplicatas em re-runs, indexar os `Message-ID` existentes
no Gmail antes do loop e pular os que já existem.

Pré-requisito: 2FA ativo na conta Gmail e App Password gerada
(Security → App passwords). Não precisa de OAuth client, GCP project,
nem ferramenta externa.
Depois é só curtir:

```plaintext
while true
        ./mbox-import.py
    end
Total: 37573 emails
Buscando Message-IDs existentes no Gmail...
Emails existentes: 32405
Message-IDs indexados: 32373
[5min] 32183/37573 (5390 restam) | Uploaded: 71 | Skipped: 32112 | Erros: 0 | ~6417/min | ETA: ~1min
[10min] 32275/37573 (5298 restam) | Uploaded: 163 | Skipped: 32112 | Erros: 0 | ~3220/min | ETA: ~2min
[15min] 32373/37573 (5200 restam) | Uploaded: 261 | Skipped: 32112 | Erros: 0 | ~2149/min | ETA: ~2min
[20min] 32476/37573 (5097 restam) | Uploaded: 364 | Skipped: 32112 | Erros: 0 | ~1615/min | ETA: ~3min
[25min] 32577/37573 (4996 restam) | Uploaded: 465 | Skipped: 32112 | Erros: 0 | ~1297/min | ETA: ~4min
[30min] 32681/37573 (4892 restam) | Uploaded: 569 | Skipped: 32112 | Erros: 0 | ~1085/min | ETA: ~5min
[35min] 32781/37573 (4792 restam) | Uploaded: 669 | Skipped: 32112 | Erros: 0 | ~933/min | ETA: ~5min
```
