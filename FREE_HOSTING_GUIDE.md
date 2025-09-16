# 🆓 Free Hosting Options for Pydantic MCP Server

This guide provides step-by-step instructions for deploying your Pydantic MCP server on various **free hosting platforms**.

## 🌟 Best Free Options (Recommended)

### 1. **Railway.app** (Recommended - Easiest)
**Free Tier**: 500 hours/month, 1GB RAM, 1GB storage

#### Quick Deploy:
```bash
# 1. Install Railway CLI
curl -fsSL https://railway.app/install.sh | sh

# 2. Login and deploy
railway login
railway new
railway add --from-path /path/to/your/Pydantic
railway up

# 3. Set environment variables
railway variables set MCP_API_KEY=your-secure-api-key-here
railway variables set PORT=8001

# 4. Deploy
railway deploy
```

#### Alternative: Deploy from GitHub
1. Go to [railway.app](https://railway.app) and sign up
2. Click "Deploy from GitHub repo"
3. Connect your GitHub account and select the Pydantic repo
4. Railway will auto-detect Python and deploy
5. Set environment variables in the Railway dashboard

### 2. **Render.com** (Great for Python)
**Free Tier**: 750 hours/month, 512MB RAM

#### Steps:
1. Go to [render.com](https://render.com) and sign up
2. Click "New +" → "Web Service"
3. Connect your GitHub repo
4. Configure:
   - **Build Command**: `pip install -e .`
   - **Start Command**: `python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"`
   - **Environment**: Python 3
5. Add environment variables:
   - `MCP_API_KEY`: your-secure-key
   - `PORT`: 8001
6. Click "Deploy"

### 3. **Fly.io** (Docker-focused)
**Free Tier**: 160GB-hours/month

#### Steps:
```bash
# 1. Install flyctl
curl -L https://fly.io/install.sh | sh

# 2. Login and launch
fly auth login
cd /path/to/Pydantic
fly launch

# 3. Follow prompts:
# - App name: your-mcp-server
# - Region: closest to you
# - Use existing Dockerfile: Yes

# 4. Set secrets
fly secrets set MCP_API_KEY=your-secure-api-key

# 5. Deploy
fly deploy
```

### 4. **Vercel** (Serverless Functions)
**Free Tier**: 100GB-hours/month

#### Setup:
1. Create `api/mcp.py`:
```python
from src.mcp_local_rag.simple_http_server import MCPHandler
from http.server import HTTPServer
import json
import os

def handler(request):
    # Serverless function wrapper
    # (implementation details...)
```

2. Deploy:
```bash
vercel --prod
vercel env add MCP_API_KEY
```

## 🛠 Platform-Specific Configuration

### Railway Configuration (`railway.toml`):
```toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "python -c 'from src.mcp_local_rag.simple_http_server import run_server; run_server()'"

[[envs.production]]
MCP_API_KEY = "$MCP_API_KEY"
PORT = "8001"
```

### Render Configuration (`render.yaml`):
```yaml
services:
  - type: web
    name: pydantic-mcp-server
    env: python
    buildCommand: pip install -e .
    startCommand: python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
    envVars:
      - key: MCP_API_KEY
        sync: false
      - key: PORT
        value: 8001
```

### Fly.io Configuration (`fly.toml`):
```toml
app = "your-mcp-server"

[build]
  image = "python:3.13-slim"

[http_service]
  internal_port = 8001
  force_https = true

[[env]]
  PORT = "8001"
```

## 🔐 Security for Free Hosting

### 1. Generate Secure API Key:
```bash
# Generate a secure random key
python -c "import secrets; print('mcp_' + secrets.token_urlsafe(32))"
```

### 2. Environment Variables:
Always set these environment variables:
- `MCP_API_KEY`: Your secure API key
- `PORT`: 8001 (or platform-specific)
- `HOST`: 0.0.0.0

### 3. Free SSL/HTTPS:
All recommended platforms provide free SSL certificates automatically.

## 🎯 Complete Deployment Example (Railway)

### Step-by-Step:
```bash
# 1. Clone the repo
git clone https://github.com/ivanmolanski/Pydantic.git
cd Pydantic

# 2. Install Railway CLI
curl -fsSL https://railway.app/install.sh | sh

# 3. Login to Railway
railway login

# 4. Create new project
railway new

# 5. Deploy from current directory  
railway add

# 6. Set environment variables
railway variables set MCP_API_KEY=$(python -c "import secrets; print('mcp_' + secrets.token_urlsafe(32))")
railway variables set PORT=8001
railway variables set HOST=0.0.0.0

# 7. Deploy
railway up
```

### Get Your URL:
```bash
# Get your deployment URL
railway domain
# Output: https://your-app-name.up.railway.app
```

## 📋 Testing Your Deployment

### Health Check:
```bash
curl https://your-app-name.up.railway.app/health
```

### Test MCP Endpoint:
```bash
curl -X POST https://your-app-name.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'
```

## 🔄 GitHub Repository Configuration

Once deployed, add to your GitHub repository's MCP settings:

```json
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://your-app-name.up.railway.app/mcp",
      "headers": {
        "Authorization": "Bearer your-api-key-here"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
```

## 💡 Free Tier Limitations & Tips

### Railway:
- ✅ 500 hours/month (generous)
- ✅ Custom domains
- ⚠️ Sleeps after 1 hour of inactivity
- 💡 Tip: Use cron-job.org to ping every 30 minutes to keep alive

### Render:
- ✅ 750 hours/month  
- ⚠️ Spins down after 15 minutes of inactivity
- ⚠️ Cold start delay (~30 seconds)
- 💡 Tip: Great for development/testing

### Fly.io:
- ✅ Always-on applications
- ✅ Global edge locations
- ⚠️ More complex setup
- 💡 Tip: Best for production-like usage

## 🆘 Troubleshooting

### Common Issues:

1. **Port Binding Error**:
   ```bash
   # Ensure PORT environment variable is set
   railway variables set PORT=8001
   ```

2. **Module Import Error**:
   ```bash
   # Check Python path in start command
   PYTHONPATH=/app/src python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
   ```

3. **Authentication Failing**:
   ```bash
   # Verify API key is set correctly
   railway variables
   ```

## 🚀 Next Steps

1. Choose a platform (Railway recommended for beginners)
2. Follow the deployment steps
3. Test your endpoints
4. Add the MCP configuration to your GitHub repository
5. Start using with GitHub Copilot!

All platforms listed provide excellent free tiers perfect for running your MCP server. Railway and Render are the most beginner-friendly options.