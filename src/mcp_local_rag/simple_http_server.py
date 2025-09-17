"""
Simple HTTP-based MCP Server for GitHub Copilot Integration
Uses Python's built-in http.server to avoid external dependencies.
Optimized for Python 3.12+ with modern features.
"""

import json
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import asyncio
from typing import Dict, Any, Optional
from dataclasses import dataclass
from enum import Enum




class Environment(Enum):
    """Supported development environments."""
    JAVA = "java"
    NODE = "node" 
    TYPESCRIPT = "typescript"
    GENERAL = "general"


@dataclass
class ProjectConfig:
    """Configuration for a development project."""
    description: str
    environments: Dict[str, Dict[str, Any]]


class ProjectInfoTools:
    """Tools for project information and environment support."""
    
    # Modern Python 3.12+ class variable with type annotation
    PROJECTS: Dict[str, ProjectConfig] = {
        "java-core": ProjectConfig(
            description="Enterprise Java application with Spring Boot backend",
            environments={
                "java": {
                    "framework": "Spring Boot 3.3",
                    "build_tool": "Maven 3.9+",
                    "java_version": "21",
                    "dependencies": ["spring-boot-starter-web", "spring-boot-starter-data-jpa", "junit5"],
                    "architecture": "Microservices with REST APIs"
                },
                "general": "Core Java business logic service with Spring Boot framework"
            }
        ),
        "node-api": ProjectConfig(
            description="RESTful API service built with Node.js and TypeScript",
            environments={
                "node": {
                    "runtime": "Node.js 22+",
                    "framework": "Express.js 5.0",
                    "package_manager": "npm 10+",
                    "dependencies": ["express", "@types/express", "typescript", "vitest"],
                    "architecture": "RESTful microservice"
                },
                "typescript": {
                    "version": "5.7+",
                    "config": "Strict mode enabled with latest features",
                    "tools": ["ESLint 9", "Prettier 3", "Vitest"],
                    "types": "Full type coverage with @types packages"
                },
                "general": "Node.js TypeScript API service with Express framework"
            }
        ),
        "frontend-app": ProjectConfig(
            description="React-based frontend application with TypeScript",
            environments={
                "typescript": {
                    "framework": "React 18+",
                    "bundler": "Vite 6+",
                    "state": "Redux Toolkit 2.0",
                    "testing": "Vitest + React Testing Library",
                    "styling": "Tailwind CSS 4.0"
                },
                "node": {
                    "runtime": "Node.js 22+",
                    "package_manager": "pnpm 9+",
                    "scripts": "Build, test, lint automation with modern tooling"
                },
                "general": "Modern React frontend with TypeScript and Vite"
            }
        )
    }
    
    @staticmethod
    def get_project_info(project_name: str, environment: str = "general") -> str:
        """Retrieve project information based on name and environment."""
        project_name = project_name.lower()
        environment = environment.lower()
        
        if project_name not in ProjectInfoTools.PROJECTS:
            available = ', '.join(ProjectInfoTools.PROJECTS.keys())
            return f"Project '{project_name}' not found. Available projects: {available}"
        
        project = ProjectInfoTools.PROJECTS[project_name]
        
        if environment in project.environments:
            env_info = project.environments[environment]
            if isinstance(env_info, dict):
                info_parts = [f"**{project_name} - {environment.upper()} Environment:**"]
                for key, value in env_info.items():
                    if isinstance(value, list):
                        info_parts.append(f"- {key.title()}: {', '.join(value)}")
                    else:
                        info_parts.append(f"- {key.title()}: {value}")
                return "\n".join(info_parts)
            else:
                return f"**{project_name}:** {env_info}"
        else:
            return f"**{project_name}:** {project.description}"
    
    @staticmethod
    def get_environment_tools(environment: str, query: str = "") -> str:
        """Provide information about development tools for specific environments."""
        environment = environment.lower()
        query = query.lower()
        
        tools_info = {
            "java": {
                "build_tools": {
                    "maven": "Maven 3.9+ - XML-based project management and build tool",
                    "gradle": "Gradle 8.10+ - Groovy/Kotlin DSL build automation tool",
                    "sbt": "SBT 1.10+ - Scala Build Tool, also used for Java projects"
                },
                "testing": {
                    "junit5": "JUnit 5.11+ - Modern Java testing framework",
                    "mockito": "Mockito 5.14+ - Mocking framework for unit tests", 
                    "testcontainers": "TestContainers 1.20+ - Integration testing with Docker containers",
                    "spring-boot-test": "Spring Boot Test 3.3+ - Testing support for Spring Boot applications"
                },
                "frameworks": {
                    "spring-boot": "Spring Boot 3.3+ - Production-ready Java application framework",
                    "quarkus": "Quarkus 3.17+ - Kubernetes-native Java framework",
                    "micronaut": "Micronaut 4.7+ - Modern microservices framework"
                }
            },
            "node": {
                "package_managers": {
                    "npm": "npm 10+ - Default Node.js package manager with workspaces",
                    "yarn": "Yarn 4+ - Fast, reliable package manager with Plug'n'Play",
                    "pnpm": "pnpm 9+ - Efficient package manager with hard links and workspaces"
                },
                "testing": {
                    "vitest": "Vitest 2.2+ - Fast Vite-native test framework with TypeScript support",
                    "jest": "Jest 29+ - JavaScript testing framework with snapshot testing",
                    "mocha": "Mocha 10+ - Feature-rich test framework"
                },
                "frameworks": {
                    "express": "Express.js 5+ - Minimal web application framework",
                    "fastify": "Fastify 5+ - High-performance web framework",
                    "nest": "NestJS 10+ - Progressive Node.js framework with TypeScript"
                }
            },
            "typescript": {
                "compilers": {
                    "tsc": "TypeScript 5.7+ - Official TypeScript compiler with latest language features",
                    "esbuild": "esbuild 0.24+ - Fast TypeScript/JavaScript bundler and transpiler",
                    "swc": "SWC 1.9+ - Super-fast TypeScript/JavaScript compiler in Rust"
                },
                "frameworks": {
                    "react": "React 18+ - UI library with advanced TypeScript support",
                    "vue": "Vue 3.5+ - Progressive framework with excellent TypeScript integration",
                    "angular": "Angular 19+ - Full-featured TypeScript framework with signals"
                },
                "bundlers": {
                    "webpack": "Webpack 5+ - Module bundler with TypeScript support",
                    "vite": "Vite 6+ - Fast build tool with native TypeScript and hot reload",
                    "rollup": "Rollup 4+ - Module bundler optimized for libraries"
                },
                "tools": {
                    "eslint": "ESLint 9+ with @typescript-eslint for code quality",
                    "prettier": "Prettier 3+ for consistent code formatting",
                    "vitest": "Vitest 2+ for fast TypeScript testing"
                }
            }
        }
        
        if environment not in tools_info:
            return f"Environment '{environment}' not supported. Available: {', '.join(tools_info.keys())}"
        
        env_tools = tools_info[environment]
        
        if query:
            relevant_sections = []
            for category, tools in env_tools.items():
                if query in category.lower() or any(query in tool.lower() or query in desc.lower() for tool, desc in tools.items()):
                    relevant_sections.append((category, tools))
            
            if relevant_sections:
                result = [f"**{environment.upper()} Tools matching '{query}':**\n"]
                for category, tools in relevant_sections:
                    result.append(f"**{category.title()}:**")
                    for tool, desc in tools.items():
                        result.append(f"- **{tool}**: {desc}")
                    result.append("")
                return "\n".join(result)
            else:
                return f"No {environment} tools found matching '{query}'"
        else:
            result = [f"**{environment.upper()} Development Tools:**\n"]
            for category, tools in env_tools.items():
                result.append(f"**{category.title()}:**")
                for tool, desc in tools.items():
                    result.append(f"- **{tool}**: {desc}")
                result.append("")
            return "\n".join(result)


