# Implementation Plan

- [ ] 1. Create WSL detection and GPU policy system
  - Implement WSL detection by checking `/proc/sys/kernel/osrelease` or `/proc/version` for "microsoft"
  - Create GPU policy that skips nvidia-smi and GPU device tests when WSL detected
  - Add logging that outputs "WSL mode: GPU tests skipped" when in WSL
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 2. Implement project structure validation
  - Validate canonical scaffold exists: `ai-hub/{docker-compose.yml, config/litellm.yaml, data/*}`
  - Check for deprecated `compose/` directory and warn if present
  - Ensure proper directory structure before proceeding with validation
  - _Requirements: 7.3_

- [ ] 3. Build configuration hygiene system
  - Create or validate `.gitignore` contains: `data/`, `config/litellm.yaml`, `**/.env`, `keys`
  - Ensure `config/litellm.sample.yaml` exists with secrets redacted (replace with placeholders)
  - Add `api_key: "EMPTY"` to vLLM model blocks in `config/litellm.yaml` if missing
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 4. Implement idempotent stack deployment
  - Execute `docker compose pull && docker compose up -d --no-recreate`
  - Restart only services that have configuration changes
  - Validate all 6 services are running: ai-ollama, ai-vllm, ai-litellm, ai-openwebui, ai-dozzle, ai-cadvisor
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 5. Create GPU affinity validation (WSL-aware)
  - Validate ai-ollama has `NVIDIA_VISIBLE_DEVICES=0` in docker-compose.yml
  - Validate ai-vllm has `NVIDIA_VISIBLE_DEVICES=1` in docker-compose.yml
  - Skip actual GPU device testing if WSL mode is detected
  - _Requirements: 1.2, 1.3_

- [ ] 6. Build Ollama model management system
  - Check for required models: `gemma3:4b-instruct-q4_K_M`, `llama3.1:8b-instruct-q4_K_M`, `qwen2.5:7b-instruct-q4_K_M`
  - Execute `docker exec ai-ollama ollama pull <model>` for missing models
  - Verify models appear in `docker exec ai-ollama ollama list` output
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 7. Implement intra-container health checks
  - Test LiteLLM → Ollama connectivity: `http://ollama:11434` from ai-litellm container
  - Test LiteLLM → vLLM connectivity: `http://vllm:8000/v1/models` from ai-litellm container
  - Execute health checks using `docker exec ai-litellm wget -qO-` commands
  - _Requirements: 5.1_

- [ ] 8. Create gateway and API validation system
  - Test `GET http://localhost:4000/v1/models` returns data array
  - Test `POST /v1/chat/completions` with Ollama route (`gemma3-4b-q4`)
  - Test `POST /v1/chat/completions` with vLLM route (`gemma3-4b-it`)
  - Validate both routes return non-empty choices in response
  - _Requirements: 5.2, 5.3_

- [ ] 9. Build monitoring service validation
  - Test OpenWebUI accessibility (port 8080 or configured port)
  - Test Dozzle accessibility: `HEAD http://127.0.0.1:9999`
  - Test cAdvisor accessibility: `HEAD http://127.0.0.1:9100`
  - Mark monitoring checks as non-blocking (warn but don't fail)
  - _Requirements: 5.4_

- [ ] 10. Implement failure handling and retry logic
  - On health check failure: restart specific service once using `docker compose restart <service>`
  - Retry failed health check up to 60 seconds with 5-second intervals
  - Capture `docker logs --tail=50 <container>` for persistent failures
  - Provide remediation hints for common failure scenarios
  - _Requirements: 5.5, 5.6_

- [ ] 11. Create comprehensive status reporting system
  - Generate service table: name, status, GPU assignment, ports, uptime
  - List available models from `GET /v1/models` endpoint
  - Show sample chat completion excerpts from both Ollama and vLLM routes
  - Report docker-compose file path and disk usage of `data/` directory
  - Display final status with WSL mode notation if applicable
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 12. Implement security boundary enforcement
  - Fail validation if Ollama is published on host port 11434
  - Restrict all file modifications to within ai-hub directory
  - Prevent execution of nvidia-smi or GPU probing commands in WSL
  - Ensure minimal configuration changes (only add missing api_key)
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 13. Create main validation script
  - Build executable script that implements the complete smoke test workflow
  - Integrate all validation phases in proper sequence
  - Add command-line options for verbose output and specific test selection
  - Output final "✅ Ready (WSL mode: GPU tests skipped)" or failure status
  - _Requirements: All requirements integration_