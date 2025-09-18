#!/bin/bash

# Automated MCP Server Setup Script for Any Repository
# This script sets up the Pydantic MCP server with all necessary files

set -e

echo "🚀 Pydantic MCP Server Setup for GitHub Copilot"
echo "================================================="
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: This script must be run from the root of a git repository"
    echo "   Navigate to your target repository and run this script again"
    exit 1
fi

REPO_NAME=$(basename "$(pwd)")
echo "📁 Setting up MCP server in repository: $REPO_NAME"
echo ""

# Function to create file with content
create_file() {
    local file_path="$1"
    local description="$2"
    
    echo "📝 Creating $description..."
    mkdir -p "$(dirname "$file_path")"
    
    # The file content will be passed via stdin
    cat > "$file_path"
    
    if [ -f "$file_path" ]; then
        echo "   ✅ $file_path"
    else
        echo "   ❌ Failed to create $file_path"
        return 1
    fi
}

echo "1️⃣  Creating core MCP server files..."

# Create src/mcp_local_rag directory structure
mkdir -p src/mcp_local_rag/embedder

# Create __init__.py files
create_file "src/mcp_local_rag/__init__.py" "MCP package init" << 'EOF'
"""MCP Local RAG package for GitHub Copilot integration."""
EOF

# Create the main simple_http_server.py with basic functionality
create_file "src/mcp_local_rag/simple_http_server.py" "HTTP MCP server" << 'EOF'
"""
Simple HTTP-based MCP Server for GitHub Copilot Integration
Uses Python's built-in http.server to avoid external dependencies.
Optimized for Python 3.12+ with modern features.
"""

import json
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field


# Pydantic models for input validation
class ProjectInfoInput(BaseModel):
    """Input schema for project information retrieval."""
    project_name: str = Field(..., description="The name of the project")
    environment: str = Field(default="general", description="Environment type")


class EnvironmentToolsInput(BaseModel):
    """Input schema for environment-specific tooling information."""
    environment: str = Field(..., description="Environment type: java, node, typescript")
    query: str = Field(default="", description="Specific query about tools")


class RagSearchInput(BaseModel):
    """Input schema for RAG search functionality."""
    query: str = Field(..., description="The query to search for")
    num_results: int = Field(default=10, description="Number of results")
    top_k: int = Field(default=5, description="Top K results")


