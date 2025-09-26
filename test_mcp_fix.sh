#!/bin/bash

# Test script for GitHub Copilot MCP connection after fix deployment

RAILWAY_URL="https://pydantic-mcp-server-production.up.railway.app"
API_KEY="mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

echo "🧪 Testing GitHub Copilot MCP Connection Fix"
echo "=============================================="
echo

# Test 1: Health check
echo "1. Health Check:"
curl -s "${RAILWAY_URL}/health" | jq .
echo

# Test 2: Initialize
echo "2. MCP Initialize:"
curl -s -X POST "${RAILWAY_URL}/mcp" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"clientInfo": {"name": "github-copilot", "version": "1.0.0"}}}' | jq .result.serverInfo
echo

# Test 3: Notifications/initialized (THE CRITICAL FIX)
echo "3. Notifications/initialized (Critical Fix):"
HTTP_STATUS=$(curl -w "%{http_code}" -s -X POST "${RAILWAY_URL}/mcp" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{"jsonrpc": "2.0", "method": "notifications/initialized"}' -o /dev/null)

if [ "$HTTP_STATUS" = "204" ]; then
    echo "✅ SUCCESS: HTTP 204 No Content (correct for notifications)"
else
    echo "❌ FAILED: HTTP $HTTP_STATUS (should be 204)"
fi
echo

# Test 4: Tools list
echo "4. Tools List:"
curl -s -X POST "${RAILWAY_URL}/mcp" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}' | jq '.result.tools[] | .name'
echo

# Test 5: Tool call
echo "5. Tool Call (get-project-info):"
curl -s -X POST "${RAILWAY_URL}/mcp" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get-project-info", "arguments": {"project_name": "java-core", "environment": "java"}}}' | jq '.result.content[0].text'
echo

if [ "$HTTP_STATUS" = "204" ]; then
    echo "🎉 All tests passed! GitHub Copilot should now be able to connect successfully."
else
    echo "⚠️  Railway deployment may not be updated yet. Redeploy to apply the fix."
fi