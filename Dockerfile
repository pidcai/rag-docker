# Use a lightweight Python Alpine image
FROM python:3.13-alpine

# Set working directory
WORKDIR /app

# Environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install required system packages for building Python deps
# (gcc, musl-dev, libffi-dev, openssl-dev, etc.)
RUN apk add --no-cache \
    bash \
    curl \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    python3-dev \
    build-base \
    jpeg-dev \
    zlib-dev

# Copy requirements file first for layer caching
COPY requirements.txt .

# Upgrade pip and install dependencies
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy application files
COPY rag_pipeline.py .
COPY streamlit_ui.py .

# Copy .env file if present (optional)
COPY .env* ./

# Expose Streamlit default port
EXPOSE 8501

# Health check using curl
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8501/_stcore/health || exit 1

# Default command to start Streamlit
CMD ["streamlit", "run", "streamlit_ui.py", "--server.port=8501", "--server.address=0.0.0.0"]

