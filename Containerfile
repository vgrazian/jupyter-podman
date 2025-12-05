# Use Python 3.11 as base image
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Create a non-root user
RUN useradd -m -u 1000 jupyter && chown -R jupyter:jupyter /workspace

# Switch to non-root user
USER jupyter

# Install Jupyter and common data science packages
COPY --chown=jupyter:jupyter requirements.txt /tmp/requirements.txt
RUN pip install --user --no-cache-dir -r /tmp/requirements.txt

# Add user Python packages to PATH
ENV PATH="/home/jupyter/.local/bin:${PATH}"

# Expose Jupyter port
EXPOSE 8888

# Create notebooks directory
RUN mkdir -p /workspace/notebooks

# Copy token file into container
COPY --chown=jupyter:jupyter token.ini /tmp/token.ini

# Set default command to start Jupyter Lab with token from file
CMD ["sh", "-c", "TOKEN=$(grep '^token=' /tmp/token.ini | cut -d= -f2) && jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --ServerApp.token=\"$TOKEN\""]