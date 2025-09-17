# Pydantic MCP Server Repository

## 🌟 About This Project

This repository provides **TWO complementary MCP server implementations**:

1. **Local RAG Server** (Original) - For Claude Desktop and local development
2. **HTTP MCP Server** (New) - For GitHub Copilot coding agent integration

## 🎯 What's New: GitHub Copilot Integration

We've added a **complete HTTP-based MCP server** specifically designed for **GitHub Copilot coding agent**. This server exposes powerful tools for Java, Node.js, and TypeScript development environments.

### ✨ Key Features:
- **HTTP Transport** - Compatible with GitHub's cloud-hosted agent
- **Multi-Language Support** - Java, Node.js, TypeScript tooling
- **Web Search Integration** - RAG-like search using DuckDuckGo
- **Project Information** - Environment-specific configuration details
- **Secure API** - Token-based authentication for production

### 🚀 Quick Start for GitHub Copilot

1. **Start the HTTP server:**
```bash
python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
```

2. **Deploy to your preferred cloud platform (free options available!)**

3. **Add this JSON to your GitHub repository's MCP configuration:**
```json
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://your-server-domain.com/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_TOKEN_HERE"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
```

📖 **[Complete Integration Guide →](HTTP_MCP_INTEGRATION.md)**

## 🔄 Replicate This Setup in Any Repository

Want to add this same MCP server functionality to another repository? We've made it super easy!

### 🚀 One-Line Installation

In your target repository directory:

```bash
curl -sSL https://raw.githubusercontent.com/ivanmolanski/Pydantic/main/install_mcp.sh | bash
```

This will:
- ✅ Copy all necessary files
- ✅ Install dependencies
- ✅ Generate secure configuration
- ✅ Create deployment templates
- ✅ Set up validation scripts

### 📋 Manual Replication

For more control, follow the **[Replication Guide →](REPLICATION_GUIDE.md)**

### 🛠 Available Scripts

- `setup_mcp_server.sh` - Complete automated setup
- `generate_config.sh` - Generate customized configurations
- `validate_mcp_setup.sh` - Test your setup
- `install_mcp.sh` - One-line installer

### 🌟 Why Replicate?

Each repository with this MCP server gets:
- **Context-aware GitHub Copilot** suggestions
- **Environment-specific** tooling recommendations  
- **Web search** capabilities for current best practices
- **Project analysis** tools for Java, Node.js, TypeScript
- **Universal Pydantic validation** for all data structures

---

## 📚 Original Local RAG Implementation

### Acknowledgments
The original local RAG implementation is based on the excellent work by [nkapila6](https://github.com/nkapila6/mcp-local-rag). We thank them for making this valuable resource available.

<img src='images/rag.jpeg' width='200' height='200'>

# mcp-local-rag
"primitive" RAG-like web search model context protocol (MCP) server that runs locally. ✨ no APIs ✨ 

<img src='images/flowchart.png' width='1000' height='500'>

# Installation instructions
1. You would need to install ```uv```: https://docs.astral.sh/uv/

## If you do not want to clone in Step 2.
Just paste this directly into Claude config. You can find the configuration paths here: https://modelcontextprotocol.io/quickstart/user
```json
{
    "mcpServers": {
        "mcp-local-rag":{
            "command": "uvx",
            "args": [
            "--python=3.13",
            "--from",
            "git+https://github.com/nkapila6/mcp-local-rag",
            "mcp-local-rag"
            ]
        }
    }
}
```

## Otherwise:
2. Clone this GitHub repository (OPTIONAL, can be skipped with above config)
```terminal
git clone https://github.com/nkapila6/mcp-local-rag
```

3. Add the following to your Claude config. You can find the configuration paths here: https://modelcontextprotocol.io/quickstart/user
```json
{
  "mcpServers": {
    "mcp-local-rag": {
      "command": "uv",
      "args": [
        "--directory",
        "<path where this folder is located>/mcp-local-rag/",
        "run",
        "src/mcp_local_rag/main.py"
      ]
    }
  }
}
```
# Example use

## On prompt
When asked to fetch/lookup/search the web, the model prompts you to use MCP server for the chat.

In the example, have asked it about Google's latest Gemma models released yesterday. This is new info that Claude is not aware about.
<img src='images/mcp_prompted.png'>

## Result
The result from the local `rag_search` helps the model answer with new info.
<img src='images/mcp_result.png'>
