from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi import Security
security = HTTPBearer(auto_error=False)
def verify_api_key(credentials: Optional[HTTPAuthorizationCredentials] = Security(security)):
    api_key = os.environ.get("MCP_API_KEY")
    if not api_key:
        return None
    if not credentials or credentials.scheme.lower() != "bearer" or credentials.credentials != api_key:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")
    return credentials.credentials

"""
HTTP-based MCP Server for GitHub Copilot Integration
Implements a FastAPI web server that exposes MCP tools via HTTP transport.
"""

from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi import Security
security = HTTPBearer(auto_error=False)

from typing import Dict, List, Any, Optional
from pydantic import BaseModel, Field
import json
import os

from fastapi import FastAPI, Request, HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

"""
NOTE: Removed import of McpServer, FastMCP, and McpTool because 'McpServer' is not a known symbol in mcp.server. If you have a local MCP server implementation, import it here. Otherwise, use your own server logic below.
"""




# Authentication setup
security = HTTPBearer(auto_error=False)

class ProjectInfoInput(BaseModel):
    """Input schema for project information retrieval."""
    project_name: str = Field(..., description="The name of the project to retrieve information for")
    environment: Optional[str] = Field("general", description="Environment type: java, node, typescript, or general")

class EnvironmentToolsInput(BaseModel):
    """Input schema for environment-specific tooling information."""
    environment: str = Field(..., description="Environment type: java, node, typescript")
    query: Optional[str] = Field("", description="Specific query about tools or libraries")

class CodeAnalysisInput(BaseModel):
    """Input schema for code analysis requests."""
    code_snippet: str = Field(..., description="Code snippet to analyze")
    language: str = Field(..., description="Programming language of the code")

# Initialize MCP server

async def get_project_info(params: ProjectInfoInput) -> str:
    """
    Retrieve project information based on name and environment.
    Simulates accessing project metadata, documentation, or configuration files.
    """
    project_name = params.project_name.lower() if params.project_name else ""
    environment = params.environment.lower() if params.environment else "general"
    
    # Simulated project information database
    projects = {
        "java-core": {
            "description": "Enterprise Java application with Spring Boot backend",
            "java": {
                "framework": "Spring Boot 3.2",
                "build_tool": "Maven",
                "java_version": "17",
                "dependencies": ["spring-boot-starter-web", "spring-boot-starter-data-jpa", "junit5"],
                "architecture": "Microservices with REST APIs"
            },
            "general": "Core Java business logic service with Spring Boot framework"
        },
        "node-api": {
            "description": "RESTful API service built with Node.js and TypeScript",
            "node": {
                "runtime": "Node.js 18+",
                "framework": "Express.js",
                "package_manager": "npm",
                "dependencies": ["express", "@types/express", "typescript", "jest"],
                "architecture": "RESTful microservice"
            },
            "typescript": {
                "version": "5.0+",
                "config": "Strict mode enabled",
                "tools": ["ESLint", "Prettier", "Jest"],
                "types": "Full type coverage with @types packages"
            },
            "general": "Node.js TypeScript API service with Express framework"
        },
        "frontend-app": {
            "description": "React-based frontend application with TypeScript",
            "typescript": {
                "framework": "React 18",
                "bundler": "Vite",
                "state": "Redux Toolkit",
                "testing": "Vitest + React Testing Library",
                "styling": "Tailwind CSS"
            },
            "node": {
                "runtime": "Node.js 18+",
                "package_manager": "yarn",
                "scripts": "Build, test, lint automation"
            },
            "general": "Modern React frontend with TypeScript and Vite"
        }
    }
    
    if project_name not in projects:
        return f"Project '{params.project_name}' not found. Available projects: {', '.join(projects.keys())}"
    
    project = projects[project_name]
    
    if environment in project:
        env_info = project[environment]
        if isinstance(env_info, dict):
            info_parts = [f"**{params.project_name} - {environment.upper()} Environment:**"]
            for key, value in env_info.items():
                if isinstance(value, list):
                    info_parts.append(f"- {key.title()}: {', '.join(value)}")
                else:
                    info_parts.append(f"- {key.title()}: {value}")
            return "\n".join(info_parts)
        else:
            return f"**{params.project_name}:** {env_info}"
    else:
        return f"**{params.project_name}:** {project['description']}"

