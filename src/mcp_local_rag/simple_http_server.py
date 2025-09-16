"""
Simple HTTP-based MCP Server for GitHub Copilot Integration
Uses Python's built-in http.server to avoid external dependencies.
"""

import json
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import asyncio
from typing import Dict, Any

# Import the existing RAG functionality
from .main import rag_search


class ProjectInfoTools:
    """Tools for project information and environment support."""
    
    @staticmethod
    def get_project_info(project_name: str, environment: str = "general") -> str:
        """Retrieve project information based on name and environment."""
        project_name = project_name.lower()
        environment = environment.lower()
        
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
            return f"Project '{project_name}' not found. Available projects: {', '.join(projects.keys())}"
        
        project = projects[project_name]
        
        if environment in project:
            env_info = project[environment]
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
            return f"**{project_name}:** {project['description']}"
    
    @staticmethod
    def get_environment_tools(environment: str, query: str = "") -> str:
        """Provide information about development tools for specific environments."""
        environment = environment.lower()
        query = query.lower()
        
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
                "bundlers": {
                    "webpack": "Module bundler with TypeScript support",
                    "vite": "Fast build tool with native TypeScript",
                    "rollup": "Module bundler for libraries"
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
        """Verify API key authentication."""
        api_key = os.environ.get("MCP_API_KEY")
        if not api_key:
            return True  # No auth required in dev mode
        
        auth_header = self.headers.get('Authorization')
        if not auth_header:
            return False
        
        try:
            scheme, token = auth_header.split(' ', 1)
            if scheme.lower() != 'bearer':
                return False
            return token == api_key
        except ValueError:
            return False
    
    def _send_json_response(self, data: Dict[str, Any], status: int = 200):
        """Send JSON response."""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        
        response_json = json.dumps(data, indent=2)
        self.wfile.write(response_json.encode('utf-8'))
    
    def _send_error_response(self, message: str, status: int = 400, request_id: str = None):
        """Send error response."""
        error_data = {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": -32603,
                "message": message
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
                {
                    "name": "rag-search",
                    "description": "Search the web for information using RAG-like similarity sorting",
                    "input_schema": {
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
                    
                    elif tool_name == "rag-search":
                        query = tool_arguments.get("query", "")
                        num_results = tool_arguments.get("num_results", 10)
                        top_k = tool_arguments.get("top_k", 5)
                        
                        # Call rag_search synchronously
                        search_result = rag_search(query, num_results, top_k)
                        
                        # Format the result
                        if isinstance(search_result, dict) and "content" in search_result:
                            content_text = []
                            for item in search_result["content"]:
                                if isinstance(item, dict) and "text" in item:
                                    content_text.append(item["text"])
                            result = "\n\n".join(content_text) if content_text else str(search_result)
                        else:
                            result = str(search_result)
                    
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


def run_server():
    """Run the HTTP MCP server."""
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", 8001))
    api_key = os.environ.get("MCP_API_KEY")
    
    print("=" * 60)
    print("🚀 Starting Pydantic MCP Server for GitHub Copilot")
    print("=" * 60)
    print(f"Host: {host}")
    print(f"Port: {port}")
    print(f"Authentication: {'Enabled' if api_key else 'Development mode (no auth)'}")
    print(f"Health Check: http://{host}:{port}/health")
    print(f"MCP Endpoint: http://{host}:{port}/mcp")
    print(f"Tools List: http://{host}:{port}/tools")
    print("=" * 60)
    
    if not api_key:
        print("⚠️  WARNING: No MCP_API_KEY set. Running in development mode.")
        print("   Set MCP_API_KEY environment variable for production use.")
        print()
    
    server = HTTPServer((host, port), MCPHandler)
    
    try:
        print(f"Server starting at http://{host}:{port}")
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.server_close()


if __name__ == "__main__":
    run_server()