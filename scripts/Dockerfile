FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 appuser

# Copy Python packages from builder to system location
COPY --from=builder /root/.local /usr/local

# Copy application files
COPY --chown=appuser:appuser . .

# Create telemetry directory
RUN mkdir -p /app/telemetry && chown appuser:appuser /app/telemetry

# Switch to non-root user
USER appuser

# Expose port (Cloud Run uses PORT env var)
EXPOSE 5000
ENV PORT=5000

# Health check (simplified - no external dependencies)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python3 -c "import http.client; c = http.client.HTTPConnection('localhost', int(__import__('os').environ.get('PORT', '5000'))); c.request('GET', '/health'); r = c.getresponse(); exit(0 if r.status == 200 else 1)"

# Run dashboard with gunicorn (skip database init - DEMO_MODE uses SQLite)
CMD gunicorn --bind 0.0.0.0:${PORT} \
             --workers 2 \
             --threads 2 \
             --timeout 120 \
             --access-logfile - \
             --error-logfile - \
             --log-level info \
             expenditure_dashboard:app
