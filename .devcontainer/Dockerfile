# Dominion OS Perfect Development Container
FROM mcr.microsoft.com/devcontainers/python:3.11-bullseye

# Install system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        vim \
        nano \
        less \
        jq \
        postgresql-client \
        redis-tools \
        lsof \
        netcat \
        htop \
        tree \
        zip \
        unzip \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Python tools globally
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir \
        black \
        isort \
        pylint \
        pytest \
        pytest-cov \
        mypy \
        flake8

# Create workspace directories
RUN mkdir -p /workspaces/dominion-os-demo-build \
    && mkdir -p /workspaces/dominion-command-center \
    && chown -R vscode:vscode /workspaces

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Set working directory
WORKDIR /workspaces/dominion-os-demo-build

# PHI environment setup
ENV PHI_MODE=development \
    PHI_SOVEREIGNTY_LEVEL=9/9 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/workspaces/dominion-os-demo-build/.venv/bin:${PATH}"

# Default user
USER vscode
