
---

### `validate.sh` (skeleton)
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "🔍 AI-Hub Validation Starting..."

# 1. Detect WSL
if grep -qi microsoft /proc/sys/kernel/osrelease; then
  echo "⚠️  WSL mode detected – GPU tests skipped"
  WSL_MODE=true
else
  WSL_MODE=false
fi

# 2. Config hygiene
[ -f .gitignore ] || {
  echo "→ creating .gitignore"
  cat > .gitignore <<EOF
data/
config/litellm.yaml
**/.env
keys
EOF
}

[ -f config/litellm.sample.yaml ] || {
  echo "→ creating config/litellm.sample.yaml (sanitized)"
  cp config/litellm.yaml config/litellm.sample.yaml
  sed -i 's/api_key:.*/api_key: "EMPTY"/g' config/litellm.sample.yaml || true
}

# 3. Compose up (idempotent)
docker compose pull
docker compose up -d

# 4. Health checks
echo "→ checking gateway models..."
curl -s http://localhost:4000/v1/models | jq .

echo "→ sample chat (Ollama route)..."
curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma3-4b-q4","messages":[{"role":"user","content":"ping"}]}' | jq .

echo "→ sample chat (vLLM route)..."
curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma3-4b-it","messages":[{"role":"user","content":"ping"}]}' | jq .

# 5. Final status
echo "✅ Validation complete"
$WSL_MODE && echo "(WSL mode: GPU tests skipped)"
