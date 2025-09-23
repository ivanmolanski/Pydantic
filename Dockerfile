FROM python:3.12-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for better caching
COPY pyproject.toml ./
# Use standard install for production, not editable mode
RUN pip install .

# Copy source code
COPY src/ ./src/

# Create a non-root user
RUN useradd -m -u 1000 mcpuser && chown -R mcpuser:mcpuser /app
USER mcpuser

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8001/health || exit 1

# Run the server
CMD ["python", "-m", "src.mcp_local_rag.simple_http_server"]