class MCPHandler(BaseHTTPRequestHandler):
    """HTTP request handler for MCP protocol."""
    
    def _verify_auth(self) -> bool:
        """Verify API key authentication using modern Python features."""
        api_key = os.environ.get("MCP_API_KEY")
        if not api_key:
            return True  # No auth required in dev mode
        
        auth_header = self.headers.get('Authorization')
        if not auth_header:
            return False
        
        # Use match-case for cleaner pattern matching (Python 3.10+)
        try:
            parts = auth_header.split(' ', 1)
            match parts:
                case ['Bearer', token] | ['bearer', token]:
                    return token == api_key
                case _:
                    return False
        except ValueError:
            return False
    
    def _send_json_response(self, data: Dict[str, Any], status: int = 200) -> None:
        """Send JSON response with modern security headers."""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        # Modern security headers
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'DENY')
        self.send_header('X-XSS-Protection', '1; mode=block')
        self.end_headers()
        
        response_json = json.dumps(data, indent=2, ensure_ascii=False)
        self.wfile.write(response_json.encode('utf-8'))
    
    def _send_error_response(self, message: str, status: int = 400, request_id: Optional[str] = None) -> None:
        """Send error response with proper JSON-RPC 2.0 format."""
        error_data = {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": -32603 if status == 500 else -32602,
                "message": message,
                "data": {"http_status": status}
            }
        }
        self._send_json_response(error_data, status)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests."""
        self._send_json_response({})
    
    def do_GET(self):
        """Handle GET requests."""
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        if path == '/health':
            self._send_json_response({
                "status": "healthy",
                "server": "pydantic-mcp-server",
                "version": "1.0.0"
            })
        elif path == '/':
            self._send_json_response({
                "name": "Pydantic MCP Server",
                "description": "HTTP-based MCP server for GitHub Copilot integration",
                "version": "1.0.0",
                "endpoints": {
                    "mcp": "/mcp - MCP protocol endpoint",
                    "health": "/health - Health check",
                    "tools": "/tools - List available tools"
                }
            })
        elif path == '/tools':
            if not self._verify_auth():
                self._send_error_response("Unauthorized", 401)
                return
            
            tools = [
                {
                    "name": "get-project-info",
                    "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
                    "input_schema": {
                        "type": "object",
                        "properties": {
                            "project_name": {"type": "string", "description": "The name of the project"},
                            "environment": {"type": "string", "default": "general", "description": "Environment type"}
                        },
                        "required": ["project_name"]
                    }
                },
                {
                    "name": "get-environment-tools",
                    "description": "Get development tools for Java, Node.js, or TypeScript environments",
                    "input_schema": {
                        "type": "object",
                        "properties": {
                            "environment": {"type": "string", "description": "Environment type: java, node, typescript"},
                            "query": {"type": "string", "default": "", "description": "Specific query about tools"}
                        },
                        "required": ["environment"]
                    }
                },

            ]
            
            self._send_json_response({"tools": tools})
        else:
            self._send_error_response("Not found", 404)
    
    def do_POST(self):
        """Handle POST requests (MCP protocol)."""
        if self.path != '/mcp':
            self._send_error_response("Not found", 404)
            return
        
        if not self._verify_auth():
            self._send_error_response("Unauthorized", 401)
            return
        
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length == 0:
                self._send_error_response("Request body is required")
                return
            
            raw_body = self.rfile.read(content_length)
            data = json.loads(raw_body.decode('utf-8'))
            
            request_id = data.get("id")
            method = data.get("method")
            
            if method == "tools/list":
                tools = [
                    {
                        "name": "get-project-info",
                        "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "project_name": {"type": "string", "description": "The name of the project"},
                                "environment": {"type": "string", "default": "general", "description": "Environment type"}
                            },
                            "required": ["project_name"]
                        }
                    },
                    {
                        "name": "get-environment-tools",
                        "description": "Get development tools for Java, Node.js, or TypeScript environments",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "environment": {"type": "string", "description": "Environment type: java, node, typescript"},
                                "query": {"type": "string", "default": "", "description": "Specific query about tools"}
                            },
                            "required": ["environment"]
                        }
                    },
                    {
                        "name": "rag-search",
                        "description": "Search the web for information using RAG-like similarity sorting",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "query": {"type": "string", "description": "The query to search for"},
                                "num_results": {"type": "integer", "default": 10},
                                "top_k": {"type": "integer", "default": 5}
                            },
                            "required": ["query"]
                        }
                    }
                ]
                
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {"tools": tools}
                }
                self._send_json_response(response)
            
            elif method == "tools/call":
                params = data.get("params", {})
                tool_name = params.get("name")
                tool_arguments = params.get("arguments", {})
                
                if not tool_name:
                    self._send_error_response("Tool name is required", 400, request_id)
                    return
                
                try:
                    # Execute the tool
                    if tool_name == "get-project-info":
                        project_name = tool_arguments.get("project_name", "")
                        environment = tool_arguments.get("environment", "general")
                        result = ProjectInfoTools.get_project_info(project_name, environment)
                    
                    elif tool_name == "get-environment-tools":
                        environment = tool_arguments.get("environment", "")
                        query = tool_arguments.get("query", "")
                        result = ProjectInfoTools.get_environment_tools(environment, query)
                    

                    
                    else:
                        self._send_error_response(f"Unknown tool: {tool_name}", 400, request_id)
                        return
                    
                    response = {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": str(result)
                                }
                            ]
                        }
                    }
                    self._send_json_response(response)
                
                except Exception as e:
                    self._send_error_response(f"Tool execution error: {str(e)}", 500, request_id)
            
            else:
                self._send_error_response(f"Unknown method: {method}", 400, request_id)
        
        except json.JSONDecodeError as e:
            self._send_error_response(f"Invalid JSON: {str(e)}")
        except Exception as e:
            self._send_error_response(f"Internal server error: {str(e)}", 500)
    
    def log_message(self, format, *args):
        """Override to customize logging."""
        print(f"[{self.address_string()}] {format % args}")


def run_server() -> None:
    """Run the HTTP MCP server with modern Python features."""
    import sys
    import signal
    from contextlib import contextmanager
    
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", 8001))
    api_key = os.environ.get("MCP_API_KEY")
    
    # Modern f-string formatting with alignment
    print("=" * 60)
    print("🚀 Starting Pydantic MCP Server for GitHub Copilot")
    print("=" * 60)
    print(f"Python Version: {sys.version.split()[0]}")
    print(f"Host:          {host}")
    print(f"Port:          {port}")
    print(f"Authentication: {'🔒 Enabled' if api_key else '🔓 Development mode (no auth)'}")
    print(f"Health Check:  http://{host}:{port}/health")
    print(f"MCP Endpoint:  http://{host}:{port}/mcp")
    print(f"Tools List:    http://{host}:{port}/tools")
    print("=" * 60)
    
    if not api_key:
        print("⚠️  WARNING: No MCP_API_KEY set. Running in development mode.")
        print("   Set MCP_API_KEY environment variable for production use.")
        print()
    
    server = HTTPServer((host, port), MCPHandler)
    
    # Modern signal handling
    def signal_handler(signum: int, frame) -> None:
        print(f"\n📡 Received signal {signum}. Shutting down server gracefully...")
        server.server_close()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        print(f"🌐 Server running at http://{host}:{port}")
        print("   Press Ctrl+C to stop the server")
        print()
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"\n❌ Server error: {e}")
    finally:
        server.server_close()
        print("✅ Server shutdown complete")


if __name__ == "__main__":
    run_server()