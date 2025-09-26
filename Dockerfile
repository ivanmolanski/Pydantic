FROM python:3.12-slim

WORKDIR /app

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy all necessary files
COPY pyproject.toml README.md ./
COPY src/ ./src/

# Install dependencies directly (no multi-stage build)
RUN pip install --no-cache-dir -e .

# Set environment variables
ENV PYTHONPATH=/app
ENV HOST=0.0.0.0
# Don't set PORT here - let Railway assign it dynamically
ENV MCP_API_KEY="mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

# Expose Railway's dynamic port (PORT env var will be set by Railway)

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8001}/health || exit 1

# Run the application
CMD ["python", "src/main.py"]
