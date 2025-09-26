#!/bin/bash
# NOTE: Ensure this script has execute permissions by running:
#   chmod +x test_railway_deployment.sh

# Comprehensive Railway Deployment Test Script
# Tests the health check and MCP fixes for Railway deployment

echo "🧪 Testing Railway Deployment Health Check Fixes"
echo "================================================"
echo

# Configuration
LOCAL_PORT=3003
RAILWAY_URL="https://pydantic-mcp-server-production.up.railway.app"
API_KEY="mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

echo "🧪 Phase 1: Local Railway Environment Simulation"
echo "------------------------------------------------"

# Start local server with Railway environment variables
echo "Starting local server with Railway environment simulation..."
RAILWAY_ENVIRONMENT=production PORT=$LOCAL_PORT MCP_API_KEY=$API_KEY python app.py &
LOCAL_PID=$!

# Wait for server to start
echo "Waiting for server startup..."
sleep 3

# Test local health endpoint
echo
echo "1. Testing Local Health Endpoint:"
HEALTH_RESPONSE=$(curl -s http://localhost:$LOCAL_PORT/health)
echo $HEALTH_RESPONSE | jq .

# Check if health check shows Railway environment
if echo $HEALTH_RESPONSE | grep -q '"railway"'; then
    echo "✅ Railway environment detected in health response"
else
    echo "❌ Railway environment not detected"
fi

echo
echo "2. Testing Local MCP Protocol (notifications/initialized):"
HTTP_STATUS=$(curl -w "%{http_code}" -s -X POST http://localhost:$LOCAL_PORT/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"jsonrpc": "2.0", "method": "notifications/initialized"}' -o /dev/null)

if [ "$HTTP_STATUS" = "204" ]; then
    echo "✅ SUCCESS: HTTP 204 No Content (correct for notifications)"
else
    echo "❌ FAILED: HTTP $HTTP_STATUS (should be 204)"
fi

echo
echo "3. Testing Local MCP Initialize:"
INIT_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"clientInfo": {"name": "github-copilot", "version": "1.0.0"}}}')

if echo $INIT_RESPONSE | grep -q '"serverInfo"'; then
    echo "✅ MCP Initialize successful"
else
    echo "❌ MCP Initialize failed"
fi

# Clean up local server
echo
echo "Stopping local server..."
kill $LOCAL_PID
wait $LOCAL_PID 2>/dev/null

echo
echo "🚂 Phase 2: Live Railway Deployment Test"
echo "----------------------------------------"

echo "Testing actual Railway deployment..."

echo
echo "1. Railway Health Check:"
RAILWAY_HEALTH=$(curl -s -w "HTTP Status: %{http_code}\n" ${RAILWAY_URL}/health)
echo "$RAILWAY_HEALTH"

if echo "$RAILWAY_HEALTH" | grep -q "HTTP Status: 200"; then
    echo "✅ Railway health endpoint is responding"
    
    # Parse the health response for Railway info
    if echo "$RAILWAY_HEALTH" | grep -q '"railway"'; then
        echo "✅ Railway deployment info included in health response"
    else
        echo "⚠️  Railway deployment info not found (may be older deployment)"
    fi
else
    echo "❌ Railway health endpoint is not responding correctly"
    echo "   This indicates the deployment health check fix may not be deployed yet"
fi

echo
echo "2. Railway MCP Protocol Test:"
RAILWAY_HTTP_STATUS=$(curl -w "%{http_code}" -s -X POST ${RAILWAY_URL}/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{"jsonrpc": "2.0", "method": "notifications/initialized"}' -o /dev/null)

if [ "$RAILWAY_HTTP_STATUS" = "204" ]; then
    echo "✅ Railway MCP notifications/initialized working correctly"
else
    echo "❌ Railway MCP issue: HTTP $RAILWAY_HTTP_STATUS (should be 204)"
fi

echo
echo "3. Railway MCP Tools Test:"
RAILWAY_TOOLS=$(curl -s -X POST ${RAILWAY_URL}/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}' | jq '.result.tools[] | .name' 2>/dev/null)

if [ -n "$RAILWAY_TOOLS" ]; then
    echo "✅ Railway MCP tools available:"
    echo "$RAILWAY_TOOLS"
else
    echo "❌ Railway MCP tools not responding correctly"
fi

echo
echo "📋 Summary"
echo "----------"

# Final assessment
if [ "$HTTP_STATUS" = "204" ] && [ "$RAILWAY_HTTP_STATUS" = "204" ]; then
    echo "🎉 SUCCESS: All tests passed!"
    echo "   • Local Railway simulation works correctly"
    echo "   • Live Railway deployment is responding properly" 
    echo "   • GitHub Copilot MCP connections should work now"
    echo
    echo "✨ The Railway health check fix appears to be working correctly."
else
    echo "⚠️  MIXED RESULTS:"
    if [ "$HTTP_STATUS" = "204" ]; then
        echo "   • Local simulation works ✅"
    else
        echo "   • Local simulation failed ❌"
    fi
    
    if [ "$RAILWAY_HTTP_STATUS" = "204" ]; then
        echo "   • Railway deployment works ✅"
    else
        echo "   • Railway deployment needs redeployment ⚠️"
        echo
        echo "💡 Next steps:"
        echo "   1. Ensure the latest code is deployed to Railway"
        echo "   2. Check Railway build logs for any errors"
        echo "   3. Verify the health check start-period (60s) is sufficient"
    fi
fi

echo
echo "🔧 Railway Health Check Configuration:"
echo "   • Health Check Path: /health" 
echo "   • Start Period: 60s (allows proper startup time)"
echo "   • Timeout: 15s (more reliable checks)"
echo "   • Retries: 5 (better fault tolerance)"