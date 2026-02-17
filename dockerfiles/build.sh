#!/bin/bash
set -e

echo "Building Claude sandbox..."
cd claude-sandbox || {
  echo "claude-sandbox dir not found"
  exit 1
}
docker build -t local/claude-sb .

echo "Building Codex sandbox..."
cd ../codex-sandbox || {
  echo "codex-sandbox dir not found"
  exit 1
}
docker build -t local/codex-sb .

echo "✅ Build complete: local/claude-sb & local/codex-sb ready."
echo "Test: cd /your/project && claudesb"
