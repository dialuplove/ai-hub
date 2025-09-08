#!/usr/bin/env bash
set -euo pipefail

API="http://localhost:4000/v1"
KEY="dev-local-key"
MODELS=("gemma3-4b-q4" "llama3.1-8b-q4" "qwen2.5-7b-q4")

echo "==> Checking /v1/models"
RESP="$(curl -s -H "Authorization: Bearer ${KEY}" "${API}/models" || true)"
echo "$RESP" | grep -q '"data"' && echo "OK: models endpoint up" || { echo "FAIL: /v1/models"; exit 2; }

echo "==> Probing chat completions"
FAIL=0
for M in "${MODELS[@]}"; do
  OUT="$(curl -s "${API}/chat/completions" \
    -H "Authorization: Bearer ${KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${M}\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hi in five words.\"}],\"max_tokens\":50}" \
    || true)"
  LINE="$(echo "$OUT" | grep -oE '"content":"[^"]{1,200}"' | head -n1 || true)"
  if [[ -n "$LINE" ]]; then
    echo "OK: ${M} → ${LINE}"
  else
    echo "FAIL: ${M}"
    FAIL=1
  fi
done

exit $FAIL
