#!/bin/bash

# Configuration Template Generator for MCP Server
# Generates customized configuration files for any repository

set -e

echo "🔧 MCP Server Configuration Generator"
echo "====================================="
echo ""

# Get user input
read -p "🌐 Enter your Railway app name (or deployment URL): " RAILWAY_APP
read -p "🔑 Enter your API key (leave empty to generate): " API_KEY
read -p "📁 Enter repository name (current: $(basename "$(pwd)")): " REPO_NAME

# Set defaults
REPO_NAME=${REPO_NAME:-$(basename "$(pwd)")}
if [ -z "$API_KEY" ]; then
    API_KEY="mcp_$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)"
    echo "   🔑 Generated API key: ${API_KEY:0:8}..."
fi

# Determine Railway URL
if [[ "$RAILWAY_APP" == *"http"* ]]; then
    RAILWAY_URL="$RAILWAY_APP"
else
    RAILWAY_URL="https://${RAILWAY_APP}.up.railway.app"
fi

echo ""
echo "📝 Generating configuration files..."

# Generate GitHub Copilot configuration
cat > github-mcp-config.json << EOF
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "${RAILWAY_URL}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
EOF

# Generate Railway configuration
cat > railway.toml << EOF
# Railway.app configuration for ${REPO_NAME}
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
# MCP_API_KEY = "${API_KEY}"
EOF

# Generate Docker Compose for local testing
cat > docker-compose.yml << EOF
version: '3.8'

services:
  mcp-server:
    build: .
    ports:
      - "8001:8001"
    environment:
      - HOST=0.0.0.0
      - PORT=8001
      - MCP_API_KEY=${API_KEY}
      - PYTHONPATH=/app/src
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# Generate environment file for local development
cat > .env.example << EOF
# Environment variables for MCP Server
# Copy this to .env and update values as needed

# Server configuration
HOST=0.0.0.0
PORT=8001
PYTHONPATH=./src

# Authentication
MCP_API_KEY=${API_KEY}

# Railway deployment URL (update with your actual URL)
RAILWAY_URL=${RAILWAY_URL}
EOF

# Generate validation script
cat > validate_mcp_setup.sh << 'EOF'
#!/bin/bash

echo "🧪 MCP Server Validation Script"
echo "================================"
echo ""

# Load environment variables if .env exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

API_KEY=${MCP_API_KEY:-"test-api-key"}
HOST=${HOST:-"localhost"}
PORT=${PORT:-"8001"}
RAILWAY_URL=${RAILWAY_URL:-""}

echo "Testing configuration:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  API Key: ${API_KEY:0:8}..."
if [ -n "$RAILWAY_URL" ]; then
    echo "  Railway URL: $RAILWAY_URL"
fi
echo ""

# Test 1: Local health check
echo "1️⃣  Testing local health endpoint..."
if curl -s -f "http://$HOST:$PORT/health" > /dev/null 2>&1; then
    echo "   ✅ Health check passed"
    health_response=$(curl -s "http://$HOST:$PORT/health")
    echo "   Response: $health_response"
else
    echo "   ❌ Health check failed - is the server running?"
    echo "   Start server with: MCP_API_KEY=\"$API_KEY\" python -c \"from src.mcp_local_rag.simple_http_server import run_server; run_server()\""
fi

echo ""

# Test 2: Local MCP endpoint
echo "2️⃣  Testing local MCP endpoint..."
mcp_response=$(curl -s -X POST "http://$HOST:$PORT/mcp" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' 2>/dev/null)

if echo "$mcp_response" | jq -e '.result.tools | length' > /dev/null 2>&1; then
    tool_count=$(echo "$mcp_response" | jq '.result.tools | length')
    echo "   ✅ MCP endpoint passed - $tool_count tools available"
    echo "$mcp_response" | jq '.result.tools[].name' | sed 's/^/     - /'
else
    echo "   ❌ MCP endpoint failed"
    echo "   Response: $mcp_response"
fi

echo ""

# Test 3: Railway deployment (if URL provided)
if [ -n "$RAILWAY_URL" ]; then
    echo "3️⃣  Testing Railway deployment..."
    
    if curl -s -f "$RAILWAY_URL/health" > /dev/null 2>&1; then
        echo "   ✅ Railway health check passed"
        
        railway_mcp_response=$(curl -s -X POST "$RAILWAY_URL/mcp" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $API_KEY" \
            -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' 2>/dev/null)
        
        if echo "$railway_mcp_response" | jq -e '.result.tools | length' > /dev/null 2>&1; then
            echo "   ✅ Railway MCP endpoint working"
        else
            echo "   ❌ Railway MCP endpoint failed"
            echo "   Check API key in Railway environment variables"
        fi
    else
        echo "   ❌ Railway health check failed"
        echo "   Check deployment status in Railway dashboard"
    fi
else
    echo "3️⃣  Railway deployment test skipped (no URL provided)"
fi

echo ""

# Test 4: Configuration files
echo "4️⃣  Validating configuration files..."

if [ -f "github-mcp-config.json" ]; then
    if jq empty github-mcp-config.json 2>/dev/null; then
        echo "   ✅ github-mcp-config.json is valid JSON"
    else
        echo "   ❌ github-mcp-config.json is invalid JSON"
    fi
else
    echo "   ⚠️  github-mcp-config.json not found"
fi

if [ -f "railway.toml" ]; then
    echo "   ✅ railway.toml exists"
else
    echo "   ⚠️  railway.toml not found"
fi

if [ -f "pyproject.toml" ]; then
    echo "   ✅ pyproject.toml exists"
else
    echo "   ❌ pyproject.toml missing - required for dependencies"
fi

echo ""
echo "🎯 Validation Summary"
echo "===================="
echo "If all tests passed, your MCP server is ready for GitHub Copilot!"
echo ""
echo "Next steps:"
echo "1. Deploy to Railway if not already done"
echo "2. Update GitHub repository settings with MCP configuration"
echo "3. Test with GitHub Copilot in your repository"
EOF

chmod +x validate_mcp_setup.sh

echo "   ✅ github-mcp-config.json"
echo "   ✅ railway.toml"
echo "   ✅ docker-compose.yml"
echo "   ✅ .env.example"
echo "   ✅ validate_mcp_setup.sh"

echo ""
echo "📋 Configuration Summary"
echo "========================"
echo "Repository: $REPO_NAME"
echo "Railway URL: $RAILWAY_URL"
echo "API Key: ${API_KEY:0:8}..."
echo ""
echo "🚀 Next Steps:"
echo "1. Deploy to Railway and set MCP_API_KEY=$API_KEY"
echo "2. Update railway.toml if needed"
echo "3. Test with: ./validate_mcp_setup.sh"
echo "4. Add github-mcp-config.json to your repository settings"
echo ""
echo "✅ Configuration files generated successfully!"