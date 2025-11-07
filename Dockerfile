# Stage 1: Frontend build
FROM node:18-slim AS frontend-builder
WORKDIR /build
COPY frontend/package*.json ./
RUN npm ci --legacy-peer-deps || npm ci
COPY frontend .
RUN npm run build

# Stage 2: Backend dependencies
FROM python:3.11-slim AS backend-builder
WORKDIR /build
COPY server.py .
RUN pip install --no-cache-dir --target ./packages fastapi uvicorn[standard] pyzmq

# Stage 3: Final runtime image
FROM linuxserver/ffmpeg:latest
WORKDIR /app

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-distutils \
    fonts-dejavu-core \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copy built artifacts from previous stages
COPY --from=frontend-builder /build/.next /app/frontend/.next
COPY --from=frontend-builder /build/node_modules /app/frontend/node_modules
COPY --from=frontend-builder /build/package*.json /app/frontend/
COPY --from=frontend-builder /build/public /app/frontend/public
COPY --from=backend-builder /build/packages /usr/local/lib/python3.11/site-packages/
COPY --from=backend-builder /build/server.py /app/

# Add startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Environment variables with defaults
ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages
ENV BACKEND_PORT=9292
ENV FRONTEND_PORT=9393
ENV ENCODER_PREFERENCE=auto
ENV M3U_SOURCE=http://127.0.0.1:9191/output/m3u?direct=true
ENV IDLE_TIMEOUT=60

EXPOSE 9292 9393

# Clear the inherited entrypoint
ENTRYPOINT []

# Hardware acceleration runtime requirements:
# - NVIDIA: --gpus flag + NVIDIA Container Toolkit
# - Intel/AMD: --device /dev/dri:/dev/dri
# - CPU: No additional requirements (always available)
CMD ["/app/start.sh"]
