# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RAGFlow is an open-source Retrieval-Augmented Generation (RAG) engine combining deep document understanding with Agent capabilities. It's a full-stack application with:
- **Backend**: Python-based RAG engine with Flask API server
- **Frontend**: React/TypeScript web UI built with UmiJS
- **Dependencies**: Elasticsearch/Infinity, MySQL, MinIO, Redis
- **Deployment**: Docker-based with optional Kubernetes/Helm support

## Development Setup

### Backend Development (Python)

**Prerequisites:**
- Python 3.10-3.12
- `uv` package manager (`pipx install uv`)
- `pre-commit` (`pipx install pre-commit`)

**Initial Setup:**
```bash
# Install dependencies
uv sync --python 3.10 --all-extras
uv run download_deps.py
pre-commit install

# Start dependent services (PostgreSQL, Redis, MinIO, ES/Infinity)
docker compose -f docker/docker-compose-base.yml up -d

# Add to /etc/hosts for local development
127.0.0.1  es01 infinity postgres mysql minio redis sandbox-executor-manager

# If accessing HuggingFace is blocked, use mirror
export HF_ENDPOINT=https://hf-mirror.com

# Install jemalloc if not present (macOS: brew install jemalloc)

# Activate virtual environment and launch backend
source .venv/bin/activate
export PYTHONPATH=$(pwd)
bash docker/launch_backend_service.sh
```

**Backend runs:**
- API server: `api/ragflow_server.py` (Flask, default port 9380)
- Task executors: `rag/svr/task_executor.py` (configurable workers via `WS` env var)

**Stop backend:**
```bash
pkill -f "ragflow_server.py|task_executor.py"
```

### Frontend Development (React/TypeScript)

**Prerequisites:**
- Node.js >= 18.20.4
- npm

**Setup and Run:**
```bash
cd web
npm install
npm run dev  # Development server with hot reload
```

**Production Build:**
```bash
npm run build
```

### Testing

**Python Tests:**
```bash
# Run pytest with coverage
pytest --no-cache --coverage

# Test markers available: p1 (high), p2 (medium), p3 (low priority)
pytest -m p1
```

**Frontend Tests:**
```bash
cd web
npm run test        # Run Jest tests
npm run lint        # ESLint check
```

### Code Quality

**Python:**
- Linting/formatting: `ruff` (configured in `pyproject.toml`, line-length: 200)
- Pre-commit hooks: YAML/JSON validation, EOF fixing, trailing whitespace, ruff auto-fix
- Run: `pre-commit run --all-files`

**Frontend:**
- Linting: ESLint via `umi lint --eslint-only`
- Formatting: Prettier (runs on staged files via lint-staged)

## Architecture Overview

### Backend Structure

**Core Modules:**
- `api/`: Flask API server, database models (Peewee ORM), endpoints, authentication
  - `api/ragflow_server.py`: Main Flask application entry point
  - `api/apps/`: API route handlers (datasets, documents, chats, agents, etc.)
  - `api/db/`: Database models, migrations, services
- `rag/`: Core RAG engine components
  - `rag/app/`: RAG application logic (retrieval, generation)
  - `rag/llm/`: LLM integrations (OpenAI, DeepSeek, Anthropic, etc.)
  - `rag/nlp/`: NLP utilities (tokenization, embeddings)
  - `rag/utils/`: Utility modules (Redis, ES/Infinity connectors, MCP tools)
- `deepdoc/`: Document parsing and layout analysis
  - `deepdoc/parser/`: Format-specific parsers (PDF, DOCX, Excel, PPT, Markdown, etc.)
  - `deepdoc/vision/`: Vision models for document understanding
- `agent/`: Agentic workflow system
  - `agent/component/`: Agent components (retrieval, generation, tools)
  - `agent/canvas.py`: Agent workflow orchestration
  - `agent/templates/`: Pre-built agent templates
- `graphrag/`: Graph-based RAG (knowledge graph construction)
- `sandbox/`: Code executor sandbox environment (gVisor-based)
- `mcp/`: Model Context Protocol server implementation

**Configuration:**
- `docker/.env`: Docker environment variables (ports, passwords, image versions)
- `docker/service_conf.yaml.template`: Backend service configuration (databases, LLM defaults, OAuth)
- `pyproject.toml`: Python dependencies, project metadata, tool configs

### Frontend Structure

**Key Directories:**
- `web/src/pages/`: Page components (chat, knowledge base, agent canvas, etc.)
- `web/src/components/`: Reusable UI components (Radix UI, Ant Design)
- `web/src/hooks/`: Custom React hooks
- `web/src/layouts/`: Layout components and routing
- `web/src/locales/`: i18n translations (multiple languages supported)
- `web/src/constants/`: Constants and configuration

**Framework:**
- UmiJS (React framework) with TypeScript
- State management: Zustand
- UI libraries: Ant Design Pro Components, Radix UI, Tailwind CSS
- Data fetching: @tanstack/react-query
- Routing: UmiJS built-in routing (see `web/src/routes.ts`)

## Docker Deployment

**Quick Start:**
```bash
cd docker

# CPU-only deployment
docker compose -f docker-compose.yml up -d

# GPU-accelerated (NVIDIA)
docker compose -f docker-compose-gpu.yml up -d

# Check server status
docker logs -f ragflow-server
```

