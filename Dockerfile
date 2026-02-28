# Dominion OS Demo - Optimized Multi-Stage Dockerfile
# Fractal5 Solutions - Production-grade Cloud Run deployment

# Stage 1: Builder - Compile and prepare dependencies
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies to a virtual environment
COPY requirements.txt .
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime - Minimal production image
FROM python:3.12-slim

# Set environment variables for optimization
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8080 \
    WORKERS=4 \
    THREADS=2 \
    TIMEOUT=300

# Create non-root user for security
RUN groupadd -r dominion && useradd -r -g dominion dominion

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY --chown=dominion:dominion . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/dist /app/out /app/telemetry && \
    chown -R dominion:dominion /app

# Switch to non-root user
USER dominion

# Add venv to PATH
ENV PATH="/opt/venv/bin:$PATH"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:$PORT/health').read()"

# Expose port
EXPOSE 8080

# Start application with Gunicorn for production
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:$PORT \
                      --workers $WORKERS \
                      --threads $THREADS \
                      --timeout $TIMEOUT \
                      --access-logfile - \
                      --error-logfile - \
                      --log-level info \
                      --preload \
                      scripts.expenditure_dashboard:app"]
