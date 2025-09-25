"""
Vercel serverless handler for Pydantic MCP Server
Converts the HTTP server to work with Vercel's serverless architecture
"""

import json
import os
from typing import Any, Dict
from urllib.parse import parse_qs

# Import the main handler class from our server
import sys
sys.path.append('/var/task/src')

try:
    from mcp_local_rag.simple_http_server import MCPHandler
    from mcp_local_rag.tools import (
        get_project_info, 
        get_environment_tools, 
        rag_search
    )
except ImportError:
    # Fallback for local development
    import sys
    import os
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
    from mcp_local_rag.simple_http_server import MCPHandler
    from mcp_local_rag.tools import (
        get_project_info, 
        get_environment_tools, 
        rag_search
    )

class VercelMCPHandler:
    """Serverless MCP handler for Vercel"""
    
    def __init__(self):
        self.api_key = os.environ.get("MCP_API_KEY")
        
    def _verify_auth(self, headers: Dict[str, str]) -> bool:
        """Verify API key authentication"""
        if not self.api_key:
            return True  # No auth in dev mode
        
        auth_header = headers.get('authorization', '').lower()
        if not auth_header:
            return False
        
        if auth_header.startswith('bearer '):
            token = auth_header[7:]  # Remove 'bearer '
            return token == self.api_key
        
        return False
    
    def _get_tool_definitions(self) -> list[dict[str, Any]]:
        """Returns tool definitions"""
        return [
            {
                "name": "get-project-info",
                "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "project_name": {
                            "type": "string",
                            "description": "The name of the project",
                            "title": "Project Name"
                        },
                        "environment": {
                            "type": "string",
                            "description": "Environment type",
                            "title": "Environment",
                            "default": "general"
                        }
                    },
                    "required": ["project_name"],
                    "title": "ProjectInfoInput"
                }
            },
            {
                "name": "get-environment-tools",
                "description": "Get development tools for Java, Node.js, or TypeScript environments",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "environment": {
                            "type": "string",
                            "description": "Environment type: java, node, typescript",
                            "title": "Environment"
                        },
                        "query": {
                            "type": "string",
                            "description": "Specific query about tools",
                            "title": "Query",
                            "default": ""
                        }
                    },
                    "required": ["environment"],
                    "title": "EnvironmentToolsInput"
                }
            },
            {
                "name": "rag-search",
                "description": "Search the web for information using RAG-like similarity sorting",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The query to search for",
                            "title": "Query"
                        },
                        "num_results": {
                            "type": "integer",
                            "description": "Number of results",
                            "title": "Num Results",
                            "default": 10
                        },
                        "top_k": {
                            "type": "integer",
                            "description": "Top K results",
                            "title": "Top K",
                            "default": 5
                        }
                    },
                    "required": ["query"],
                    "title": "RagSearchInput"
                }
            }
        ]
    
    def handle_request(self, event, context=None):
        """Handle Vercel serverless request"""
        
        # Get path and method
        path = event.get('path', event.get('rawPath', '/'))
        method = event.get('httpMethod', event.get('requestContext', {}).get('http', {}).get('method', 'GET'))
        headers = event.get('headers', {})
        
        # Convert header keys to lowercase for case-insensitive lookup
        headers = {k.lower(): v for k, v in headers.items()}
        
        # Health check endpoint
        if path == '/health' and method == 'GET':
            return {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization",
                    "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
                },
                "body": json.dumps({
                    "status": "healthy",
                    "server": "pydantic-mcp-server",
                    "version": "1.0.0",
                    "platform": "vercel"
                })
            }
        
        # MCP endpoint
        if path == '/mcp' and method == 'POST':
            # Verify authentication
            if not self._verify_auth(headers):
                return {
                    "statusCode": 401,
                    "headers": {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*"
                    },
                    "body": json.dumps({
                        "jsonrpc": "2.0",
                        "id": None,
                        "error": {
                            "code": -32600,
                            "message": "Unauthorized"
                        }
                    })
                }
            
            # Parse request body
            try:
                body = event.get('body', '')
                if event.get('isBase64Encoded'):
                    import base64
                    body = base64.b64decode(body).decode('utf-8')
                
                data = json.loads(body) if body else {}
                
                request_id = data.get("id")
                method_name = data.get("method")
                params = data.get("params", {})
                
                # Handle MCP methods
                if method_name == "initialize":
                    return {
                        "statusCode": 200,
                        "headers": {
                            "Content-Type": "application/json",
                            "Access-Control-Allow-Origin": "*"
                        },
                        "body": json.dumps({
                            "jsonrpc": "2.0",
                            "id": request_id,
                            "result": {
                                "protocolVersion": "2024-11-05",
                                "capabilities": {
                                    "tools": {}
                                },
                                "serverInfo": {
                                    "name": "pydantic-mcp-server",
                                    "version": "1.0.0"
                                }
                            }
                        })
                    }
                
                elif method_name == "tools/list":
                    return {
                        "statusCode": 200,
                        "headers": {
                            "Content-Type": "application/json",
                            "Access-Control-Allow-Origin": "*"
                        },
                        "body": json.dumps({
                            "jsonrpc": "2.0",
                            "id": request_id,
                            "result": {
                                "tools": self._get_tool_definitions()
                            }
                        })
                    }
                
                elif method_name == "tools/call":
                    tool_name = params.get("name")
                    arguments = params.get("arguments", {})
                    
                    try:
                        if tool_name == "get-project-info":
                            result = get_project_info(
                                project_name=arguments.get("project_name", ""),
                                environment=arguments.get("environment", "general")
                            )
                        elif tool_name == "get-environment-tools":
                            result = get_environment_tools(
                                environment=arguments.get("environment", ""),
                                query=arguments.get("query", "")
                            )
                        elif tool_name == "rag-search":
                            result = rag_search(
                                query=arguments.get("query", ""),
                                num_results=arguments.get("num_results", 10),
                                top_k=arguments.get("top_k", 5)
                            )
                        else:
                            raise ValueError(f"Unknown tool: {tool_name}")
                        
                        return {
                            "statusCode": 200,
                            "headers": {
                                "Content-Type": "application/json",
                                "Access-Control-Allow-Origin": "*"
                            },
                            "body": json.dumps({
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
                            })
                        }
                    
                    except Exception as e:
                        return {
                            "statusCode": 200,
                            "headers": {
                                "Content-Type": "application/json",
                                "Access-Control-Allow-Origin": "*"
                            },
                            "body": json.dumps({
                                "jsonrpc": "2.0",
                                "id": request_id,
                                "error": {
                                    "code": -32603,
                                    "message": f"Internal error: {str(e)}"
                                }
                            })
                        }
                
                else:
                    return {
                        "statusCode": 200,
                        "headers": {
                            "Content-Type": "application/json",
                            "Access-Control-Allow-Origin": "*"
                        },
                        "body": json.dumps({
                            "jsonrpc": "2.0",
                            "id": request_id,
                            "error": {
                                "code": -32601,
                                "message": f"Method not found: {method_name}"
                            }
                        })
                    }
            
            except json.JSONDecodeError:
                return {
                    "statusCode": 400,
                    "headers": {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*"
                    },
                    "body": json.dumps({
                        "jsonrpc": "2.0",
                        "id": None,
                        "error": {
                            "code": -32700,
                            "message": "Parse error"
                        }
                    })
                }
            
            except Exception as e:
                return {
                    "statusCode": 500,
                    "headers": {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*"
                    },
                    "body": json.dumps({
                        "jsonrpc": "2.0",
                        "id": None,
                        "error": {
                            "code": -32603,
                            "message": f"Internal error: {str(e)}"
                        }
                    })
                }
        
        # Handle OPTIONS for CORS
        if method == 'OPTIONS':
            return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization",
                    "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
                },
                "body": ""
            }
        
        # 404 for other paths
        return {
            "statusCode": 404,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "error": "Not found"
            })
        }

# Create global handler instance
handler = VercelMCPHandler()

# Vercel entry point
def handler_func(request):
    """Vercel Python handler function"""
    # Convert Vercel request to event format
    event = {
        'path': request.path,
        'httpMethod': request.method,
        'headers': dict(request.headers),
        'body': request.body.decode('utf-8') if hasattr(request.body, 'decode') else str(request.body),
        'isBase64Encoded': False
    }
    
    response = handler.handle_request(event)
    
    # Convert response back to Vercel format
    from werkzeug.wrappers import Response
    return Response(
        response['body'],
        status=response['statusCode'],
        headers=response.get('headers', {}),
        content_type='application/json'
    )

# Also support AWS Lambda format for compatibility
def lambda_handler(event, context):
    """AWS Lambda compatible handler"""
    return handler.handle_request(event, context)