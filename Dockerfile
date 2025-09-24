# ---- Builder Stage: Install dependencies ----
FROM python:3.12-slim as builder

WORKDIR /app

# Install uv for faster dependency management
RUN pip install uv

# Copy dependency definition files
COPY pyproject.toml ./
COPY README.md ./
# Copy source code so editable install works
COPY src/ ./src

# Install dependencies into a virtual environment
# This creates an isolated environment that we can copy to the final image
RUN uv pip install --system -e .

# ---- Final Stage: Create the production image ----
FROM python:3.12-slim

# Install curl for the health check
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a non-root user for security
RUN useradd --create-home --shell /bin/bash --uid 1000 appuser
USER appuser

# Copy installed dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy your application source code
COPY --chown=appuser:appuser src/ ./src

# Set environment variables for the application
ENV PYTHONPATH=/app
ENV HOST=0.0.0.0
ENV PORT=8001
# This default key will be overridden by Railway's environment variables
ENV MCP_API_KEY="mcp_S4bRw3Y8M7RqP8ilyRFsOPsNs"

# Expose the port the application will run on
EXPOSE 8001

# Health check to ensure the server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8001/health || exit 1

# Command to run the application
CMD ["python", "-m", "src.mcp_local_rag.simple_http_server"]
