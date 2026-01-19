FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080

WORKDIR /app

# No external dependencies; keep the image minimal.
COPY . /app

RUN useradd --create-home --uid 10001 app && chown -R app:app /app
USER 10001

EXPOSE 8080

CMD ["python", "demo_server.py"]
