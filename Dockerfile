FROM linuxserver/ffmpeg:latest

# Universal FFmpeg build with ALL hardware encoders:
# - NVIDIA NVENC (h264_nvenc)
# - Intel QuickSync (h264_qsv via libvpl)
# - AMD/Intel VAAPI (h264_vaapi)
# - CPU (libx264)

# Install Python and dependencies (bypass PEP 668 for container)
RUN apt-get update \
 && apt-get install -y python3 python3-pip fonts-dejavu-core curl ca-certificates gnupg2 \
 && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
 && apt-get install -y nodejs \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY server.py /app/server.py

# Copy frontend sources into the image and build them so the final image
# contains both backend (Python) and frontend (Next.js) artifacts.
COPY frontend /app/frontend

# Use --break-system-packages for containerized environment (safe in Docker)
RUN pip3 install --break-system-packages --no-cache-dir fastapi uvicorn[standard] pyzmq

# Install frontend dependencies and build Next.js (production)
WORKDIR /app/frontend
# npm ci may fail on peer-dependency issues in some setups; try fallback
RUN npm ci --legacy-peer-deps || npm ci
RUN npm run build

# Return to app root
WORKDIR /app

# Environment variables with defaults
ENV BACKEND_PORT=9292
ENV FRONTEND_PORT=9393
ENV ENCODER_PREFERENCE=auto
ENV M3U_SOURCE=http://127.0.0.1:9191/output/m3u?direct=true
ENV IDLE_TIMEOUT=60

EXPOSE 9292 9393

# Clear the inherited entrypoint from linuxserver/ffmpeg
# (allows our Python command to execute directly instead of being passed to ffmpeg)
ENTRYPOINT []

# Copy startup script that launches both the frontend and backend processes
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Hardware acceleration runtime requirements:
# - NVIDIA: --gpus flag + NVIDIA Container Toolkit
# - Intel/AMD: --device /dev/dri:/dev/dri
# - CPU: No additional requirements (always available)
CMD ["/app/start.sh"]
