#!/bin/bash

# Universal MCP Server Validation Script
# Tests any MCP server setup for GitHub Copilot compatibility

echo "🧪 Universal MCP Server Validation"
echo "==================================="
echo ""

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "📂 Loading environment variables from .env file..."
    set -o allexport
    source .env
    set +o allexport
    echo ""
fi

API_KEY=${MCP_API_KEY:-"test-api-key"}
HOST=${HOST:-"localhost"}
PORT=${PORT:-"8001"}
RAILWAY_URL=${RAILWAY_URL:-""}

echo "🔧 Current Configuration:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  API Key: ${API_KEY:0:8}..."
if [ -n "$RAILWAY_URL" ]; then
    echo "  Railway URL: $RAILWAY_URL"
fi
echo ""

# Function to test an endpoint
test_endpoint() {
    local url="$1"
    local description="$2"
    local expected_status="${3:-200}"
    local auth_header="$4"
    
    echo "   Testing $description..."
    
    local curl_cmd="curl -s -w '%{http_code}' -o /tmp/response.json"
    if [ -n "$auth_header" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $auth_header'"
    fi
    curl_cmd="$curl_cmd '$url'"
    
    local status_code=$(eval $curl_cmd)
    
    if [ "$status_code" = "$expected_status" ]; then
        echo "     ✅ HTTP $status_code - Success"
        if [ -f "/tmp/response.json" ]; then
            local response=$(cat /tmp/response.json)
            if [ -n "$response" ] && [ "$response" != "null" ]; then
                echo "     📄 Response: ${response:0:100}..."
            fi
        fi
        return 0
    else
        echo "     ❌ HTTP $status_code - Failed (expected $expected_status)"
        if [ -f "/tmp/response.json" ]; then
            local response=$(cat /tmp/response.json)
            if [ -n "$response" ] && [ "$response" != "null" ]; then
                echo "     📄 Error: ${response:0:200}..."
            fi
        fi
        return 1
    fi
}

# Function to test MCP endpoint
test_mcp_endpoint() {
    local url="$1"
    local description="$2"
    local api_key="$3"
    
    echo "   Testing $description..."
    
    local response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' 2>/dev/null)
    
    if echo "$response" | jq -e '.result.tools | length' > /dev/null 2>&1; then
        local tool_count=$(echo "$response" | jq '.result.tools | length')
        echo "     ✅ MCP endpoint working - $tool_count tools available"
        echo "$response" | jq '.result.tools[].name' 2>/dev/null | sed 's/^/       - /' | tr -d '"'
        return 0
    else
        echo "     ❌ MCP endpoint failed"
        echo "     📄 Response: ${response:0:200}..."
        return 1
    fi
}

# Test 1: Check if server is running locally
echo "1️⃣  Testing Local Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"

local_health_url="http://$HOST:$PORT/health"
local_mcp_url="http://$HOST:$PORT/mcp"

if test_endpoint "$local_health_url" "health endpoint"; then
    test_mcp_endpoint "$local_mcp_url" "local MCP endpoint" "$API_KEY"
else
    echo "   ⚠️  Local server not running. Start with:"
    echo '       export MCP_API_KEY="'$API_KEY'"'
    echo '       python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"'
fi

echo ""

# Test 2: Railway deployment (if URL provided)
if [ -n "$RAILWAY_URL" ]; then
    echo "2️⃣  Testing Railway Deployment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    railway_health_url="$RAILWAY_URL/health"
    railway_mcp_url="$RAILWAY_URL/mcp"
    
    if test_endpoint "$railway_health_url" "Railway health endpoint"; then
        test_mcp_endpoint "$railway_mcp_url" "Railway MCP endpoint" "$API_KEY"
    else
        echo "   ⚠️  Railway deployment not accessible"
        echo "       Check deployment status in Railway dashboard"
    fi
else
    echo "2️⃣  Railway Deployment Test Skipped"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   ℹ️  No RAILWAY_URL provided"
fi

echo ""

# Test 3: Configuration files validation
echo "3️⃣  Validating Configuration Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

files_valid=0
total_files=0

# Check github-mcp-config.json
total_files=$((total_files + 1))
if [ -f "github-mcp-config.json" ]; then
    if jq empty github-mcp-config.json 2>/dev/null; then
        echo "   ✅ github-mcp-config.json is valid JSON"
        files_valid=$((files_valid + 1))
        
        # Check if it contains the right structure
        if jq -e '.mcpServers.pydanticAgent.url' github-mcp-config.json > /dev/null 2>&1; then
            echo "       📡 MCP server URL configured"
        else
            echo "       ⚠️  MCP server URL not found in configuration"
        fi
        
        if jq -e '.mcpServers.pydanticAgent.headers.Authorization' github-mcp-config.json > /dev/null 2>&1; then
            echo "       🔐 Authorization header configured"
        else
            echo "       ⚠️  Authorization header not found"
        fi
    else
        echo "   ❌ github-mcp-config.json contains invalid JSON"
    fi
else
    echo "   ⚠️  github-mcp-config.json not found"
fi

# Check railway.toml
total_files=$((total_files + 1))
if [ -f "railway.toml" ]; then
    echo "   ✅ railway.toml exists"
    files_valid=$((files_valid + 1))
    
    # Check for key configurations
    if grep -q "startCommand" railway.toml; then
        echo "       🚀 Start command configured"
    fi
    if grep -q "healthcheckPath" railway.toml; then
        echo "       🏥 Health check configured"
    fi
else
    echo "   ⚠️  railway.toml not found"
fi

# Check pyproject.toml
total_files=$((total_files + 1))
if [ -f "pyproject.toml" ]; then
    echo "   ✅ pyproject.toml exists"
    files_valid=$((files_valid + 1))
    
    if grep -q "pydantic" pyproject.toml; then
        echo "       📦 Pydantic dependency found"
    fi
else
    echo "   ❌ pyproject.toml missing - required for dependencies"
fi

# Check source code
total_files=$((total_files + 1))
if [ -f "src/mcp_local_rag/simple_http_server.py" ]; then
    echo "   ✅ MCP server source code exists"
    files_valid=$((files_valid + 1))
else
    echo "   ❌ MCP server source code missing"
fi

echo ""

# Test 4: Python environment validation
echo "4️⃣  Python Environment Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Python version
if command -v python3 >/dev/null 2>&1; then
    python_version=$(python3 --version 2>/dev/null | cut -d' ' -f2)
    echo "   ✅ Python 3 found: $python_version"
    
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
        echo "   ✅ Python 3.8+ compatibility confirmed"
    else
        echo "   ⚠️  Python 3.8+ recommended"
    fi
else
    echo "   ❌ Python 3 not found"
fi

# Check key dependencies
dependencies=("pydantic" "requests" "json")
for dep in "${dependencies[@]}"; do
    if python3 -c "import $dep" 2>/dev/null; then
        echo "   ✅ $dep module available"
    else
        echo "   ❌ $dep module missing"
        echo "       Install with: pip install $dep"
    fi
done

# Check if MCP server can be imported
if python3 -c "from src.mcp_local_rag.simple_http_server import run_server" 2>/dev/null; then
    echo "   ✅ MCP server can be imported successfully"
else
    echo "   ❌ MCP server import failed"
    echo "       Check file structure and dependencies"
fi

echo ""

# Summary
echo "🎯 Validation Summary"
echo "════════════════════"

config_score=$((files_valid * 100 / total_files))

if [ "$config_score" -ge 75 ]; then
    echo "📊 Configuration Score: $config_score% - ✅ Good"
else
    echo "📊 Configuration Score: $config_score% - ⚠️  Needs attention"
fi

echo ""
echo "📋 Next Steps:"

if [ ! -f "src/mcp_local_rag/simple_http_server.py" ]; then
    echo "1. 🚨 Run the setup script to create missing files"
    echo "   ./setup_mcp_server.sh"
elif ! python3 -c "import pydantic" 2>/dev/null; then
    echo "1. 📦 Install missing dependencies"
    echo "   pip install -e ."
elif ! curl -s -f "$local_health_url" > /dev/null 2>&1; then
    echo "1. 🚀 Start the local MCP server"
    echo '   export MCP_API_KEY="'$API_KEY'"'
    echo '   python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"'
elif [ -z "$RAILWAY_URL" ]; then
    echo "1. 🌐 Deploy to Railway for production use"
    echo "   - Connect repository to Railway"
    echo "   - Set environment variable MCP_API_KEY=$API_KEY"
    echo "   - Update RAILWAY_URL in this script or .env file"
else
    echo "1. 🎉 Setup looks good! Your MCP server is ready for GitHub Copilot"
    echo "   - Add github-mcp-config.json to your GitHub repository settings"
    echo "   - Test with GitHub Copilot in your development workflow"
fi

echo ""
echo "💡 For detailed setup instructions, see:"
echo "   - REPLICATION_GUIDE.md"
echo "   - HTTP_MCP_INTEGRATION.md"
echo "   - GITHUB_COPILOT_SETUP.md"

# Cleanup
rm -f /tmp/response.json

echo ""
echo "✨ Validation complete!"