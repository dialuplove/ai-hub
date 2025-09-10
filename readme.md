# AI-Hub

A containerized AI serving stack for **HulaGirl**, built on:

- **Ollama** (local models)
- **vLLM** (optimized OpenAI-compatible engine)
- **LiteLLM Gateway** (unified OpenAI-style API)
- **Open WebUI** (browser interface)
- **Dozzle & cAdvisor** (lightweight monitoring)

## Quickstart

```bash
git clone https://github.com/dialuplove/ai-hub.git
cd ai-hub

# bring up stack + run validation
./validate.sh
