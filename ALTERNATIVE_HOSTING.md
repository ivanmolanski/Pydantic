# Alternative Hosting Setup Guide

This guide provides step-by-step instructions for deploying the Pydantic MCP Server on various free hosting platforms as alternatives to Railway.

## 🚨 Current Issue Fix

**FIXED**: The main issue was a mismatched API key between GitHub Copilot config and the deployed server.
- ✅ **Correct API Key**: `mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs`
- ✅ **GitHub Copilot Config**: Updated to use correct API key
- ✅ **All Scripts**: Updated with correct API key

## 🌟 Platform Options (Ranked by Ease of Use)

### 1. **Render.com** (Recommended - Most Stable)

**Pros**: Great for Python, generous free tier, reliable
**Cons**: Slower cold starts than Railway

#### Setup Steps:
```bash
# 1. Fork/clone this repo
git clone https://github.com/ivanmolanski/Pydantic.git
cd Pydantic

# 2. Create Render account and connect GitHub
# 3. Create new Web Service from your repo
```

**Environment Variables** (in Render dashboard):
```
MCP_API_KEY=mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs
PORT=10000
HOST=0.0.0.0
PYTHONPATH=/opt/render/project/src
```

**GitHub Copilot Config**:
```json
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://your-app-name.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
```

### 2. **Vercel** (Serverless - Fast)

**Pros**: Fast cold starts, excellent for API endpoints
**Cons**: Function timeout limits, different architecture

#### Setup Steps:
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

Create `vercel.json`:
```json
{
  "builds": [
    {
      "src": "src/mcp_local_rag/vercel_handler.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/mcp",
      "dest": "src/mcp_local_rag/vercel_handler.py"
    },
    {
      "src": "/health",
      "dest": "src/mcp_local_rag/vercel_handler.py"
    }
  ],
  "env": {
    "MCP_API_KEY": "mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
  }
}
```

### 3. **Fly.io** (Docker-Based - Very Fast)

**Pros**: Fast deployment, Docker-based, good free tier
**Cons**: Requires Docker knowledge

#### Setup Steps:
```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Initialize and deploy
flyctl apps create your-mcp-server
flyctl deploy
```

### 4. **Heroku** (Classic - Easy but Paid)

**Pros**: Mature platform, good documentation
**Cons**: No longer free, requires payment

### 5. **Railway.app** (Current - Working)

**Status**: ✅ Already working, just needed API key fix
**URL**: `https://pydantic-mcp-server-production.up.railway.app/mcp`

## 🔧 Quick Migration Script

If you want to switch from Railway to another platform:

```bash
#!/bin/bash

# Quick Platform Switch Script
echo "🚀 Switching MCP Server Platform"

# Choose platform
echo "Select platform:"
echo "1) Render"
echo "2) Vercel" 
echo "3) Fly.io"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo "📋 Render Setup:"
        echo "1. Go to https://render.com"
        echo "2. Connect your GitHub repo"
        echo "3. Set environment variables as shown above"
        echo "4. Deploy"
        ;;
    2)
        echo "📋 Vercel Setup:"
        echo "Running vercel deployment..."
        npx vercel --prod
        ;;
    3)
        echo "📋 Fly.io Setup:"
        echo "1. Install flyctl: curl -L https://fly.io/install.sh | sh"
        echo "2. Run: flyctl apps create your-mcp-server"
        echo "3. Run: flyctl deploy"
        ;;
esac
```

## 🧪 Testing Your Deployment

After deploying to any platform, test with:

```bash
# Replace YOUR_URL with your actual deployment URL
DEPLOYMENT_URL="https://your-deployment-url.com"

# Test health endpoint
curl "$DEPLOYMENT_URL/health"

# Test MCP endpoint
curl -X POST "$DEPLOYMENT_URL/mcp" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

## 📋 Platform Comparison

| Platform | Free Tier | Cold Start | Reliability | Ease of Setup |
|----------|-----------|------------|-------------|---------------|
| Railway  | ✅        | Fast       | ⭐⭐⭐⭐       | ⭐⭐⭐⭐⭐      |
| Render   | ✅        | Slow       | ⭐⭐⭐⭐⭐      | ⭐⭐⭐⭐       |
| Vercel   | ✅        | Very Fast  | ⭐⭐⭐⭐       | ⭐⭐⭐        |
| Fly.io   | ✅        | Fast       | ⭐⭐⭐⭐       | ⭐⭐⭐        |
| Heroku   | ❌        | Medium     | ⭐⭐⭐⭐⭐      | ⭐⭐⭐⭐       |

## 💡 Recommendations

1. **Keep Railway**: Current deployment works perfectly with the API key fix
2. **Backup Option**: Set up Render.com as a backup
3. **Fast Option**: Use Vercel for ultra-fast response times
4. **Docker Fans**: Go with Fly.io for container-based deployment

## 🆘 If You Still Get HTTP 502

1. **Check API Key**: Ensure both server and client use `mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs`
2. **Test Manually**: Use curl commands above to test directly
3. **Check Logs**: Look at platform logs for errors
4. **Try Alternative**: Switch to Render.com for more stability