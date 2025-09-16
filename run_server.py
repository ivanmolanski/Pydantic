#!/usr/bin/env python3
"""
Startup script for the Pydantic MCP HTTP Server
"""
import os
import sys
import uvicorn

def main():
    """Start the HTTP server."""
    # Add src to Python path
    src_path = os.path.join(os.path.dirname(__file__), "..", "..")
    sys.path.insert(0, src_path)
    
    # Import the FastAPI app
    from src.mcp_local_rag.http_server import app
    
    # Get configuration from environment
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
    
    # Start the server
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info",
        access_log=True
    )

if __name__ == "__main__":
    main()