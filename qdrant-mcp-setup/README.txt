Scripts
=======

setup-qdrant-mcp.sh
-------------------
Sets up a Qdrant vector database RAG and connects it to Claude Code via MCP.

Usage:
  bash ~/.claude/scripts/setup-qdrant-mcp.sh [project-path]

  project-path  Path to the Claude Code project to register the MCP server for.
                Defaults to the current working directory.

Example:
  bash ~/.claude/scripts/setup-qdrant-mcp.sh ~/Source/ruby/rails-server

What it does:
  1. Installs Podman (via Homebrew) if not present, initializes and starts the
     Podman machine, then runs a Qdrant container on port 6333 with storage at
     ~/.qdrant_storage.
  2. Installs uv/uvx (via astral.sh) if not present.
  3. Adds the Qdrant MCP server entry to ~/.claude.json under the given project,
     using the mcp-server-qdrant package with the sentence-transformers embedding
     model and a "claude_docs" collection.

After running:
  - Verify Qdrant is up:  http://localhost:6333/dashboard
  - Verify MCP connected: run /mcp inside Claude Code

Notes:
  - Requires jq (ships with macOS, or: brew install jq)
  - The Qdrant container must be running for the MCP server to work. If you
    restart your machine, run: podman machine start && podman start qdrant
