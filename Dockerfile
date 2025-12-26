# Multi-stage Dockerfile for building multiple images from a single codebase
# Components: Frontend (Node.js), Backend (Python), Agents (Go)
# Each component can be built and combined in various ways
#
# This is intended to be executed by a CI/CD pipeline, which will fetch the frontend, server, agents code,
# and build the appropriate images based on user selection.

# ==========================================
# 1. BUILD STAGES
# ==========================================
FROM node:24 as frontend_builder
WORKDIR /app
COPY frontend/ .
RUN npm install

FROM python:3.14 as backend_builder
WORKDIR /app
COPY backend/ .
# Install deps, etc.
RUN python -m venv venv
RUN venv/bin/pip install -r requirements.txt

FROM python:3.14 as agents_builder
WORKDIR /app
COPY agents/ .
# Install deps, etc.
RUN python -m venv venv
RUN venv/bin/pip install -r requirements.txt

# ==========================================
# 2. OUTPUT STAGES
# ==========================================

# --- IMAGE 1: Backend Only ---
FROM python:3.14-slim as backend_only
WORKDIR /app
COPY --from=backend_builder /app /app
# Native entrypoint for just the backend
ENTRYPOINT ["/app/venv/bin/python", "main.py"]

# --- IMAGE 2: Agents Only ---
FROM python:3.14-slim as agents_only
WORKDIR /app
COPY --from=agents_builder /app /app
ENTRYPOINT ["/app/venv/bin/python", "main.py"]

# --- IMAGE 3: Frontend Only ---
FROM node:24-slim as frontend_only
WORKDIR /app
COPY --from=frontend_builder /app /app
ENTRYPOINT ["npm", "run", "dev", "--", "--host"]

# --- IMAGE 4: Backend + Agents ---
FROM python:3.14-slim as backend_agents
# Install a process manager (Supervisor is recommended for multi-process)
RUN apt-get update && apt-get install -y supervisor
COPY --from=backend_builder /app /backend
COPY --from=agents_builder /app /agents

# Create shared directory and symlinks
RUN mkdir -p /shared-data/.clogs \
    && ln -s /shared-data/.clogs /backend/.clogs \
    && ln -s /shared-data/.clogs /agents/.clogs

# Add a supervisor config to run both
COPY supervisord-backend-agents.conf /etc/supervisor/conf.d/supervisord.conf
ENTRYPOINT ["/usr/bin/supervisord"]

# --- IMAGE 5: Frontend + Backend ---
FROM python:3.14-slim as frontend_backend
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs supervisor

COPY --from=frontend_builder /app /frontend
COPY --from=backend_builder /app /backend

# Create shared directory and symlinks
RUN mkdir -p /shared-data/.clogs \
    && ln -s /shared-data/.clogs /backend/.clogs \
    && ln -s /shared-data/.clogs /frontend/.clogs

COPY supervisord-frontend-backend.conf /etc/supervisor/conf.d/supervisord.conf
ENTRYPOINT ["/usr/bin/supervisord"]

# --- IMAGE 6: Frontend + Agents ---
FROM python:3.14-slim as frontend_agents
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs supervisor

COPY --from=frontend_builder /app /frontend
COPY --from=agents_builder /app /agents

# Create shared directory and symlinks
RUN mkdir -p /shared-data/.clogs \
    && ln -s /shared-data/.clogs /agents/.clogs \
    && ln -s /shared-data/.clogs /frontend/.clogs

COPY supervisord-frontend-agents.conf /etc/supervisor/conf.d/supervisord.conf
ENTRYPOINT ["/usr/bin/supervisord"]

# --- IMAGE 7: Full Tool (Frontend + Backend + Agents) ---
FROM python:3.14-slim as full_tool
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs supervisor nginx

COPY --from=frontend_builder /app /frontend
COPY --from=backend_builder /app /backend
COPY --from=agents_builder /app /agents

# Create shared directory and symlinks
RUN mkdir -p /shared-data/.clogs \
    && ln -s /shared-data/.clogs /backend/.clogs \
    && ln -s /shared-data/.clogs /agents/.clogs \
    && ln -s /shared-data/.clogs /frontend/.clogs

# Config to run Nginx (front), Python (back), and Agents
COPY supervisord-all.conf /etc/supervisor/conf.d/supervisord.conf
ENTRYPOINT ["/usr/bin/supervisord"]
