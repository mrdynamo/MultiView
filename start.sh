#!/bin/bash

# Define default ports
FRONTEND_PORT="${FRONTEND_PORT:-9393}"
BACKEND_PORT="${BACKEND_PORT:-9292}"

# Change to frontend directory
cd /app/frontend || exit 1

# Start frontend
echo "[INFO] Starting frontend on port ${FRONTEND_PORT}"
export PORT="${FRONTEND_PORT}"
npm start &
FRONTEND_PID=$!

# Start backend
echo "[INFO] Starting backend on port ${BACKEND_PORT}"
cd /app || exit 1
python3 -m uvicorn server:app --host 0.0.0.0 --port "${BACKEND_PORT}" &
BACKEND_PID=$!

# Handle shutdown
cleanup() {
    echo "[INFO] Shutting down..."
    kill $FRONTEND_PID 2>/dev/null || true
    kill $BACKEND_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Wait for processes
wait $FRONTEND_PID $BACKEND_PID
