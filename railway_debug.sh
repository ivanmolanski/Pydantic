#!/bin/bash

# Railway CLI Debugging and Troubleshooting Script
# This script helps diagnose Railway deployment issues for Pydantic MCP Server

set -e

echo "🚂 Railway MCP Server Debugging Script"
echo "======================================"

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Installing..."
    curl -fsSL https://railway.app/install.sh | sh
    export PATH="$HOME/.railway/bin:$PATH"
    echo "✅ Railway CLI installed"
fi

# Check Railway authentication
echo "🔐 Checking Railway authentication..."
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please run:"
    echo "   railway login"
    exit 1
fi

RAILWAY_USER=$(railway whoami)
echo "✅ Logged in as: $RAILWAY_USER"

# Check if we're in a Railway project
echo "📋 Checking Railway project status..."
if ! railway status &> /dev/null; then
    echo "❌ Not in a Railway project. Available options:"
    echo "1. Link existing project: railway link"
    echo "2. Create new project: railway init"
    echo ""
    echo "🔍 Listing your Railway projects:"
    railway list
    exit 1
fi

echo "✅ Railway project linked"
railway status

echo ""
echo "🔧 Checking environment variables..."

# Check critical environment variables
VARS_TO_CHECK=("MCP_API_KEY" "PORT" "HOST" "PYTHONPATH")
MISSING_VARS=()

for var in "${VARS_TO_CHECK[@]}"; do
    if railway variables | grep -q "$var"; then
        echo "✅ $var is set"
    else
        echo "❌ $var is missing"
        MISSING_VARS+=("$var")
    fi
done

# Set missing variables
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo ""
    echo "🔧 Setting missing environment variables..."
    
    for var in "${MISSING_VARS[@]}"; do
        case $var in
            "MCP_API_KEY")
                echo "Setting MCP_API_KEY..."
                railway variables set MCP_API_KEY="mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
                ;;
            "PORT")
                echo "Setting PORT..."
                railway variables set PORT=8001
                ;;
            "HOST")
                echo "Setting HOST..."
                railway variables set HOST=0.0.0.0
                ;;
            "PYTHONPATH")
                echo "Setting PYTHONPATH..."
                railway variables set PYTHONPATH=/app/src
                ;;
        esac
    done
    
    echo "🔄 Triggering redeploy with new variables..."
    railway redeploy --service web
    
    echo "⏳ Waiting for deployment to complete..."
    sleep 30
fi

echo ""
echo "🌐 Getting deployment information..."

# Get deployment URL
RAILWAY_URL=$(railway domain 2>/dev/null || echo "")
if [ -z "$RAILWAY_URL" ]; then
    echo "⚠️  Could not get Railway URL automatically."
    echo "   Getting from Railway service info..."
    railway service --help | grep -q "domain" && railway domain || true
    RAILWAY_URL="https://pydantic-mcp-server-production.up.railway.app"
    echo "   Using known URL: $RAILWAY_URL"
else
    echo "✅ Deployment URL: $RAILWAY_URL"
fi

echo ""
echo "📊 Checking deployment logs..."
echo "Recent logs:"
railway logs --tail 20

echo ""
echo "🧪 Testing deployment..."

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -f "$RAILWAY_URL/health" || echo "FAILED")
if [[ "$HEALTH_RESPONSE" == "FAILED" ]]; then
    echo "❌ Health endpoint failed"
    
    # Check if deployment is still starting
    echo "🔍 Checking if deployment is still starting..."
    railway logs --tail 10
    
    echo ""
    echo "💡 Possible issues:"
    echo "1. Deployment is still starting (wait 2-3 minutes)"
    echo "2. Environment variables are incorrect"
    echo "3. Dependencies failed to install"
    echo "4. Port binding issue"
    
else
    echo "✅ Health endpoint working"
    echo "Response: $HEALTH_RESPONSE"
fi

# Test MCP endpoint
echo ""
echo "Testing MCP endpoint..."
MCP_RESPONSE=$(curl -s -X POST "$RAILWAY_URL/mcp" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs" \
    -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' || echo "FAILED")

if [[ "$MCP_RESPONSE" == "FAILED" ]]; then
    echo "❌ MCP endpoint failed"
elif echo "$MCP_RESPONSE" | grep -q "Unauthorized"; then
    echo "❌ MCP endpoint returned Unauthorized"
    echo "🔧 Fix: Check that MCP_API_KEY matches in Railway variables"
elif echo "$MCP_RESPONSE" | grep -q "tools"; then
    echo "✅ MCP endpoint working correctly"
else
    echo "⚠️  MCP endpoint returned unexpected response:"
    echo "$MCP_RESPONSE"
fi

echo ""
echo "🔍 Advanced debugging information..."

# Show current variables
echo "Current environment variables:"
railway variables

echo ""
echo "Current service status:"
railway status

# Check for common issues
echo ""
echo "🩺 Health check summary:"

# Check if using correct builder
echo "Checking builder configuration..."
if [ -f "Dockerfile" ]; then
    echo "✅ Dockerfile found - Railway will use Docker builder"
else
    echo "⚠️  No Dockerfile found - Railway will use Nixpacks"
fi

# Check Python version in project
if [ -f ".python-version" ]; then
    PYTHON_VERSION=$(cat .python-version)
    echo "✅ Python version specified: $PYTHON_VERSION"
else
    echo "⚠️  No .python-version file found"
fi

# Check if dependencies are correct
if [ -f "pyproject.toml" ]; then
    echo "✅ pyproject.toml found"
else
    echo "❌ pyproject.toml missing"
fi

echo ""
echo "📋 Recommendations:"

if [[ "$HEALTH_RESPONSE" == "FAILED" ]]; then
    echo "🚨 Server is not responding:"
    echo "1. Check Railway logs: railway logs"
    echo "2. Wait 2-3 minutes for deployment to complete"
    echo "3. Try redeploying: railway redeploy"
    echo "4. Check environment variables are correct"
fi

if echo "$MCP_RESPONSE" | grep -q "Unauthorized"; then
    echo "🔐 Authentication issue:"
    echo "1. Verify Railway variable MCP_API_KEY = mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
    echo "2. Update GitHub Copilot config to use the same API key"
    echo "3. Redeploy after changing variables"
fi

echo ""
echo "💡 Next steps:"
echo "1. If deployment is healthy, update GitHub Copilot with:"
echo "   URL: $RAILWAY_URL/mcp"
echo "   API Key: mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
echo ""
echo "2. Test GitHub Copilot connection"
echo ""
echo "3. If issues persist, try alternative hosting:"
echo "   - Render.com (see ALTERNATIVE_HOSTING.md)"
echo "   - Vercel (see ALTERNATIVE_HOSTING.md)"
echo ""
echo "🎉 Debugging complete!"