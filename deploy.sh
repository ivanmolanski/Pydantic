#!/bin/bash

# Simple deployment script for Pydantic MCP Server

set -e

echo "🚀 Pydantic MCP Server Deployment Script"
echo "======================================="

# Check if API key is provided
if [ -z "$MCP_API_KEY" ]; then
    echo "⚠️  Warning: MCP_API_KEY not set. Server will run in development mode."
    echo "   For production, export MCP_API_KEY=your-secure-api-key"
    echo ""
fi

# Default configuration
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-"8001"}

echo "Configuration:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  Auth: $([ -n "$MCP_API_KEY" ] && echo "Enabled" || echo "Development mode")"
echo ""

# Check Python version
python_version=$(python3 --version 2>/dev/null || echo "Not found")
echo "Python: $python_version"

if [[ "$python_version" == "Not found" ]]; then
    echo "❌ Python 3 is required but not found"
    exit 1
fi

# Check dependencies
echo "Checking dependencies..."
if python3 -c "import mediapipe, duckduckgo_search, requests, beautifulsoup4" 2>/dev/null; then
    echo "✅ Dependencies installed"
else
    echo "📦 Installing dependencies..."
    pip install -e .
fi

# Start server based on available options
echo ""
echo "🎯 Starting server..."

# Try the simple HTTP server first
if python3 -c "from src.mcp_local_rag.simple_http_server import run_server" 2>/dev/null; then
    echo "Using simple HTTP server implementation"
    export HOST PORT MCP_API_KEY
    exec python3 -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
else
    echo "❌ Failed to import simple HTTP server"
    exit 1
fi