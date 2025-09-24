FROM python:3.12-slim

WORKDIR /app

# Copy all necessary files
COPY pyproject.toml README.md ./
COPY src/ ./src/

# Install dependencies directly (no multi-stage build)
RUN pip install --no-cache-dir -e .

# Set environment variables
ENV PYTHONPATH=/app
ENV HOST=0.0.0.0
ENV PORT=8001
ENV MCP_API_KEY="mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

# Expose port
EXPOSE 8001

# Run the application
CMD ["python", "-m", "src.mcp_local_rag.simple_http_server"]
