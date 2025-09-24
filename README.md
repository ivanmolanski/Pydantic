# Pydantic MCP Server for GitHub Copilot Integration

## 🌟 About This Project

This repository provides a **HTTP-based Model Context Protocol (MCP) server** built with Pydantic, specifically designed for integration with **GitHub Copilot coding agent**. The server exposes tools that help developers working with Java, Node.js, and TypeScript environments.

### ✨ Key Features:
- **HTTP Transport** - Compatible with GitHub Copilot's remote agent architecture
- **Multi-Language Support** - Java, Node.js, TypeScript tooling
- **Web Search Integration** - RAG-like search using DuckDuckGo
- **Project Information** - Environment-specific configuration details
- **Secure API** - Token-based authentication for production

### 🚀 Quick Start

**The server is already deployed and running on Railway at:**
- **URL**: `https://pydantic-mcp-server-production.up.railway.app/mcp`
- **API Key**: `mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs`

**For GitHub Copilot Integration, use this configuration:**
```json
{
  "mcpServers": {
    "pydanticAgent": {
      "type": "http",
      "url": "https://pydantic-mcp-server-production.up.railway.app/mcp",
      "headers": {
        "Authorization": "Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"
      },
      "tools": ["get-project-info", "get-environment-tools", "rag-search"]
    }
  }
}
```

## � Available Tools

### 1. **get-project-info**
Retrieve information about projects in different environments.

### 2. **get-environment-tools** 
Get development tools and best practices for specific environments.

### 3. **rag-search**
Web search with RAG-like similarity sorting using DuckDuckGo.

## 🧪 Testing the Server

### Health Check
```bash
curl https://pydantic-mcp-server-production.up.railway.app/health
```

### Test MCP Protocol
```bash
curl -X POST https://pydantic-mcp-server-production.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

## 📊 Environment Support Matrix

| Environment | Project Info | Tool Recommendations | Code Analysis |
|-------------|-------------|---------------------|---------------|
| Java ☕     | ✅ Spring Boot, Maven, Gradle | ✅ JUnit, Mockito, TestContainers | ✅ Pattern detection |
| Node.js 🟢  | ✅ Express, package.json | ✅ npm, yarn, Jest | ✅ Module analysis |
| TypeScript 🔷 | ✅ React, Vite, tsconfig | ✅ tsc, ESLint, Vitest | ✅ Type checking |

## 📄 License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.
