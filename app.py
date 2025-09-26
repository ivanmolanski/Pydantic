#!/usr/bin/env python3
"""
Railway deployment entry point for Pydantic MCP Server
Uses the simple HTTP server implementation for better Railway compatibility
"""

import os
import sys

# Add src to Python path so we can import our modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

if __name__ == "__main__":
    # Import and run the simple HTTP server
    from mcp_local_rag.simple_http_server import run_server
    run_server()