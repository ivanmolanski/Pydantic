# 🚂 Railway MCP Server Troubleshooting Guide

This guide addresses the **HTTP 502 "Application failed to respond"** error that occurs when GitHub Copilot tries to connect to the Railway-deployed MCP server.

## 🐛 Problem Analysis

The error message:
```
Starting remote MCP client for pydanticAgent with url: https://pydantic-mcp-server-production.up.railway.app/mcp
Creating MCP client for pydanticAgent...
Connecting MCP client for pydanticAgent...
MCP transport for pydanticAgent closed
Failed to start MCP client for remote server pydanticAgent: Error: Error POSTing to endpoint (HTTP 502): {"status":"error","code":502,"message":"Application failed to respond","request_id":"kuiivpjcQbu_fdsILPU1MQ"}
```

This indicates that Railway receives the request but the MCP server application is not responding properly.

## 🔧 Common Causes and Solutions

### 1. Railway Service Sleeping
**Problem**: Railway puts inactive services to sleep after 5-10 minutes of inactivity.
**Solution**: The server now includes a keepalive system to prevent sleeping.

### 2. Port Configuration Issues
**Problem**: Railway assigns a dynamic PORT environment variable, but the server might be using a fixed port.
**Solution**: Updated the server to use Railway's dynamic PORT assignment.

### 3. Startup Timing Issues
**Problem**: Railway might route requests before the server is fully ready.
**Solution**: Added startup delays and retry mechanisms.

### 4. Authentication Failures
**Problem**: MCP requests might fail due to incorrect API key configuration.
**Solution**: Ensured consistent API key setup in Railway environment.

## 🚀 Quick Fix Steps

### Step 1: Use the Enhanced Debugging Script
```bash
./railway_debug_improved.sh
```

This script will:
- Check Railway service status
- Test the health and MCP endpoints
- Verify environment variables
- Offer automated redeployment

### Step 2: Manual Railway Fixes

If the debugging script doesn't resolve the issue:

```bash
# Login to Railway
railway login

# Link to your project
railway link

# Set required environment variables
railway env set MCP_API_KEY=mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs

# Redeploy with latest fixes
railway up --detach

# Monitor deployment
railway logs --follow
```

### Step 3: Verify the Fix

After redeployment, test the server:

```bash
# Get your Railway URL
RAILWAY_URL=$(railway get-url)

# Test health endpoint
curl "$RAILWAY_URL/health"

# Test MCP endpoint with authentication
curl -X POST "$RAILWAY_URL/mcp" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

Both should return successful responses.

### Step 4: Update GitHub Copilot Configuration

Once the server is working, update your MCP configuration:

```json
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://YOUR-RAILWAY-URL.up.railway.app/mcp",
      "headers": {
        "Authorization": "Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
```

Replace `YOUR-RAILWAY-URL` with your actual Railway deployment URL.

## 🔍 Advanced Troubleshooting

### Check Railway Logs
```bash
# Real-time logs
railway logs --follow

# Recent logs
railway logs --num 50
```

Look for:
- Server startup messages
- Port binding confirmations
- Authentication failures
- Connection errors

### Verify Environment Variables
```bash
railway env
```

Ensure you have:
- `MCP_API_KEY=mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs`
- `HOST=0.0.0.0` (should be set automatically)
- `PORT` (set automatically by Railway)

### Test Different Endpoints
```bash
# Health check (should work without auth)
curl https://your-railway-url.up.railway.app/health

# Tools list (requires auth)
curl https://your-railway-url.up.railway.app/tools \
  -H "Authorization: Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

# MCP protocol test
curl -X POST https://your-railway-url.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"clientInfo": {"name": "test", "version": "1.0.0"}}}'
```

## 🛡️ Server Improvements Made

The server has been enhanced with:

1. **Dynamic Port Handling**: Uses Railway's assigned PORT environment variable
2. **Railway Detection**: Automatically detects Railway environment and adjusts behavior
3. **Startup Delays**: Waits for container to stabilize before accepting connections
4. **Retry Logic**: Attempts to create server multiple times if initial creation fails
5. **Keepalive System**: Prevents Railway from putting the service to sleep
6. **Enhanced Error Handling**: Better logging and error reporting for debugging
7. **Socket Options**: Improved socket configuration for Railway compatibility
8. **Health Checks**: Docker-level health checks to ensure service availability

## 📞 Support

If you continue to experience issues:

1. Run `./railway_debug_improved.sh` and share the output
2. Check `railway logs --follow` for error messages
3. Verify your Railway deployment URL is accessible from external networks
4. Ensure your GitHub Copilot configuration matches the working server URL

The fixes implemented should resolve the HTTP 502 issues and provide a stable MCP server for GitHub Copilot integration.