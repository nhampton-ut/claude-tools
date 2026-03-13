#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${1:-$(pwd)}"
CLAUDE_CONFIG="$HOME/.claude.json"
QDRANT_STORAGE="$HOME/.qdrant_storage"

echo "Setting up Qdrant RAG MCP for project: $PROJECT_PATH"
echo ""
echo "This script will:"
echo "  1. Install Podman (if needed) and start a Qdrant container"
echo "  2. Install uv/uvx (if needed)"
echo "  3. Add the Qdrant MCP server entry to ~/.claude.json for this project"
echo ""
read -rp "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Step 1: Podman + Qdrant
if ! command -v podman &>/dev/null; then
  echo "Installing Podman..."
  brew install podman
fi

if ! podman machine list 2>/dev/null | grep -q "Currently running"; then
  echo "Initializing and starting Podman machine..."
  podman machine init 2>/dev/null || true
  podman machine start
fi

mkdir -p "$QDRANT_STORAGE"

if ! podman ps --filter "name=qdrant" --format "{{.Names}}" | grep -q "qdrant"; then
  echo "Starting Qdrant container..."
  podman run -d --name qdrant \
    -p 6333:6333 \
    -v "$QDRANT_STORAGE:/qdrant/storage" \
    qdrant/qdrant
else
  echo "Qdrant container already running."
fi

# Step 2: uv / uvx
if ! command -v uvx &>/dev/null && [ ! -f "$HOME/.local/bin/uvx" ]; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

UVX_PATH="${HOME}/.local/bin/uvx"

# Step 3: Add Qdrant MCP server to ~/.claude.json
if [ ! -f "$CLAUDE_CONFIG" ]; then
  echo "Error: $CLAUDE_CONFIG not found. Open Claude Code at least once first."
  exit 1
fi

echo "Updating $CLAUDE_CONFIG..."

jq --arg path "$PROJECT_PATH" \
   --arg uvx "$UVX_PATH" \
  '.projects[$path].mcpServers.qdrant = {
    "type": "stdio",
    "command": $uvx,
    "args": ["mcp-server-qdrant"],
    "env": {
      "QDRANT_URL": "http://localhost:6333",
      "COLLECTION_NAME": "claude_docs",
      "EMBEDDING_MODEL": "sentence-transformers/all-MiniLM-L6-v2"
    }
  }' "$CLAUDE_CONFIG" > "${CLAUDE_CONFIG}.tmp" && mv "${CLAUDE_CONFIG}.tmp" "$CLAUDE_CONFIG"

echo ""
echo "Done! Verify setup:"
echo "  Qdrant dashboard: http://localhost:6333/dashboard"
echo "  MCP server:       run /mcp in Claude Code"