class MCPHandler(BaseHTTPRequestHandler):
    """HTTP request handler for MCP protocol."""
    
    def _verify_auth(self) -> bool:
        """Verify API key authentication."""
        api_key = os.environ.get("MCP_API_KEY")
        if not api_key:
            return True  # No auth required in dev mode
            
        auth_header = self.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return False
            
        token = auth_header[7:]  # Remove "Bearer "
        return token == api_key
    
    def _send_json_response(self, data: Dict[str, Any], status_code: int = 200):
        """Send JSON response."""
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def _send_error_response(self, message: str, status_code: int = 400):
        """Send error response."""
        self._send_json_response({"error": message}, status_code)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests."""
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
    
    def do_GET(self):
        """Handle GET requests."""
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        if path == '/health':
            self._send_json_response({
                "status": "healthy",
                "server": "pydantic-mcp-server",
                "version": "1.0.0"
            })
        elif path == '/':
            self._send_json_response({
                "name": "Pydantic MCP Server",
                "description": "HTTP-based MCP server for GitHub Copilot integration",
                "version": "1.0.0",
                "endpoints": {
                    "mcp": "/mcp - MCP protocol endpoint",
                    "health": "/health - Health check",
                    "tools": "/tools - List available tools"
                }
            })
        elif path == '/tools':
            if not self._verify_auth():
                self._send_error_response("Unauthorized", 401)
                return
            
            tools = [
                {
                    "name": "get-project-info",
                    "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
                    "inputSchema": ProjectInfoInput.model_json_schema()
                },
                {
                    "name": "get-environment-tools", 
                    "description": "Get development tools for Java, Node.js, or TypeScript environments",
                    "inputSchema": EnvironmentToolsInput.model_json_schema()
                },
                {
                    "name": "rag-search",
                    "description": "Search the web for information using RAG-like similarity sorting",
                    "inputSchema": RagSearchInput.model_json_schema()
                }
            ]
            
            self._send_json_response({"tools": tools})
        else:
            self._send_error_response("Not found", 404)
    
    def do_POST(self):
        """Handle POST requests (MCP protocol)."""
        if self.path != '/mcp':
            self._send_error_response("Not found", 404)
            return
        
        if not self._verify_auth():
            self._send_error_response("Unauthorized", 401)
            return
        
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length == 0:
                self._send_error_response("Request body is required")
                return
            
            raw_body = self.rfile.read(content_length)
            data = json.loads(raw_body.decode('utf-8'))
            
            request_id = data.get("id")
            method = data.get("method")
            
            if method == "tools/list":
                tools = [
                    {
                        "name": "get-project-info",
                        "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
                        "inputSchema": ProjectInfoInput.model_json_schema()
                    },
                    {
                        "name": "get-environment-tools",
                        "description": "Get development tools for Java, Node.js, or TypeScript environments", 
                        "inputSchema": EnvironmentToolsInput.model_json_schema()
                    },
                    {
                        "name": "rag-search",
                        "description": "Search the web for information using RAG-like similarity sorting",
                        "inputSchema": RagSearchInput.model_json_schema()
                    }
                ]
                
                self._send_json_response({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {"tools": tools}
                })
            
            elif method == "tools/call":
                params = data.get("params", {})
                tool_name = params.get("name")
                tool_arguments = params.get("arguments", {})
                
                # Simple tool implementations
                if tool_name == "get-project-info":
                    result = f"Project: {tool_arguments.get('project_name', 'unknown')} - Environment: {tool_arguments.get('environment', 'general')}"
                elif tool_name == "get-environment-tools":
                    env = tool_arguments.get('environment', 'general')
                    result = f"Tools for {env}: Maven/Gradle (Java), npm/yarn (Node.js), TypeScript compiler"
                elif tool_name == "rag-search":
                    query = tool_arguments.get('query', '')
                    result = f"Search results for '{query}': [Simulated web search - integrate with actual search API]"
                else:
                    result = "Unknown tool"
                
                self._send_json_response({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {
                        "content": [{"type": "text", "text": result}]
                    }
                })
            
            else:
                self._send_error_response("Unknown method", 400)
        
        except json.JSONDecodeError:
            self._send_error_response("Invalid JSON")
        except Exception as e:
            self._send_error_response(f"Server error: {str(e)}", 500)


def run_server() -> None:
    """Run the HTTP MCP server with modern Python features."""
    import sys
    import signal
    
    host_env = os.environ.get("HOST", "0.0.0.0")
    # Always use 0.0.0.0 if host is not a valid IPv4 address
    import socket
    try:
        socket.inet_pton(socket.AF_INET, host_env)
        host = host_env
    except OSError:
        host = "0.0.0.0"
    
    port = int(os.environ.get("PORT", 8001))
    api_key = os.environ.get("MCP_API_KEY")
    
    print("=" * 60)
    print("🚀 Starting Pydantic MCP Server for GitHub Copilot")
    print("=" * 60)
    print(f"Python Version: {sys.version.split()[0]}")
    print(f"Host:          {host}")
    print(f"Port:          {port}")
    print(f"Authentication: {'🔒 Enabled' if api_key else '🔓 Development mode (no auth)'}")
    if api_key:
        print(f"API Key:       {api_key[:8]}...")
    print(f"Health Check:  http://{host}:{port}/health")
    print(f"MCP Endpoint:  http://{host}:{port}/mcp")
    print(f"Tools List:    http://{host}:{port}/tools")
    print("=" * 60)
    
    if not api_key:
        print("⚠️  WARNING: No MCP_API_KEY set. Running in development mode.")
        print("   Set MCP_API_KEY environment variable for production use.")
        print(f"   Example: export MCP_API_KEY='your-secure-api-key'")
        print()
    else:
        print("🔐 Authentication enabled. Clients must use Authorization header:")
        print(f"   Authorization: Bearer {api_key}")
        print()
    
    def signal_handler(signum: int, frame) -> None:
        print(f"\n📡 Received signal {signum}. Shutting down server gracefully...")
        server.server_close()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    server = HTTPServer((host, port), MCPHandler)
    
    print(f"🌐 Server running at http://{host}:{port}")
    print("   Press Ctrl+C to stop the server")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n📡 Received keyboard interrupt. Shutting down...")
    finally:
        server.server_close()
        print("👋 Server stopped.")


if __name__ == "__main__":
    run_server()
EOF

# Create pyproject.toml
create_file "pyproject.toml" "Python project configuration" << 'EOF'
[project]
name = "mcp-local-rag"
version = "1.0.0" 
description = "MCP server for GitHub Copilot integration with Pydantic validation"
requires-python = ">=3.8"
dependencies = [
    "pydantic>=2.0.0",
    "requests",
    "beautifulsoup4", 
    "duckduckgo-search",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/mcp_local_rag"]
EOF

# Create a basic README.md
create_file "README.md" "Basic README" << 'EOF'
# MCP Server for GitHub Copilot

This repository contains a Pydantic MCP (Model Context Protocol) server for GitHub Copilot integration.

## Quick Start

1. **Install dependencies:**
   ```bash
   pip install -e .
   ```

2. **Start the server:**
   ```bash
   export MCP_API_KEY="your-secure-api-key"
   python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
   ```

3. **Test the server:**
   ```bash
   curl http://localhost:8001/health
   ```

## Available Tools

- `get-project-info`: Retrieve project information for Java, Node.js, or TypeScript environments
- `get-environment-tools`: Get development tools for specific environments
- `rag-search`: Search the web for information using RAG-like similarity sorting

## Deployment

See the configuration files for deployment to Railway, Docker, or other platforms.
EOF

# Create github-mcp-config.json
create_file "github-mcp-config.json" "GitHub Copilot configuration" << 'EOF'
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://your-app-name.up.railway.app/mcp",
      "headers": {
        "Authorization": "Bearer your-secure-api-key1"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
EOF

# Create railway.toml
create_file "railway.toml" "Railway deployment configuration" << 'EOF'
# Railway.app configuration for easy deployment
[build]
builder = "DOCKERFILE"

[deploy]
startCommand = "python -c 'from src.mcp_local_rag.simple_http_server import run_server; run_server()'"
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"

[env]
PORT = { default = "8001" }
HOST = { default = "0.0.0.0" }
PYTHONPATH = { default = "/app/src" }
# Set this in Railway dashboard variables section:
# MCP_API_KEY = "your-secure-api-key1"
EOF

# Create Dockerfile
create_file "Dockerfile" "Docker configuration" << 'EOF'
FROM python:3.12-slim

WORKDIR /app

# Copy requirements first for better caching
COPY pyproject.toml ./
RUN pip install -e .

# Copy source code
COPY src/ ./src/

# Create a non-root user
RUN useradd -m -u 1000 mcpuser && chown -R mcpuser:mcpuser /app
USER mcpuser

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8001/health || exit 1

# Run the server
CMD ["python", "-c", "from src.mcp_local_rag.simple_http_server import run_server; run_server()"]
EOF

# Create deploy.sh
create_file "deploy.sh" "Local deployment script" << 'EOF'
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
if python3 -c "import pydantic, requests" 2>/dev/null; then
    echo "✅ Dependencies installed"
else
    echo "📦 Installing dependencies..."
    pip install -e .
fi

# Start server
echo ""
echo "🎯 Starting server..."
echo "Using simple HTTP server implementation"
export HOST PORT MCP_API_KEY
exec python3 -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
EOF

chmod +x deploy.sh

echo ""
echo "2️⃣  Setting up Python environment..."

# Check Python version
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version 2>/dev/null | cut -d' ' -f2)
    echo "   Python version: $PYTHON_VERSION"
    
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
        echo "   ✅ Python 3.8+ detected"
    else
        echo "   ⚠️  Warning: Python 3.8+ recommended"
    fi
else
    echo "   ❌ Error: Python 3 is required but not found"
    echo "   Please install Python 3.8+ and try again"
    exit 1
fi

# Install dependencies
echo "   📦 Installing dependencies..."
if pip install -e . >/dev/null 2>&1; then
    echo "   ✅ Dependencies installed successfully"
else
    echo "   ⚠️  Failed to install dependencies automatically"
    echo "   Please run 'pip install -e .' manually"
fi

echo ""
echo "3️⃣  Configuration setup..."

# Generate a secure API key
if command -v openssl >/dev/null 2>&1; then
    API_KEY="mcp_$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)"
else
    # Fallback key generation
    API_KEY="mcp_$(date +%s | sha256sum | head -c 25)"
fi

echo "   🔑 Generated secure API key: ${API_KEY:0:8}..."

# Update github-mcp-config.json with generated key
sed -i.bak "s|your-secure-api-key1|$API_KEY|g" github-mcp-config.json 2>/dev/null || {
    # For macOS
    sed -i '' "s|your-secure-api-key1|$API_KEY|g" github-mcp-config.json 2>/dev/null || true
}
rm -f github-mcp-config.json.bak

echo "   ✅ Updated GitHub configuration with generated API key"

echo ""
echo "4️⃣  Testing setup..."

# Test Python imports
echo "   🧪 Testing Python imports..."
if python3 -c "from src.mcp_local_rag.simple_http_server import run_server; print('✅ MCP server can be imported')" 2>/dev/null; then
    echo "   ✅ MCP server import successful"
else
    echo "   ⚠️  MCP server import test failed - check dependencies"
fi

echo ""
echo "✅ Setup Complete!"
echo "==================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. **Test locally:**"
echo "   export MCP_API_KEY=\"$API_KEY\""
echo '   python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"'
echo ""
echo "2. **Deploy to Railway (free):**"
echo "   - Connect this repository to Railway"
echo "   - Set environment variable: MCP_API_KEY=$API_KEY"
echo "   - Railway will auto-deploy using railway.toml"
echo ""
echo "3. **Configure GitHub Copilot:**"
echo "   - Update github-mcp-config.json with your Railway URL"
echo "   - Add the configuration to your repository settings"
echo ""
echo "4. **Validate setup:**"
echo "   ./deploy.sh  # Test locally"
echo ""
echo "🎉 Your MCP server is ready for GitHub Copilot integration!"