# ================================
# Stage 1: Builder
# ================================
FROM python:3.13-alpine AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    python3-dev \
    build-base \
    jpeg-dev \
    zlib-dev

# Copy requirements
COPY requirements.txt .

# Set pip environment variables to suppress all warnings
ENV PIP_ROOT_USER_ACTION=ignore \
    PIP_NO_WARN_SCRIPT_LOCATION=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH=/root/.local/bin:$PATH

# Upgrade pip first (silently), then install dependencies
RUN pip install --upgrade pip && \
    pip install --user -r requirements.txt

# ================================
# Stage 2: Runtime (Minimal)
# ================================
FROM python:3.13-alpine

WORKDIR /app

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUSERBASE=/python-deps \
    PATH=/python-deps/bin:/usr/local/bin:$PATH \
    PIP_ROOT_USER_ACTION=ignore

# Install only runtime libraries
RUN apk add --no-cache \
    bash \
    curl \
    libffi \
    openssl \
    libjpeg \
    zlib && \
    rm -rf /var/cache/apk/*

# Copy Python packages from builder
COPY --from=builder /root/.local /python-deps

# Copy application files
COPY rag_pipeline.py streamlit_ui.py ./

# Create non-root user
RUN adduser -D -u 1000 -h /app appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8501

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=2 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

CMD ["streamlit", "run", "streamlit_ui.py", "--server.port=8501", "--server.address=0.0.0.0"]