**Docker Images:**
- `infiniflow/ragflow:v0.20.5`: Full image (~9GB) with embedding models
- `infiniflow/ragflow:v0.20.5-slim`: Slim image (~2GB) without embedding models
- `nightly`/`nightly-slim`: Unstable nightly builds

**Configuration Files:**
- `docker/.env`: Environment variables (ports, credentials, image selection)
- `docker/service_conf.yaml.template`: Service configuration template
- `docker/docker-compose.yml`: Main compose file
- `docker/docker-compose-base.yml`: Standalone services only (dev setup)

**Switching Document Store:**
To switch from Elasticsearch to Infinity:
```bash
docker compose -f docker/docker-compose.yml down -v  # Warning: deletes data
# Edit docker/.env: set DOC_ENGINE=infinity
docker compose -f docker-compose.yml up -d
```

## Common Development Tasks

### Adding a New Document Parser

1. Create parser in `deepdoc/parser/<format>_parser.py`
2. Inherit from base parser class
3. Implement chunking logic following template-based chunking patterns
4. Register parser in parser factory
5. Add tests in `test/` directory

### Adding LLM Integration

1. Create LLM client in `rag/llm/<provider>.py`
2. Implement chat and embedding interfaces
3. Add configuration to `docker/service_conf.yaml.template`
4. Update `user_default_llm` factory options in config docs

### Adding Agent Tool

1. Create tool in `agent/tools/<tool_name>.py`
2. Define tool schema and execution logic
3. Register in `agent/tools/__init__.py`
4. Add corresponding frontend component if needed

### Working with MCP (Model Context Protocol)

- MCP server implementation: `mcp/server/`
- MCP tool utilities: `rag/utils/mcp_tool_call_conn.py`
- Supports external tool integrations and agentic workflows

## Database

- **ORM**: Peewee (models in `api/db/db_models.py`)
- **Database**: PostgreSQL (default) or MySQL (configurable via `DB_TYPE` env var)
- **Migrations**: Manual migration scripts in `api/db/`
- **Services**: Database service layer in `api/db/services/`

### Switching Between PostgreSQL and MySQL

**Default**: PostgreSQL (recommended for production)

To use MySQL instead:
1. Edit `docker/.env`: Set `DB_TYPE=mysql`
2. The system will automatically use MySQL configuration from `service_conf.yaml.template`

**PostgreSQL** (default):
- Port: 5433 (host) → 5432 (container)
- Database: rag_flow
- User: rag_flow
- Extensions: uuid-ossp, pg_trgm

**MySQL** (alternative):
- Port: 5455 (host) → 3306 (container)
- Database: rag_flow
- User: root
- Character set: utf8mb4

## Key Environment Variables

**Backend:**
- `PYTHONPATH`: Set to project root
- `HF_ENDPOINT`: HuggingFace mirror (optional)
- `NLTK_DATA`: NLTK data directory (default: `./nltk_data`)
- `WS`: Number of task executor workers (default: 1)

**Docker:**
- `RAGFLOW_IMAGE`: Docker image tag selection
- `SVR_HTTP_PORT`: Host port for RAGFlow HTTP API (default: 9380)
- `DB_TYPE`: Database type (`postgres` (default) or `mysql`)
- `POSTGRES_PASSWORD`, `MYSQL_PASSWORD`, `MINIO_PASSWORD`, `REDIS_PASSWORD`: Service credentials
- `DOC_ENGINE`: Document storage backend (`elasticsearch` or `infinity`)

## Build Custom Docker Images

**Slim image (~2GB):**
```bash
docker build --platform linux/amd64 --build-arg LIGHTEN=1 -f Dockerfile -t infiniflow/ragflow:custom-slim .
```

**Full image with embeddings (~9GB):**
```bash
docker build --platform linux/amd64 -f Dockerfile -t infiniflow/ragflow:custom .
```

## Important Implementation Details

### Document Processing Pipeline
1. File upload → MinIO storage
2. Format detection → Parser selection (deepdoc/parser/)
3. Layout analysis → Vision models (deepdoc/vision/)
4. Template-based chunking → Chunk generation
5. Embedding → Vector storage (ES/Infinity)
6. Indexing → Full-text + vector search ready

### RAG Workflow
1. Query processing → NLP preprocessing (rag/nlp/)
2. Retrieval → Hybrid search (keyword + vector)
3. Re-ranking → Fusion and relevance scoring
4. Context assembly → Chunk aggregation
5. LLM generation → Answer with citations

### Agent System
- Canvas-based workflow (agent/canvas.py)
- Component-based architecture (retrieval, generation, tools)
- Template system for pre-built agent patterns
- MCP integration for external tool calling

## Testing Strategy

- Unit tests: Individual component testing
- Integration tests: API endpoint testing (test/testcases/)
- SDK tests: Python SDK validation (test/testcases/test_sdk_api/)
- Frontend tests: Component testing with Jest + React Testing Library
- Priority markers: p1 (critical), p2 (important), p3 (nice-to-have)

## Security Considerations

- OAuth2/OIDC integration supported (configure in service_conf.yaml)
- API key management for LLM providers
- Sandbox execution for code (gVisor required)
- HTTPS configuration available (see docker/README.md)

## Documentation

- Main docs: https://ragflow.io/docs/dev/
- API reference: Generated via Flasgger (OpenAPI/Swagger)
- Frontend Storybook: `npm run storybook` (port 6006)