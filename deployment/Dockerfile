FROM python:3.6-slim

# Configure DNS to fix resolution issues
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Install system dependencies with retry mechanism for network issues
RUN apt-get update --allow-releaseinfo-change || true && \
    apt-get update -o Acquire::ForceIPv4=true || true && \
    for i in $(seq 1 3); do \
        apt-get install -y --no-install-recommends \
            wget \
            unzip \
            curl \
            gnupg \
            ca-certificates \
            apt-transport-https && break || sleep 15; \
    done && \
    rm -rf /var/lib/apt/lists/*

# Install TensorFlow Serving with retry logic
RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list && \
    for i in $(seq 1 3); do \
        curl -s https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add - && break || sleep 15; \
    done && \
    for i in $(seq 1 3); do \
        apt-get update -o Acquire::ForceIPv4=true || apt-get update && break || sleep 15; \
    done && \
    for i in $(seq 1 3); do \
        apt-get install -y tensorflow-model-server && break || sleep 15; \
    done && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies with retry mechanism
RUN pip install --upgrade pip && \
    for i in $(seq 1 3); do \
        pip install --no-cache-dir "tensorflow<2" captcha22 && break || sleep 15; \
    done

# Create directories
RUN mkdir -p /app/captchas /app/Unsorted /app/models

# Copy helper scripts
COPY prepare_captchas.py /app/
COPY run_captcha22.sh /app/

# Set working directory
WORKDIR /app

# Make scripts executable
RUN chmod +x /app/run_captcha22.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Command to run
ENTRYPOINT ["/app/run_captcha22.sh"]

