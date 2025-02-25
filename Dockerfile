FROM python:3.6-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install TensorFlow Serving
RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list && \
    curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add - && \
    apt-get update && apt-get install -y tensorflow-model-server && \
    rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Create required directories
RUN mkdir -p /app/Unsorted

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir "tensorflow<2" && \
    pip install --no-cache-dir captcha22

# Copy the rest of the application
COPY . .

# Expose API port
EXPOSE 5000
# Expose TensorFlow Serving ports
EXPOSE 9000 9001

# Create a startup script
RUN echo '#!/bin/bash\n\
if [ "$1" = "engine" ]; then\n\
  captcha22 server engine\n\
elif [ "$1" = "api" ]; then\n\
  captcha22 server api\n\
elif [ "$1" = "all" ]; then\n\
  captcha22 server engine & captcha22 server api\n\
elif [ "$1" = "shell" ]; then\n\
  /bin/bash\n\
else\n\
  echo "Usage: docker run [options] IMAGE [engine|api|all|shell]"\n\
  echo "  engine: Start only the CAPTCHA22 engine"\n\
  echo "  api: Start only the CAPTCHA22 API server"\n\
  echo "  all: Start both engine and API server"\n\
  echo "  shell: Start a shell inside the container"\n\
fi' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command
CMD ["all"]
