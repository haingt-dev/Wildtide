#!/usr/bin/env bash
# Start all MCP Podman containers used by Kilo Code in detached mode.
# Safe to run multiple times (idempotent) — skips already-running containers.
# Companion script: mcp-stop.sh

set -euo pipefail

# Container name → image mapping
declare -A MCP_CONTAINERS=(
  ["mcp-godot-docs"]="localhost/godot-docs-mcp:latest"
  ["mcp-context7"]="localhost/context7-mcp:latest"
)

started=0
skipped=0

for name in "${!MCP_CONTAINERS[@]}"; do
  image="${MCP_CONTAINERS[$name]}"

  # Check if a container with this name is already running
  if podman ps --filter "name=^${name}$" --format "{{.ID}}" 2>/dev/null | grep -q .; then
    echo "[skip] ${name} is already running (${image})"
    ((skipped++)) || true
    continue
  fi

  # Remove any stopped container with the same name (shouldn't exist with --rm, but just in case)
  podman rm -f "$name" >/dev/null 2>&1 || true

  echo "[start] Starting ${name} (${image})..."
  if podman run -d --rm -i --name "$name" "$image" >/dev/null 2>&1; then
    echo "[done] ${name} started."
    ((started++)) || true
  else
    echo "[error] Failed to start ${name} (${image})"
  fi
done

echo ""
echo "Finished. Started ${started}, skipped ${skipped} MCP container(s)."