async def get_environment_tools(params: EnvironmentToolsInput) -> str:
    """
    Provide information about development tools and best practices for specific environments.
    """
    environment = params.environment.lower() if params.environment else ""
    query = params.query.lower() if params.query else ""
    
    tools_info = {
        "java": {
            "build_tools": {
                "maven": "XML-based project management and build tool",
                "gradle": "Groovy/Kotlin DSL build automation tool",
                "sbt": "Scala Build Tool, also used for Java projects"
            },
            "testing": {
                "junit5": "Modern Java testing framework",
                "mockito": "Mocking framework for unit tests", 
                "testcontainers": "Integration testing with Docker containers",
                "spring-boot-test": "Testing support for Spring Boot applications"
            },
            "frameworks": {
                "spring-boot": "Production-ready Java application framework",
                "quarkus": "Kubernetes-native Java framework",
                "micronaut": "Modern microservices framework"
            },
            "ide": {
                "intellij": "JetBrains IntelliJ IDEA",
                "eclipse": "Eclipse IDE for Java Developers", 
                "vscode": "Visual Studio Code with Java extensions"
            }
        },
        "node": {
            "package_managers": {
                "npm": "Default Node.js package manager",
                "yarn": "Fast, reliable package manager",
                "pnpm": "Efficient package manager with hard links"
            },
            "testing": {
                "jest": "JavaScript testing framework",
                "mocha": "Feature-rich test framework",
                "vitest": "Fast Vite-native test framework"
            },
            "frameworks": {
                "express": "Minimal web application framework",
                "fastify": "High-performance web framework",
                "nest": "Progressive Node.js framework"
            },
            "tools": {
                "nodemon": "Development server with auto-restart",
                "eslint": "JavaScript/TypeScript linter",
                "prettier": "Code formatter"
            }
        },
        "typescript": {
            "compilers": {
                "tsc": "Official TypeScript compiler",
                "esbuild": "Fast TypeScript/JavaScript bundler",
                "swc": "Super-fast TypeScript/JavaScript compiler"
            },
            "frameworks": {
                "react": "UI library with TypeScript support",
                "vue": "Progressive framework with TypeScript",
                "angular": "Full-featured TypeScript framework"
            },
            "tools": {
                "ts-node": "Execute TypeScript directly",
                "typescript-eslint": "TypeScript-specific ESLint rules",
                "type-fest": "Collection of essential TypeScript types"
            },
            "bundlers": {
                "webpack": "Module bundler with TypeScript support",
                "vite": "Fast build tool with native TypeScript",
                "rollup": "Module bundler for libraries"
            }
        }
    }
    
    if environment not in tools_info:
        return f"Environment '{params.environment}' not supported. Available: {', '.join(tools_info.keys())}"
    
    env_tools = tools_info[environment]
    
    if query:
        # Filter results based on query
        relevant_sections = []
        for category, tools in env_tools.items():
            if query in category.lower() or any(query in tool.lower() or query in desc.lower() for tool, desc in tools.items()):
                relevant_sections.append((category, tools))
        
        if relevant_sections:
            result = [f"**{environment.upper()} Tools matching '{params.query}':**\n"]
            for category, tools in relevant_sections:
                result.append(f"**{category.title()}:**")
                for tool, desc in tools.items():
                    result.append(f"- **{tool}**: {desc}")
                result.append("")
            return "\n".join(result)
        else:
            return f"No {environment} tools found matching '{params.query}'"
    else:
        # Return all tools for the environment
        result = [f"**{environment.upper()} Development Tools:**\n"]
        for category, tools in env_tools.items():
            result.append(f"**{category.title()}:**")
            for tool, desc in tools.items():
                result.append(f"- **{tool}**: {desc}")
            result.append("")
        return "\n".join(result)

async def analyze_code(params: CodeAnalysisInput) -> str:
    """
    Analyze code snippets and provide insights about language-specific patterns.
    """
    language = params.language.lower() if params.language else ""
    code = params.code_snippet.strip()
    
    if not code:
        return "No code snippet provided for analysis."
    
    # Basic code analysis patterns
    analysis = []
    
    if language == "java":
        if "public class" in code:
            analysis.append("✅ Java class definition found")
        if "public static void main" in code:
            analysis.append("✅ Main method detected - executable class")
        if "@" in code:
            analysis.append("✅ Annotations found - modern Java practices")
        if "import" in code:
            analysis.append("✅ Import statements present")
        if "throws" in code:
            analysis.append("⚠️  Exception handling declared")
    
    elif language in ["javascript", "typescript"]:
        if "function" in code or "=>" in code:
            analysis.append("✅ Function definitions found")
        if "const " in code or "let " in code:
            analysis.append("✅ Modern variable declarations (const/let)")
        if "import" in code or "require(" in code:
            analysis.append("✅ Module imports detected")
        if language == "typescript":
            if ":" in code and ("string" in code or "number" in code or "boolean" in code):
                analysis.append("✅ TypeScript type annotations found")
            if "interface" in code or "type " in code:
                analysis.append("✅ TypeScript type definitions present")
        if "async" in code or "await" in code:
            analysis.append("✅ Asynchronous code patterns detected")
    
    elif language == "python":
        if "def " in code:
            analysis.append("✅ Function definitions found")
        if "class " in code:
            analysis.append("✅ Class definitions present")
        if "import " in code or "from " in code:
            analysis.append("✅ Module imports detected")
        if "async def" in code or "await " in code:
            analysis.append("✅ Asynchronous code patterns found")
    if not analysis:
        analysis.append("⚠️  No specific patterns detected for this language")
    return "\n".join(analysis)

