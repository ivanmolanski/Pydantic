#!/bin/bash

# Validation script for Pydantic MCP Server GitHub Copilot integration
# Tests both local and remote deployments

set -e

API_KEY="celebrated-magic"
LOCAL_URL="http://localhost:8001"
RAILWAY_URL="${1:-https://pydantic-mcp-server-production.up.railway.app}"

echo "🧪 Pydantic MCP Server Validation Script"
echo "========================================"
echo "API Key: ${API_KEY:0:8}..."
echo "Local URL: $LOCAL_URL"
echo "Railway URL: $RAILWAY_URL"
echo ""

# Function to test an endpoint
test_endpoint() {
    local url=$1
    local description=$2
    local auth_header=$3
    
    echo "Testing $description..."
    
    if [ -n "$auth_header" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "$url/mcp" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $auth_header" \
            -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' 2>/dev/null || echo -e "\nERROR")
    else
        response=$(curl -s -w "\n%{http_code}" "$url/health" 2>/dev/null || echo -e "\nERROR")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        if [ -n "$auth_header" ]; then
            if echo "$body" | grep -q '"tools"'; then
                echo "✅ $description - SUCCESS (Found tools list)"
            else
                echo "❌ $description - FAILED (No tools in response)"
                echo "   Response: $body"
            fi
        else
            if echo "$body" | grep -q '"status"' && echo "$body" | grep -q '"healthy"'; then
                echo "✅ $description - SUCCESS (Healthy)"
            else
                echo "❌ $description - FAILED (Not healthy)"
                echo "   Response: $body"
            fi
        fi
    elif [ "$http_code" = "401" ]; then
        echo "❌ $description - FAILED (HTTP 401 - Unauthorized)"
        echo "   Check API key configuration"
    elif [ "$http_code" = "ERROR" ]; then
        echo "❌ $description - FAILED (Connection error)"
        echo "   Server may be down or URL incorrect"
    else
        echo "❌ $description - FAILED (HTTP $http_code)"
        echo "   Response: $body"
    fi
}

# Test local server (if running)
echo "📡 Testing local server..."
test_endpoint "$LOCAL_URL" "Local health check" ""
test_endpoint "$LOCAL_URL" "Local MCP endpoint" "$API_KEY"

# Test wrong API key locally
echo ""
echo "Testing local server with wrong API key (should fail)..."
response=$(curl -s -w "\n%{http_code}" -X POST "$LOCAL_URL/mcp" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer wrong-key" \
    -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' 2>/dev/null || echo -e "\nERROR")

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "401" ]; then
    echo "✅ Local wrong API key test - SUCCESS (Correctly rejected)"
else
    echo "❌ Local wrong API key test - FAILED (Should have returned 401)"
fi

echo ""
echo "🌐 Testing Railway deployment..."
test_endpoint "$RAILWAY_URL" "Railway health check" ""
test_endpoint "$RAILWAY_URL" "Railway MCP endpoint" "$API_KEY"

echo ""
echo "📋 Summary for GitHub Copilot Configuration:"
echo ""
echo "If tests pass, use this configuration in GitHub Copilot:"
cat << EOF
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "$RAILWAY_URL/mcp",
      "headers": {
        "Authorization": "Bearer $API_KEY"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
EOF

echo ""
echo "🔧 If tests fail:"
echo "1. For local issues: Start server with 'MCP_API_KEY=$API_KEY python -c \"from src.mcp_local_rag.simple_http_server import run_server; run_server()\"'"
echo "2. For Railway issues: Run './railway_setup.sh' to configure environment variables"
echo "3. For detailed troubleshooting: See GITHUB_COPILOT_SETUP.md"

echo ""
echo "✅ Validation complete!"