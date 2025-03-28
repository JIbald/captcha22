FROM tensorflow/tensorflow:1.15.5-py3

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    curl \
    build-essential \
    libsm6 \
    libxext6 \
    libxrender-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install tensorflow serving (required for hosting models)
RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list && \
    curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add - && \
    apt-get update && apt-get install -y tensorflow-model-server && \
    rm -rf /var/lib/apt/lists/*

# Set up work directory
WORKDIR /app

# Copy the CAPTCHA22 source code
COPY . /app/

# Install CAPTCHA22 and its dependencies 
# Note: TensorFlow is already installed in the base image
RUN pip install --no-cache-dir -e .

# Copy the entrypoint script
COPY deployments/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create required directories
RUN mkdir -p /data/input /data/output /data/model

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Expose ports for TF Serving and API
EXPOSE 5000 9000 9001

ENTRYPOINT ["/entrypoint.sh"]
