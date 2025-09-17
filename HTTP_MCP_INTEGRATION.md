# Pydantic MCP Server for GitHub Copilot Integration

## Overview

This repository provides a **HTTP-based Model Context Protocol (MCP) server** built with Pydantic, specifically designed for integration with **GitHub Copilot coding agent**. The server exposes tools that help developers working with Java, Node.js, and TypeScript environments.

### 🎯 Key Features

- **HTTP Transport**: Compatible with GitHub Copilot's remote agent architecture
- **Multi-Language Support**: Tools for Java, Node.js, and TypeScript environments
- **Web Search Integration**: RAG-like web search functionality using DuckDuckGo
- **Project Information**: Retrieve project metadata and configuration details
- **Development Tools Guide**: Environment-specific tooling recommendations
- **Secure API**: Optional API key authentication for production deployment

## 🛠 Architecture

Unlike traditional MCP servers that use `stdio` transport for local IDE integration, this server implements **HTTP transport** to work with GitHub's cloud-hosted coding agent. The server acts as a web service that GitHub Copilot can call remotely.

```
GitHub Copilot Agent → HTTP Request → MCP Server → Tool Execution → Response
```

## 📦 Installation & Setup

### 1. Clone and Install Dependencies

```bash
git clone https://github.com/ivanmolanski/Pydantic.git
cd Pydantic
pip install -e .
```

### 2. Start the Server

#### Simple HTTP Server (Recommended)
```bash
python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
```

#### With Environment Variables
```bash
export HOST=0.0.0.0
export PORT=8001
export MCP_API_KEY=your-secure-api-key
python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
```

#### Using Docker
```bash
# Build the image
docker build -t pydantic-mcp-server .

# Run with Docker
docker run -p 8001:8001 -e MCP_API_KEY=your-api-key pydantic-mcp-server

# Or use docker-compose
docker-compose up
```

## 🔧 Available Tools

### 1. **get-project-info**
Retrieve information about projects in different environments.

**Input Schema:**
```json
{
  "project_name": "java-core",
  "environment": "java"
}
```

**Example Response:**
```
**java-core - JAVA Environment:**
- Framework: Spring Boot 3.2
- Build_Tool: Maven
- Java_Version: 17
- Dependencies: spring-boot-starter-web, spring-boot-starter-data-jpa, junit5
- Architecture: Microservices with REST APIs
```

### 2. **get-environment-tools**
Get development tools and best practices for specific environments.

**Input Schema:**
```json
{
  "environment": "typescript",
  "query": "testing"
}
```

**Example Response:**
```
**TYPESCRIPT Tools matching 'testing':**

**Testing:**
- **jest**: JavaScript testing framework
- **vitest**: Fast Vite-native test framework
```

### 3. **rag-search**
Web search with RAG-like similarity sorting using DuckDuckGo.

**Input Schema:**
```json
{
  "query": "TypeScript best practices 2024",
  "num_results": 10,
  "top_k": 5
}
```

## 🌐 GitHub Copilot Integration

### Step 1: Deploy Your Server

Deploy the server to a publicly accessible URL using:

#### 🆓 **Free Options** (Recommended for getting started):
- **Railway.app** - 500 hours/month, easiest setup
- **Render.com** - 750 hours/month, Python-optimized  
- **Fly.io** - 160GB-hours/month, Docker-based
- **Vercel** - 100GB-hours/month, serverless functions

📖 **[Complete Free Hosting Guide →](FREE_HOSTING_GUIDE.md)**

#### 💰 **Paid Options** (For production):
- **Cloud platforms**: AWS, Google Cloud, Azure
- **Container services**: Docker, Kubernetes  
- **Platform-as-a-Service**: Heroku, Railway Pro, Render Pro

### Step 2: Configure GitHub Repository

1. Go to your GitHub repository settings
2. Navigate to **Copilot coding agent** section
3. Add the following **MCP configuration**:

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

### Step 3: Set Up Authentication

