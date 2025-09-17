#!/bin/bash

# Railway Deployment Setup Script for Pydantic MCP Server
# This script helps configure Railway deployment with correct environment variables

set -e

echo "🚀 Railway Deployment Setup for Pydantic MCP Server"
echo "================================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Installing..."
    curl -fsSL https://railway.app/install.sh | sh
    echo "✅ Railway CLI installed"
fi

# Check if we're in a Railway project
if ! railway status &> /dev/null; then
    echo "❌ Not in a Railway project. Please run 'railway login' and 'railway link' first."
    exit 1
fi

echo "📋 Current Railway project status:"
railway status

echo ""
echo "🔑 Setting up environment variables..."

# Set the API key (using the one from Railway Variables)
API_KEY="your-secure-api-key1"
echo "Setting MCP_API_KEY to: $API_KEY"
railway variables set MCP_API_KEY="$API_KEY"

# Set other required environment variables
echo "Setting PORT to: 8001"
railway variables set PORT=8001

echo "Setting HOST to: 0.0.0.0"
railway variables set HOST=0.0.0.0

echo "Setting PYTHONPATH to: /app/src"
railway variables set PYTHONPATH=/app/src

echo ""
echo "🔧 Railway Configuration Info:"
echo "   Your Railway dashboard shows Dockerfile builder is being used"
echo "   Make sure these variables match in Railway dashboard:"
echo "   - MCP_API_KEY = your-secure-api-key1 (your actual key)"
echo "   - PYTHONPATH = /app/src (not '/opt/render/project/src')"
echo "   - HOST = 0.0.0.0 (not '[::]')"
echo "   - PORT = 8001"

echo ""
echo "📦 Deploying to Railway..."
railway up

echo ""
echo "⏳ Waiting for deployment to complete..."
sleep 10

echo ""
echo "🌐 Getting deployment URL..."
RAILWAY_URL=$(railway domain 2>/dev/null || echo "")

if [ -z "$RAILWAY_URL" ]; then
    echo "⚠️  Could not get Railway URL automatically."
    echo "   Please check your Railway dashboard for the deployment URL."
    echo "   Based on your dashboard, it should be: https://pydantic-mcp-server-production.up.railway.app"
    RAILWAY_URL="https://pydantic-mcp-server-production.up.railway.app"
else
    echo "✅ Deployment URL: $RAILWAY_URL"
fi
    
echo ""
echo "🧪 Testing deployment..."

# Test health endpoint
echo "Testing health endpoint..."
if curl -f -s "$RAILWAY_URL/health" > /dev/null; then
    echo "✅ Health endpoint is working"
else
    echo "❌ Health endpoint failed - deployment may still be starting"
fi

# Test MCP endpoint with authentication
echo "Testing MCP endpoint with authentication..."
MCP_RESPONSE=$(curl -s -X POST "$RAILWAY_URL/mcp" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}')

if echo "$MCP_RESPONSE" | grep -q "tools"; then
    echo "✅ MCP endpoint is working with authentication"
elif echo "$MCP_RESPONSE" | grep -q "Unauthorized"; then
    echo "⚠️  MCP endpoint returned Unauthorized - check Railway dashboard variables:"
    echo "   Make sure MCP_API_KEY = your-secure-api-key1 (your actual API key)"
else
    echo "❌ MCP endpoint failed"
    echo "Response: $MCP_RESPONSE"
fi

echo ""
echo "📋 Next steps:"
echo "1. Update your GitHub Copilot configuration with:"
echo "   URL: $RAILWAY_URL/mcp"
echo "   API Key: $API_KEY"
echo ""
echo "2. Example GitHub Copilot configuration:"
cat << 'EOF'
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "REPLACE_WITH_YOUR_RAILWAY_URL/mcp",
      "headers": {
        "Authorization": "Bearer your-secure-api-key1"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
EOF

echo ""
echo "3. For troubleshooting, see: GITHUB_COPILOT_SETUP.md"
echo ""
echo "🎉 Deployment setup complete!"