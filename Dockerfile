FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Force rebuild: ensure Railway uses python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*


# Copy requirements and README for build
COPY pyproject.toml uv.lock README.md ./

# Install Python dependencies (explicitly include pydantic)
RUN pip install --no-cache-dir pydantic aiohttp beautifulsoup4 duckduckgo-search requests fastapi "uvicorn[standard]"
RUN pip install --no-cache-dir -e .

# Copy source code
COPY src/ ./src/

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Expose port
EXPOSE 8001

# Set environment variables
ENV PYTHONPATH=/app/src
ENV HOST=0.0.0.0
ENV PORT=8001

# Set default API key (should be overridden in production)
# For Railway: Use your actual API key from Railway Variables
ENV MCP_API_KEY=your-secure-api-key1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8001/health')"

# Start the server (simple HTTP MCP server)
CMD ["python", "-c", "from src.mcp_local_rag.simple_http_server import run_server; run_server()"]