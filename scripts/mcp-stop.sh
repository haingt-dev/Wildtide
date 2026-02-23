#!/usr/bin/env bash
# Stop all running MCP Podman containers used by Kilo Code.
# Safe to run multiple times (idempotent). Containers use --rm,
# so stopping them also removes them automatically.
# Companion script: mcp-start.sh

set -euo pipefail

MCP_CONTAINERS=(
  "mcp-godot-docs"
  "mcp-context7"
)

stopped=0

for name in "${MCP_CONTAINERS[@]}"; do
  # Check if a container with this name is running
  if ! podman ps --filter "name=^${name}$" --format "{{.ID}}" 2>/dev/null | grep -q .; then
    echo "[skip] ${name} is not running"
    continue
  fi

  echo "[stop] Stopping ${name}..."
  if podman stop "$name" >/dev/null 2>&1; then
    echo "[done] ${name} stopped."
    ((stopped++)) || true
  else
    echo "[warn] Failed to stop ${name} — it may have already exited."
  fi
done

echo ""
echo "Finished. Stopped ${stopped} MCP container(s)."
