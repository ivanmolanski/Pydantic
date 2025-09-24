FROM python:3.12-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy project configuration and readme for packaging
COPY pyproject.toml ./
COPY README.md ./

# Use standard install for production, not editable mode
RUN pip install .

# Copy source code
COPY src/ ./src/

# Create a non-root user
RUN useradd -m -u 1000 mcpuser && chown -R mcpuser:mcpuser /app
USER mcpuser

# Set environment variables
ENV PYTHONPATH=/app/src
ENV HOST=0.0.0.0
ENV PORT=8001

# Set default API key (should be overridden in production)
# For Railway: Use your actual API key from Railway Variables
ENV MCP_API_KEY="Bearer mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

# Health check

# Run the server
CMD ["python", "-m", "src.mcp_local_rag.simple_http_server"]
