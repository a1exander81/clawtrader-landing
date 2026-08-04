#!/bin/bash
set -euo pipefail

DRYRUN="${DRYRUN:-1}"
STAMP=$(date -u +%Y%m%d_%H%M%S)

echo "=== DeepSeek content cleanup (DRYRUN=$DRYRUN) ==="

patch_file() {
  local file="$1"
  local py_script="$2"
  if [ ! -f "$file" ]; then
    echo "ABORT: $file not found"
    exit 1
  fi
  cp "$file" "${file}.bak.pre-deepseek-cleanup-${STAMP}"
  python3 "$py_script" "$file" "$DRYRUN"
}

cat > /tmp/patch_index.py << 'PYEOF'
import sys
path, dryrun = sys.argv[1], sys.argv[2] == "1"
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ('engine: DeepSeek SMC · exchange: bybit',
     'engine: Living Card SMC · exchange: bybit'),
    ('The bot uses a configurable AI engine for SMC/ICT reasoning across 3 timeframes (4H trend, 1H Order Block, 15M displacement). News context from CoinTelegraph, Decrypt, and CryptoPanic is fed into every scan. Supported providers include DeepSeek, Claude, and OpenAI — you choose.',
     'The bot runs a deterministic SMC/ICT engine — 4H bias, 1H agreement, 5M confirmation — with a strict R:R gate before any setup ever reaches your Telegram card. No discretionary AI model picks the trade.'),
]

applied = 0
for old, new in replacements:
    count = content.count(old)
    if count == 0:
        print(f"SKIP (already applied or anchor missing): {old[:60]!r}")
        continue
    if count != 1:
        print(f"ABORT: expected 1 match, got {count} for: {old[:60]!r}")
        sys.exit(1)
    content = content.replace(old, new)
    applied += 1

if dryrun:
    print(f"[DRYRUN] index.html: {applied} replacement(s) would apply")
else:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"index.html: {applied} replacement(s) applied")
PYEOF

cat > /tmp/patch_dashboard.py << 'PYEOF'
import sys
path, dryrun = sys.argv[1], sys.argv[2] == "1"
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ('Clawmimoto ICT/SMC · DeepSeek L1/L2/L3 · <span id="trade-count">—</span> closed trades',
     'Clawmimoto ICT/SMC · Living Card Engine · <span id="trade-count">—</span> closed trades'),
    ('<span class="strat-key">Engine</span><span class="strat-val">DeepSeek L1/L2/L3</span>',
     '<span class="strat-key">Engine</span><span class="strat-val">Living Card (4H→1H→5M)</span>'),
]

applied = 0
for old, new in replacements:
    count = content.count(old)
    if count == 0:
        print(f"SKIP (already applied or anchor missing): {old[:60]!r}")
        continue
    if count != 1:
        print(f"ABORT: expected 1 match, got {count} for: {old[:60]!r}")
        sys.exit(1)
    content = content.replace(old, new)
    applied += 1

if dryrun:
    print(f"[DRYRUN] dashboard.html: {applied} replacement(s) would apply")
else:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"dashboard.html: {applied} replacement(s) applied")
PYEOF

patch_file "index.html" /tmp/patch_index.py
patch_file "dashboard.html" /tmp/patch_dashboard.py

if [ "$DRYRUN" = "1" ]; then
  echo ""
  echo "=== DRYRUN complete. Re-run with DRYRUN=0 ./apply_deepseek_cleanup.sh to apply. ==="
  # remove the backups made during dryrun since nothing changed
  rm -f "index.html.bak.pre-deepseek-cleanup-${STAMP}" "dashboard.html.bak.pre-deepseek-cleanup-${STAMP}"
else
  echo ""
  echo "=== Applied. Backups: *.bak.pre-deepseek-cleanup-${STAMP} ==="
fi
