# 📋 Replicating Pydantic MCP Server in Any Repository

This guide explains how to set up the same MCP (Model Context Protocol) server that works with GitHub Copilot in any repository.

## 🚀 Quick Setup (5 Minutes)

### Option 1: Automated Setup Script

1. **Copy the setup script to your target repository:**

```bash
# In your target repository directory
curl -o setup_mcp_server.sh https://raw.githubusercontent.com/ivanmolanski/Pydantic/main/setup_mcp_server.sh
chmod +x setup_mcp_server.sh
./setup_mcp_server.sh
```

### Option 2: Manual Setup

If you prefer to set up manually or need to customize the setup:

#### Step 1: Copy Required Files

Copy these files from this repository to your target repository:

**Core Files:**
- `src/mcp_local_rag/` (entire directory)
- `pyproject.toml` 
- `railway.toml`
- `github-mcp-config.json`
- `deploy.sh`
- `Dockerfile`
- `docker-compose.yml`

**Documentation (optional but recommended):**
- `FREE_HOSTING_GUIDE.md`
- `GITHUB_COPILOT_SETUP.md`
- `HTTP_MCP_INTEGRATION.md`

#### Step 2: Install Dependencies

```bash
pip install -e .
```

#### Step 3: Test Locally

```bash
# Set your API key
export MCP_API_KEY="your-secure-api-key-here"

# Start the server
python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"

# In another terminal, test it
curl http://localhost:8001/health
curl -X POST http://localhost:8001/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-secure-api-key-here" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

#### Step 4: Deploy to Railway (Free)

1. Connect your repository to Railway
2. Set environment variable: `MCP_API_KEY=your-secure-api-key-here`
3. Deploy using the provided `railway.toml` configuration

#### Step 5: Configure GitHub Copilot

Update your `github-mcp-config.json` with your Railway deployment URL:

```json
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://your-app-name.up.railway.app/mcp",
      "headers": {
        "Authorization": "Bearer your-secure-api-key-here"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
```

## 🔧 Available MCP Tools

Once set up, GitHub Copilot will have access to these tools:

1. **get-project-info**: Get information about Java, Node.js, or TypeScript projects
2. **get-environment-tools**: Get development tools and best practices for specific environments  
3. **rag-search**: Search the web using RAG-like similarity sorting

## 🆘 Troubleshooting

### Common Issues

1. **Import Errors**: Ensure `PYTHONPATH=/app/src` in Railway environment
2. **401 Unauthorized**: Check API key matches in both server and GitHub config
3. **Health Check Fails**: Verify Railway deployment is active and accessible
4. **Missing Dependencies**: Run `pip install -e .` to install all required packages

### Validation

Use the included validation script to test your setup:

```bash
./validate_setup.sh
```

## 🌟 Benefits

With this MCP server running, GitHub Copilot will be able to:
- Understand your project structure and environment
- Provide context-aware suggestions for Java, Node.js, and TypeScript projects
- Search the web for current best practices and solutions
- Validate data structures using Pydantic models

## 📞 Support

If you encounter issues:
1. Check the logs in Railway dashboard
2. Verify all environment variables are set correctly
3. Test endpoints manually using curl commands above
4. Refer to the detailed guides in the documentation files