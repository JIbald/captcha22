FROM python:3.6-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install TensorFlow Serving
RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list && \
    curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add - && \
    apt-get update && apt-get install -y tensorflow-model-server && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir "tensorflow<2" captcha22

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