# Register tools with the MCP server



# Create FastAPI application
app = FastAPI(
    title="Pydantic MCP Server for GitHub Copilot",
    description="HTTP-based Model Context Protocol server for GitHub Copilot integration",
    version="1.0.0"
)

# Add CORS middleware for cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to specific domains
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "server": "pydantic-mcp-server", "version": "1.0.0"}

@app.get("/")
async def root():
    """Root endpoint with server information."""
    return {
        "name": "Pydantic MCP Server",
        "description": "HTTP-based MCP server for GitHub Copilot integration",
        "version": "1.0.0",
        "endpoints": {
            "mcp": "/mcp - MCP protocol endpoint",
            "health": "/health - Health check",
            "tools": "/tools - List available tools"
        }
    }

@app.get("/tools")
async def list_tools(api_key: str = Security(verify_api_key)):
    """List available MCP tools."""
    tools = [
        {
            "name": "get-project-info",
            "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
            "input_schema": ProjectInfoInput.model_json_schema()
        },
        {
            "name": "get-environment-tools",
            "description": "Get development tools and best practices for Java, Node.js, or TypeScript environments",
            "input_schema": EnvironmentToolsInput.model_json_schema()
        },
        {
            "name": "analyze-code",
            "description": "Analyze code snippets for patterns and provide insights",
            "input_schema": CodeAnalysisInput.model_json_schema()
        }
    ]
    return {"tools": tools}

@app.post("/mcp")
async def mcp_endpoint(request: Request, api_key: str = Security(verify_api_key)):
    raw_body = await request.body()
    if not raw_body:
        return JSONResponse(status_code=400, content={"error": "Request body is required"})
    try:
        data = json.loads(raw_body)
    except json.JSONDecodeError as e:
        return JSONResponse(status_code=400, content={"error": f"Invalid JSON: {str(e)}"})
    method = data.get("method")
    if method == "tools/list":
        tools = [
            {
                "name": "get-project-info",
                "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
                "inputSchema": ProjectInfoInput.model_json_schema()
            },
            {
                "name": "get-environment-tools",
                "description": "Get development tools and best practices for Java, Node.js, or TypeScript environments",
                "inputSchema": EnvironmentToolsInput.model_json_schema()
            },
            {
                "name": "analyze-code",
                "description": "Analyze code snippets for patterns and provide insights",
                "inputSchema": CodeAnalysisInput.model_json_schema()
            }
        ]
        return JSONResponse(content={
            "jsonrpc": "2.0",
            "id": data.get("id"),
            "result": {"tools": tools}
        })
    elif method == "tools/call":
        params = data.get("params", {})
        tool_name = params.get("name")
        tool_arguments = params.get("arguments", {})
        input_schema_map = {
            "get-project-info": ProjectInfoInput,
            "get-environment-tools": EnvironmentToolsInput,
            "analyze-code": CodeAnalysisInput
        }
        handler_map = {
            "get-project-info": get_project_info,
            "get-environment-tools": get_environment_tools,
            "analyze-code": analyze_code
        }
        input_schema_class = input_schema_map.get(tool_name)
        handler = handler_map.get(tool_name)
        if handler is None:
            return JSONResponse(status_code=404, content={"error": f"Tool handler for '{tool_name}' not found"})
        if input_schema_class:
            validated_input = input_schema_class(**tool_arguments)
            result = await handler(validated_input)
        else:
            result = await handler(tool_arguments)
        return JSONResponse(content={
            "jsonrpc": "2.0",
            "id": data.get("id"),
            "result": {
                "content": [
                    {
                        "type": "text",
                        "text": str(result)
                    }
                ]
            }
        })
    else:
        return JSONResponse(
            status_code=400,
            content={
                "jsonrpc": "2.0",
                "id": data.get("id"),
                "error": {
                    "code": -32601,
                    "message": "Method not found",
                    "data": f"Unknown method: {method}"
                }
            }
        )