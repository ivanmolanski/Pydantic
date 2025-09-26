"""
FastAPI-based MCP Server for GitHub Copilot Integration
Compatible with the existing simple_http_server.py implementation.
"""

import os
from typing import Dict, Any, Optional, Union, List
from fastapi import FastAPI, HTTPException, Depends, Header, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, ValidationError

# Import existing components from simple_http_server
from .simple_http_server import (
    ProjectInfoTools,
    ProjectInfoInput,
    EnvironmentToolsInput, 
    RagSearchInput
)

# Create FastAPI app
app = FastAPI(
    title="Pydantic MCP Server",
    description="HTTP-based MCP server for GitHub Copilot integration",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MCP Request/Response models

class MCPRequest(BaseModel):
    jsonrpc: str = "2.0"
    id: Optional[Union[str, int]] = None
    method: str
    params: Optional[Dict[str, Any]] = {}


class MCPResponse(BaseModel):
    jsonrpc: str = "2.0"
    id: Optional[Union[str, int]] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[Dict[str, Any]] = None

# Authentication dependency
async def verify_api_key(authorization: Optional[str] = Header(None)):
    """Verify API key authentication."""
    api_key = os.environ.get("MCP_API_KEY")
    if not api_key:
        return True  # No auth required in dev mode
    
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    
    try:
        scheme, token = authorization.split(' ', 1)
        if scheme.lower() != 'bearer':
            raise HTTPException(status_code=401, detail="Bearer token required")
        
        if token != api_key:
            raise HTTPException(status_code=401, detail="Invalid API key")
            
        return True
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid authorization format")

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "server": "pydantic-mcp-server", 
        "version": "1.0.0"
    }

# Root endpoint
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

# Tools list endpoint
@app.get("/tools")
async def list_tools(authenticated: bool = Depends(verify_api_key)):
    """List available tools."""
    tools = get_tool_definitions()
    return {"tools": tools}

def get_tool_definitions() -> List[Dict[str, Any]]:
    """Returns a list of tool definitions."""
    return [
        {
            "name": "get-project-info",
            "description": "Retrieve project information for Java, Node.js, or TypeScript environments",
            "inputSchema": ProjectInfoInput.model_json_schema()
        },
        {
            "name": "get-environment-tools", 
            "description": "Get development tools for Java, Node.js, or TypeScript environments",
            "inputSchema": EnvironmentToolsInput.model_json_schema()
        },
        {
            "name": "rag-search",
            "description": "Search the web for information using RAG-like similarity sorting",
            "inputSchema": RagSearchInput.model_json_schema()
        }
    ]

# MCP Protocol endpoint
@app.post("/mcp", response_model=None)
async def mcp_handler(
    request: MCPRequest,
    authenticated: bool = Depends(verify_api_key)
) -> Union[MCPResponse, Response]:
    """Handle MCP protocol requests."""
    try:
        if request.method == "initialize":
            return handle_initialize(request.id)
        
        elif request.method == "notifications/initialized":
            # Client acknowledges initialization - no JSON-RPC response needed for notifications
            # but we still need to send a proper HTTP 204 No Content response
            return Response(status_code=204, headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization"
            })
            
        elif request.method == "tools/list":
            return handle_tools_list(request.id)
            
        elif request.method == "tools/call":
            return handle_tool_call(request.id, request.params or {})
            
        else:
            return MCPResponse(
                id=request.id,
                error={
                    "code": -32601,
                    "message": "Method not found",
                    "data": {"method": request.method}
                }
            )
            
    except ValidationError as e:
        return MCPResponse(
            id=request.id,
            error={
                "code": -32602,
                "message": "Invalid params",
                "data": {"validation_error": str(e)}
            }
        )
    except Exception as e:
        return MCPResponse(
            id=request.id,
            error={
                "code": -32603,
                "message": "Internal error",
                "data": {"error": str(e)}
            }
        )

def handle_initialize(request_id: Optional[Union[str, int]]) -> MCPResponse:
    """Handle initialize request."""
    return MCPResponse(
        id=request_id,
        result={
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {},
                "resources": {},
                "prompts": {}
            },
            "serverInfo": {
                "name": "pydantic-mcp-server",
                "version": "1.0.0"
            }
        }
    )

def handle_tools_list(request_id: Optional[Union[str, int]]) -> MCPResponse:
    """Handle tools/list request."""
    tools = get_tool_definitions()
    return MCPResponse(
        id=request_id,
        result={"tools": tools}
    )

def handle_tool_call(request_id: Optional[Union[str, int]], params: Dict[str, Any]) -> MCPResponse:
    """Handle tools/call request."""
    tool_name = params.get("name")
    tool_arguments = params.get("arguments", {})
    
    if not tool_name:
        return MCPResponse(
            id=request_id,
            error={
                "code": -32602,
                "message": "Tool name is required"
            }
        )
    
    try:
        # Map tool names to their validation models and implementation functions
        tool_map = {
            "get-project-info": (ProjectInfoInput, lambda v: ProjectInfoTools.get_project_info(v.project_name, v.environment)),
            "get-environment-tools": (EnvironmentToolsInput, lambda v: ProjectInfoTools.get_environment_tools(v.environment, v.query)),
            "rag-search": (RagSearchInput, lambda v: ProjectInfoTools.rag_search(v.query, v.top_k, v.num_results))
        }
        
        if tool_name not in tool_map:
            return MCPResponse(
                id=request_id,
                error={
                    "code": -32602,
                    "message": f"Unknown tool: {tool_name}"
                }
            )
        
        model, func = tool_map[tool_name]
        try:
            validated_args = model(**tool_arguments)
        except ValidationError as ve:
            return MCPResponse(
                id=request_id,
                error={
                    "code": -32602,
                    "message": "Input validation error",
                    "data": {"validation_error": str(ve)}
                }
            )
        
        result = func(validated_args)
        
        return MCPResponse(
            id=request_id,
            result={
                "content": [
                    {"type": "text", "text": str(result)}
                ]
            }
        )
        
    except Exception as e:
        return MCPResponse(
            id=request_id,
            error={
                "code": -32603,
                "message": "Tool execution error",
                "data": {"error": str(e)}
            }
        )

# Add CORS preflight handler
@app.options("/mcp")
async def mcp_options():
    """Handle CORS preflight for MCP endpoint."""
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", 8001))
    
    uvicorn.run(app, host=host, port=port)