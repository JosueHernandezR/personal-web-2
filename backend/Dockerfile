# Stage 1: Build stage
FROM python:3.10-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install UV package installer (faster than pip)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Copy project files
COPY pyproject.toml .
COPY . .

# Install dependencies using uv
RUN /root/.cargo/bin/uv pip install --no-cache .

# Stage 2: Runtime stage
FROM python:3.10-slim

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /app/app ./app
COPY --from=builder /app/alembic.ini .
COPY --from=builder /app/migrations ./migrations

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]