For production deployment, always set the `MCP_API_KEY` environment variable:

```bash
export MCP_API_KEY="your-secure-random-api-key-here"
```

The server will require this key in the `Authorization: Bearer <token>` header.

### Step 4: Troubleshooting Connection Issues

If you encounter HTTP 401 "Unauthorized" errors, see the comprehensive troubleshooting guide:

📖 **[GitHub Copilot Setup & Troubleshooting Guide →](GITHUB_COPILOT_SETUP.md)**

## 🚦 Universal Pydantic Validation

All MCP tool calls and schemas are now strictly validated using Pydantic models. This ensures:
- Every request and response is type-safe and schema-compliant
- Invalid input is rejected with clear error messages
- Output schemas are always correct and documented

### How to Use
- Always use this MCP server for code validation, generation, and schema enforcement
- All code, configs, and API schemas must be validated using Pydantic models via the MCP server
- If you use Copilot or any coding agent, configure it to use this MCP server for all validation and code generation tasks

### Example Error Response
If you send invalid input, you will receive:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Input validation error: ...",
    "data": {"http_status": 400}
  }
}
```

### Recommended Copilot Configuration
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

---

## 🏆 Best Practice: Always Validate with Pydantic
- All code, configs, and API schemas must be validated using Pydantic models via this MCP server
- This ensures robust, error-free, and type-safe code for all integrations
- Use the MCP server for all code generation, validation, and schema enforcement

---

## 🧪 Testing the Server

### Health Check
```bash
curl http://localhost:8001/health
```

### List Available Tools (with Authentication)
```bash
curl http://localhost:8001/tools \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Test MCP Protocol (with Authentication)
```bash
curl -X POST http://localhost:8001/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'
```

### Execute a Tool (with Authentication)
```bash
curl -X POST http://localhost:8001/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "get-project-info",
      "arguments": {
        "project_name": "node-api",
        "environment": "typescript"
      }
    }
  }'
```

## 🔒 Security Considerations

1. **Always use HTTPS** in production deployments
2. **Set strong API keys** using the `MCP_API_KEY` environment variable
3. **Implement rate limiting** for public deployments
4. **Use reverse proxy** (nginx) for additional security
5. **Monitor logs** for suspicious activity

## 🚀 Quick Deployment Examples

### Railway (Recommended - Free & Easy)
```bash
# Quick deploy in 3 commands
railway login
railway new --from-repo https://github.com/ivanmolanski/Pydantic
railway variables set MCP_API_KEY=$(openssl rand -base64 32)
```

### Render  
```bash
# Deploy from GitHub repo at render.com
# Build: pip install -e .
# Start: python -c "from src.mcp_local_rag.simple_http_server import run_server; run_server()"
```

### Docker (Self-hosted)
```bash
git clone https://github.com/ivanmolanski/Pydantic.git
cd Pydantic
docker build -t mcp-server .
docker run -d -p 8001:8001 -e MCP_API_KEY=your-key mcp-server
```

📖 **[Complete Free Hosting Guide with Step-by-Step Instructions →](FREE_HOSTING_GUIDE.md)**

## 📊 Environment Support Matrix

| Environment | Project Info | Tool Recommendations | Code Analysis |
|-------------|-------------|---------------------|---------------|
| Java ☕     | ✅ Spring Boot, Maven, Gradle | ✅ JUnit, Mockito, TestContainers | ✅ Pattern detection |
| Node.js 🟢  | ✅ Express, package.json | ✅ npm, yarn, Jest | ✅ Module analysis |
| TypeScript 🔷 | ✅ React, Vite, tsconfig | ✅ tsc, ESLint, Vitest | ✅ Type checking |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-tool`
3. Add your tool to `simple_http_server.py`
4. Test with the MCP protocol
5. Submit a pull request

## 📄 License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

This project extends the work from [nkapila6/mcp-local-rag](https://github.com/nkapila6/mcp-local-rag) and adapts it for GitHub Copilot integration.