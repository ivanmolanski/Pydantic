#!/bin/bash
# Enhanced Railway Deployment Debugging Script
# This script helps diagnose and fix Railway deployment issues for the MCP server

set -e

echo "🚂 Enhanced Railway MCP Server Debugging and Fix Script"
echo "========================================================"

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Installing..."
    curl -fsSL https://railway.app/install.sh | sh
    export PATH="$HOME/.railway/bin:$PATH"
fi

echo "🔍 Current Railway project status:"
railway status 2>/dev/null || {
    echo "⚠️  Not linked to Railway project. Run 'railway login' and 'railway link' first."
    exit 1
}

echo -e "\n🔧 Checking Railway environment variables:"
railway env --json 2>/dev/null || railway env

echo -e "\n📦 Latest Railway deployments:"
railway logs --num 10 2>/dev/null || echo "⚠️  Could not fetch recent logs"

echo -e "\n🏥 Testing Railway service health:"
# Get the current Railway service URL
RAILWAY_URL=$(railway get-url 2>/dev/null || echo "")
if [ -n "$RAILWAY_URL" ]; then
    echo "Railway URL: $RAILWAY_URL"
    
    echo "Testing health endpoint..."
    if curl -f -m 10 "$RAILWAY_URL/health" 2>/dev/null; then
        echo "✅ Health endpoint is working"
        
        echo -e "\nTesting MCP endpoint authentication..."
        curl -X POST "$RAILWAY_URL/mcp" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs" \
            -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' \
            -m 30 2>/dev/null && echo -e "\n✅ MCP endpoint is working" || echo -e "\n❌ MCP endpoint failed"
    else
        echo "❌ Health endpoint is not responding"
        echo "🔧 This indicates the Railway service is not running properly"
    fi
else
    echo "❌ Could not get Railway URL"
fi

echo -e "\n🚀 Checking Railway service configuration:"
echo "Dockerfile configuration:"
head -5 Dockerfile

echo -e "\nRailway.toml configuration:"
cat railway.toml

echo -e "\n🔧 Common fixes to try:"
echo "1. Redeploy the service:"
echo "   railway up --detach"
echo ""
echo "2. Check Railway logs in real-time:"
echo "   railway logs --follow"
echo ""
echo "3. Restart the Railway service:"
echo "   railway restart"
echo ""
echo "4. Set required environment variables:"
echo "   railway env set MCP_API_KEY=mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
echo ""
echo "5. If the service is sleeping, try:"
echo "   railway env set SLEEP_POLICY=NEVER"
echo ""

# Offer to redeploy automatically
echo -e "\n❓ Would you like to redeploy the Railway service now? (y/N)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🚀 Redeploying Railway service..."
    railway env set MCP_API_KEY=mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs
    railway up --detach
    echo "✅ Redeployment initiated. Check 'railway logs --follow' for status."
    
    echo "⏳ Waiting 30 seconds for deployment to stabilize..."
    sleep 30
    
    # Test again
    RAILWAY_URL=$(railway get-url 2>/dev/null || echo "")
    if [ -n "$RAILWAY_URL" ]; then
        echo "🏥 Testing redeployed service..."
        if curl -f -m 10 "$RAILWAY_URL/health" 2>/dev/null; then
            echo "✅ Redeployed service is healthy!"
            echo "🎉 Your MCP server should now work with GitHub Copilot"
            echo "📋 Use this configuration in GitHub Copilot:"
            echo "{"
            echo "  \"mcpServers\": {"
            echo "    \"pydanticAgent\": {"
            echo "      \"type\": \"http\","
            echo "      \"url\": \"$RAILWAY_URL/mcp\","
            echo "      \"headers\": {"
            echo "        \"Authorization\": \"Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs\""
            echo "      },"
            echo "      \"tools\": [\"get-project-info\", \"get-environment-tools\", \"rag-search\"]"
            echo "    }"
            echo "  }"
            echo "}"
        else
            echo "❌ Redeployed service is still not responding"
            echo "🔍 Check logs: railway logs --follow"
        fi
    fi
fi

echo -e "\n✅ Debugging script complete!"