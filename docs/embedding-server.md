# Embedding Server — nomic-embed-text v1.5

Local embedding server running on the GTX 1080 Ti (GPU 1) via llama.cpp. OpenAI-compatible API, no API key required.

## Endpoint

```
http://asus:8002/v1/embeddings
```

## Quick Test

```bash
curl http://asus:8002/v1/embeddings \
  -H 'Content-Type: application/json' \
  -d '{"input": "Hello world", "model": "nomic-embed-text"}'
```

## Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(base_url="http://asus:8002/v1", api_key="none")

response = client.embeddings.create(
    model="nomic-embed-text",
    input="search_document: Your text here"
)

print(response.data[0].embedding[:5])  # 768-dim vector
```

## Node.js (OpenAI SDK)

```javascript
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "http://asus:8002/v1", apiKey: "none" });

const response = await client.embeddings.create({
  model: "nomic-embed-text",
  input: "search_document: Your text here",
});

console.log(response.data[0].embedding.length); // 768
```

## Batch Embeddings

```bash
curl http://asus:8002/v1/embeddings \
  -H 'Content-Type: application/json' \
  -d '{"input": ["first document", "second document"], "model": "nomic-embed-text"}'
```

## Nomic Prefix Convention

For best results, prefix your input:

| Use case | Prefix |
|----------|--------|
| Indexing documents | `search_document: <text>` |
| Search queries | `search_query: <text>` |
| Clustering | `clustering: <text>` |
| Classification | `classification: <text>` |

## Specs

| Property | Value |
|----------|-------|
| Model | nomic-embed-text-v1.5 (F16 GGUF) |
| Dimensions | 768 |
| Max tokens | 2048 |
| GPU | GTX 1080 Ti (CUDA, ~400MB VRAM) |
| Parallel requests | 4 |
| Service | `nomic-embed.service` (auto-starts on boot) |
| Port | 8002 |
| API | OpenAI-compatible (`/v1/embeddings`) |

## Service Management

```bash
systemctl status nomic-embed       # status
journalctl -u nomic-embed -f       # logs
sudo systemctl restart nomic-embed # restart
curl http://asus:8002/health       # health check
```

## Infrastructure

Defined in `hosts/common/llamacpp.nix`. Model at `~/inference/models/nomic-embed/`. Launch script at `~/inference/scripts/nomic-embed`.

| GPU | Card | Service | Port |
|-----|------|---------|------|
| 0 | RTX 4090 (23GB) | Qwen 27B — LLM inference | 8001 |
| 1 | GTX 1080 Ti (11GB) | nomic-embed-text — embeddings | 8002 |
| 1 | GTX 1080 Ti (11GB) | faster-whisper — speech-to-text | — |
