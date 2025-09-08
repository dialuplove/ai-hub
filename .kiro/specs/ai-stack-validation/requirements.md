# Requirements Document

## Introduction

This feature implements a comprehensive validation and hardening system for the AI-Hub stack, which consists of Ollama, vLLM, LiteLLM Gateway, Open WebUI, and monitoring services (Dozzle, cAdvisor). The system must be WSL-friendly, avoiding GPU probing while ensuring all services are properly configured, healthy, and ready for production use. The validation process will detect the runtime environment, perform configuration hygiene checks, validate service health through HTTP endpoints, and generate a comprehensive status report.

## Requirements

### Requirement 1

**User Story:** As a developer running AI-Hub on WSL, I want the validation system to automatically detect WSL environment and skip GPU-specific tests, so that I can validate my stack without GPU hardware dependencies.

#### Acceptance Criteria

1. WHEN the system starts validation THEN it SHALL check `/proc/sys/kernel/osrelease` for "microsoft" to detect WSL
2. IF WSL is detected THEN the system SHALL skip all nvidia-smi commands and GPU device probing
3. IF WSL is detected THEN the system SHALL validate GPU configuration intent in docker-compose.yml without testing actual GPU access
4. WHEN WSL mode is active THEN the system SHALL log "WSL mode: GPU tests skipped" in all reports

### Requirement 2

**User Story:** As a DevOps engineer, I want the system to validate and fix configuration hygiene issues, so that sensitive data is protected and configurations are properly maintained.

#### Acceptance Criteria

1. WHEN validation runs THEN the system SHALL check for existence of `.gitignore` file
2. IF `.gitignore` is missing THEN the system SHALL create it with entries for `data/`, `config/litellm.yaml`, `**/.env`, and `keys`
3. WHEN validation runs THEN the system SHALL ensure `config/litellm.sample.yaml` exists and is sanitized
4. IF sample config is missing THEN the system SHALL create it from live config with all secrets replaced with placeholders
5. WHEN validating vLLM configuration THEN the system SHALL ensure `api_key: "EMPTY"` is present in litellm.yaml vLLM model blocks
6. IF vLLM api_key is missing THEN the system SHALL add it automatically

### Requirement 3

**User Story:** As a system administrator, I want the validation system to bring up the entire stack in an idempotent manner, so that services are running without unnecessary restarts.

#### Acceptance Criteria

1. WHEN stack deployment is requested THEN the system SHALL run `docker compose pull && docker compose up -d`
2. WHEN services are already running THEN the system SHALL NOT restart them unnecessarily
3. IF a service needs configuration changes THEN the system SHALL restart only that specific service
4. WHEN deployment completes THEN all 6 services SHALL be in running state (ai-ollama, ai-vllm, ai-litellm, ai-openwebui, ai-dozzle, ai-cadvisor)

### Requirement 4

**User Story:** As an AI developer, I want the system to ensure all required Ollama models are available, so that my applications can use the expected models without failures.

#### Acceptance Criteria

1. WHEN model validation runs THEN the system SHALL check for `gemma3:4b-instruct-q4_K_M`, `llama3.1:8b-instruct-q4_K_M`, and `qwen2.5:7b-instruct-q4_K_M`
2. IF any model is missing THEN the system SHALL run `ollama pull` for that specific model
3. WHEN all models are pulled THEN the system SHALL verify they appear in `ollama list` output
4. IF model pulling fails THEN the system SHALL report the failure with remediation hints

### Requirement 5

**User Story:** As a service operator, I want comprehensive health checks for all stack components using HTTP endpoints, so that I can verify the entire system is functional without relying on GPU-specific diagnostics.

#### Acceptance Criteria

1. WHEN health checks run THEN the system SHALL test intra-container connectivity from LiteLLM to Ollama (`http://ollama:11434`) and vLLM (`http://vllm:8000/v1/models`)
2. WHEN gateway validation runs THEN the system SHALL test `GET http://localhost:4000/v1/models` and expect a "data" array response
3. WHEN chat completion testing runs THEN the system SHALL test both Ollama route (`gemma3-4b-q4`) and vLLM route (`gemma3-4b-it`) via POST to `/v1/chat/completions`
4. WHEN monitoring validation runs THEN the system SHALL test Dozzle (`http://127.0.0.1:9999`) and cAdvisor (`http://127.0.0.1:9100`) accessibility
5. IF any HTTP check fails THEN the system SHALL restart the specific service once and retry
6. IF service still fails after restart THEN the system SHALL capture last 50 log lines and provide remediation hint

### Requirement 6

**User Story:** As a system administrator, I want a comprehensive status report after validation, so that I can quickly understand the health and configuration of my AI stack.

#### Acceptance Criteria

1. WHEN validation completes THEN the system SHALL generate a table showing all services with their status and ports
2. WHEN validation completes THEN the system SHALL list all available models from `GET /v1/models`
3. WHEN validation completes THEN the system SHALL provide one-line excerpts from successful chat completions for both Ollama and vLLM routes
4. WHEN validation completes THEN the system SHALL report docker-compose file path and disk usage of `data/` directory
5. WHEN validation completes THEN the system SHALL display "✅ Ready (WSL mode: GPU tests skipped)" for successful WSL validation
6. IF any critical component fails THEN the system SHALL display clear error status with specific remediation steps

### Requirement 7

**User Story:** As a security-conscious developer, I want the validation system to respect security boundaries and avoid making unauthorized changes, so that my system remains secure and stable.

#### Acceptance Criteria

1. WHEN validation runs THEN the system SHALL NOT run nvidia-smi or assert GPU isolation in WSL
2. WHEN validation runs THEN the system SHALL keep Ollama internal-only with no host binding on port 11434
3. WHEN validation runs THEN the system SHALL NOT modify files outside the ai-hub directory
4. WHEN configuration fixes are needed THEN the system SHALL make only minimal edits necessary for vLLM backend key and sample config
5. WHEN validation runs THEN the system SHALL preserve existing working configurations unless they contain critical errors