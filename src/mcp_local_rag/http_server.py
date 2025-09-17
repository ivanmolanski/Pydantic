"""
HTTP-based MCP Server for GitHub Copilot Integration
Implements a FastAPI web server that exposes MCP tools via HTTP transport.
"""

from typing import Dict, List, Any, Optional
from pydantic import BaseModel, Field
import json
import os

from fastapi import FastAPI, Request, HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from mcp.server import McpServer
from mcp.server.fastmcp import FastMCP
from mcp.types import TextContent, Tool as McpTool



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
mcp_server = McpServer(name="pydantic-github-agent", version="1.0.0")

def verify_api_key(credentials: Optional[HTTPAuthorizationCredentials] = Security(security)):
    """Verify API key for authentication."""
    if not credentials:
        # For development, allow requests without auth
        # In production, this should always require authentication
        api_key = os.environ.get("MCP_API_KEY")
        if api_key:  # Only enforce auth if API key is set
            raise HTTPException(status_code=401, detail="Authorization header required")
        return None
    
    expected_key = os.environ.get("MCP_API_KEY", "dev-key-123")
    if credentials.credentials != expected_key:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return credentials.credentials

async def get_project_info(params: ProjectInfoInput) -> str:
    """
    Retrieve project information based on name and environment.
    Simulates accessing project metadata, documentation, or configuration files.
    """
    project_name = params.project_name.lower()
    environment = params.environment.lower()
    
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
    environment = params.environment.lower()
    query = params.query.lower()
    
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
    language = params.language.lower()
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
    
    # Count lines and estimate complexity
    lines = code.split('\n')
    non_empty_lines = [line for line in lines if line.strip()]
    
    complexity_indicators = [
        "if", "for", "while", "switch", "try", "catch", "finally"
    ]
    complexity_count = sum(1 for line in non_empty_lines for indicator in complexity_indicators if indicator in line.lower())
    
    result = [
        f"**Code Analysis Results for {language.title()}:**",
        f"- Lines of code: {len(non_empty_lines)}",
        f"- Complexity indicators: {complexity_count}"
    ]
    
    if analysis:
        result.append("**Pattern Analysis:**")
        result.extend(analysis)
    else:
        result.append("⚠️  No specific patterns detected for this language")
    
    return "\n".join(result)

# Register tools with the MCP server
mcp_server.register_tool(
    name="get-project-info",
    description="Retrieve project information for Java, Node.js, or TypeScript environments",
    input_schema=ProjectInfoInput.model_json_schema(),
    handler=get_project_info
)

mcp_server.register_tool(
    name="get-environment-tools", 
    description="Get development tools and best practices for Java, Node.js, or TypeScript environments",
    input_schema=EnvironmentToolsInput.model_json_schema(),
    handler=get_environment_tools
)

mcp_server.register_tool(
    name="analyze-code",
    description="Analyze code snippets for patterns and provide insights",
    input_schema=CodeAnalysisInput.model_json_schema(), 
    handler=analyze_code
)



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
async def list_tools(api_key: str = Depends(verify_api_key)):
    """List available MCP tools."""
    tools = []
    for tool_name, tool_info in mcp_server._tools.items():
        tools.append({
            "name": tool_name,
            "description": tool_info.get("description", ""),
            "input_schema": tool_info.get("input_schema", {})
        })
    return {"tools": tools}

@app.post("/mcp")
async def mcp_endpoint(request: Request, api_key: str = Depends(verify_api_key)):
    """
    Main MCP protocol endpoint for GitHub Copilot integration.
    Handles all MCP requests and routes them to the appropriate tools.
    """
    try:
        raw_body = await request.body()
        if not raw_body:
            raise HTTPException(status_code=400, detail="Request body is required")
        
        try:
            data = json.loads(raw_body)
        except json.JSONDecodeError as e:
            raise HTTPException(status_code=400, detail=f"Invalid JSON: {str(e)}")
        
        # Handle different MCP message types
        if data.get("method") == "tools/list":
            # Return list of available tools
            tools = []
            for tool_name, tool_info in mcp_server._tools.items():
                tools.append({
                    "name": tool_name,
                    "description": tool_info.get("description", ""),
                    "inputSchema": tool_info.get("input_schema", {})
                })
            
            return JSONResponse(content={
                "jsonrpc": "2.0",
                "id": data.get("id"),
                "result": {"tools": tools}
            })
        
        elif data.get("method") == "tools/call":
            # Execute a tool
            params = data.get("params", {})
            tool_name = params.get("name")
            tool_arguments = params.get("arguments", {})
            
            if not tool_name:
                raise HTTPException(status_code=400, detail="Tool name is required")
            
            if tool_name not in mcp_server._tools:
                raise HTTPException(status_code=404, detail=f"Tool '{tool_name}' not found")
            
            # Execute the tool
            tool_info = mcp_server._tools[tool_name]
            handler = tool_info["handler"]
            
            try:
                # For all tools that expect Pydantic models
                input_schema_class = {
                    "get-project-info": ProjectInfoInput,
                    "get-environment-tools": EnvironmentToolsInput,
                    "analyze-code": CodeAnalysisInput
                }.get(tool_name)
                
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
            
            except Exception as e:
                return JSONResponse(
                    status_code=500,
                    content={
                        "jsonrpc": "2.0",
                        "id": data.get("id"),
                        "error": {
                            "code": -32603,
                            "message": "Internal error",
                            "data": str(e)
                        }
                    }
                )
        
        else:
            return JSONResponse(
                status_code=400,
                content={
                    "jsonrpc": "2.0",
                    "id": data.get("id"),
                    "error": {
                        "code": -32601,
                        "message": "Method not found",
                        "data": f"Unknown method: {data.get('method')}"
                    }
                }
            )
    
    except HTTPException:
        raise
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "jsonrpc": "2.0",
                "id": data.get("id") if "data" in locals() else None,
                "error": {
                    "code": -32603,
                    "message": "Internal server error",
                    "data": str(e)
                }
            }
        )

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8001))
    host = os.environ.get("HOST", "0.0.0.0")
    
    print(f"Starting Pydantic MCP Server on {host}:{port}")
    print("Set MCP_API_KEY environment variable for authentication")
    
    uvicorn.run(app, host=host, port=port)