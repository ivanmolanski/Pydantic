#!/bin/bash

# One-liner MCP Server Installation
# Usage: curl -sSL https://raw.githubusercontent.com/ivanmolanski/Pydantic/main/install_mcp.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/ivanmolanski/Pydantic/main"

echo "🚀 Installing Pydantic MCP Server..."
echo "===================================="
echo ""

# Download and run the full setup script
curl -sSL "$REPO_URL/setup_mcp_server.sh" | bash

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Quick start:"
echo '1. export MCP_API_KEY="your-api-key"'
echo '2. python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"'
echo ""
echo "For deployment and configuration, see the generated documentation files."