# GitHub Copilot MCP Server Setup Guide

## 🚨 Troubleshooting HTTP 401 "Unauthorized" Errors

If you're getting a 401 Unauthorized error when GitHub Copilot tries to connect, follow these steps:

### Step 1: Verify Railway Deployment is Running

1. Go to your Railway dashboard: https://railway.app/dashboard
2. Find your `pydantic-mcp-server` project
3. Check the deployment status - it should show "Active"
4. Click on your deployment to get the actual URL

### Step 2: Set the Correct API Key in Railway

1. In your Railway project dashboard, go to **Variables** tab
2. Update/Add these environment variables:
   - **Key**: `MCP_API_KEY`
   - **Value**: `your-secure-api-key1` (your actual API key)
   - **Key**: `PYTHONPATH`
   - **Value**: `/app/src` (replace `/opt/render/project/src`)
   - **Key**: `HOST`
   - **Value**: `0.0.0.0` (replace `[::]`)
   - **Key**: `PORT`
   - **Value**: `8001`
3. **Deploy** the changes - Railway will restart your server

### Step 3: Test Your Deployment

Replace `your-actual-railway-url` with your actual Railway deployment URL:

```bash
# Test health endpoint (no auth required)
curl https://your-actual-railway-url.up.railway.app/health

# Test MCP endpoint (auth required)
curl -X POST https://your-actual-railway-url.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-secure-api-key1" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

**Expected Response for Health Check:**
```json
{
  "status": "healthy",
  "server": "pydantic-mcp-server",
  "version": "1.0.0"
}
```

**Expected Response for MCP Tools:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "get-project-info",
        "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
        "inputSchema": { ... }
      },
      ...
    ]
  }
}
```

### Step 4: Update GitHub Copilot Configuration

Update your repository's MCP configuration (usually in `.github/copilot/` or repository settings):

```json
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://YOUR-ACTUAL-RAILWAY-URL.up.railway.app/mcp",
      "headers": {
        "Authorization": "Bearer your-secure-api-key1"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
```

## 🔍 Common Issues and Solutions

### Issue 1: Railway Using Wrong Builder (Dockerfile vs NIXPACKS)
- **Cause**: Railway detected Dockerfile and used it instead of NIXPACKS
- **Solution**: This is actually fine! The Dockerfile has been updated to work correctly with Railway
- **Action**: Just ensure environment variables are set correctly (see Step 2 above)

### Issue 2: "Could not resolve host"
- **Cause**: Incorrect Railway URL in configuration
- **Solution**: Get the correct URL from Railway dashboard

### Issue 3: HTTP 401 "Unauthorized" 
- **Cause**: API key mismatch between Railway environment and GitHub config
- **Solution**: Ensure both use the same API key (`your-secure-api-key1`)
- **Check**: Railway Variables tab should show `MCP_API_KEY = your-secure-api-key1`

### Issue 4: Wrong Environment Variables
- **Cause**: Copy-paste from other platforms (Render, Heroku)
- **Solution**: Use these Railway-specific values:
  - `PYTHONPATH = /app/src` (not `/opt/render/project/src`)
  - `HOST = 0.0.0.0` (not `[::]`)
  - `MCP_API_KEY = your-secure-api-key1` (your actual API key)

### Issue 5: Server not starting
- **Cause**: Missing dependencies or configuration issues
- **Solution**: Check Railway logs for Python import errors

### Issue 6: DNS/Network issues
- **Cause**: Railway deployment region or networking
- **Solution**: Wait a few minutes for DNS propagation, or redeploy

## 🎛️ Alternative: Generate New API Key

If you prefer a more secure API key:

```bash
# Generate a new secure API key
python -c "import secrets; print('mcp_' + secrets.token_urlsafe(32))"
```

Then update both:
1. Railway environment variable `MCP_API_KEY`
2. GitHub Copilot configuration `Authorization: Bearer <new-key>`

## 📋 Quick Checklist

- [ ] Railway deployment is active and running
- [ ] `MCP_API_KEY` environment variable is set in Railway
- [ ] Health endpoint returns 200 OK
- [ ] MCP endpoint returns tools list with correct auth
- [ ] GitHub configuration uses the correct Railway URL
- [ ] GitHub configuration uses the correct API key
- [ ] Both server and client use the same API key

## 🔧 Local Testing

Test locally before deploying:

```bash
# Set the API key and start server
export MCP_API_KEY="your-secure-api-key1"
python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"

# In another terminal, test the endpoint
curl -X POST http://localhost:8001/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-secure-api-key1" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```