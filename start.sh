#!/usr/bin/env bash
set -euo pipefail

# start.sh - simple runner to launch both Next.js frontend and FastAPI backend
# Runs frontend (npm start) in background and uvicorn in foreground. For production
# deployments a process manager or separate containers is preferable.

FRONTEND_DIR="/app/frontend"
# Allow overriding ports via env vars; defaults:
FRONTEND_PORT="${FRONTEND_PORT:-9393}"
BACKEND_PORT="${BACKEND_PORT:-9292}"

info(){ echo "[INFO] $*" }
err(){ echo "[ERROR] $*" >&2 }

cd "$FRONTEND_DIR" || { err "Frontend directory not found: $FRONTEND_DIR"; exit 1; }

info "Starting frontend (next) on port ${FRONTEND_PORT}"
# Start frontend with explicit PORT so it doesn't pick up BACKEND_PORT
PORT="${FRONTEND_PORT}" npm start &
FRONTEND_PID=$!
info "Frontend PID: ${FRONTEND_PID}"
info "Frontend PID: $FRONTEND_PID"

trap 'info "Shutting down..."; kill ${FRONTEND_PID} 2>/dev/null || true; exit 0' SIGINT SIGTERM

info "Starting backend (uvicorn) on port ${BACKEND_PORT}"
exec python3 -m uvicorn server:app --host 0.0.0.0 --port "${BACKEND_PORT}"
