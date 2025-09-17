#!/bin/bash

# One-liner MCP Server Installation
# Usage: curl -sSL https://raw.githubusercontent.com/ivanmolanski/Pydantic/main/install_mcp.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/ivanmolanski/Pydantic/main"

echo "🚀 Installing Pydantic MCP Server..."
echo "===================================="
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: This script must be run from the root of a git repository"
    echo "   Navigate to your target repository and run this script again"
    exit 1
fi

# Download and run the full setup script
echo "📥 Downloading setup script..."
curl -sSL "$REPO_URL/setup_mcp_server.sh" -o setup_mcp_server.sh
chmod +x setup_mcp_server.sh

echo "🚀 Running setup..."
./setup_mcp_server.sh

# Cleanup
rm setup_mcp_server.sh

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Quick start:"
echo '1. export MCP_API_KEY="$(grep -o "mcp_[^\"]*" github-mcp-config.json | head -1)"'
echo '2. python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"'
echo ""
echo "For deployment and configuration, see the generated documentation files."