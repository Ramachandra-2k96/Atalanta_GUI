# Dockerfile for Atalanta Test Pattern Generator
FROM ubuntu:22.04

# Set maintainer information
LABEL maintainer="atalanta-docker"
LABEL description="Atalanta - Automatic Test Pattern Generator for stuck-at faults in combinational circuits"
LABEL version="2.0"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Create working directories
RUN mkdir -p /opt/atalanta/src \
    && mkdir -p /opt/atalanta/bin \
    && mkdir -p /data/input \
    && mkdir -p /data/output

# Set working directory
WORKDIR /opt/atalanta/src

# Copy source code
COPY *.cpp *.h makefile /opt/atalanta/src/

# Build Atalanta
RUN make clean 2>/dev/null || true && \
    make atalanta && \
    cp atalanta /opt/atalanta/bin/ && \
    chmod +x /opt/atalanta/bin/atalanta

# Copy manual pages and documentation
COPY man/ /opt/atalanta/man/
COPY README /opt/atalanta/

# Set environment variables
ENV PATH="/opt/atalanta/bin:${PATH}"
ENV ATALANTA_MAN="/opt/atalanta"

# Create a non-root user for security
RUN useradd -m -u 1000 atalanta && \
    chown -R atalanta:atalanta /opt/atalanta /data

# Switch to non-root user
USER atalanta

# Set the default working directory to data mount point
WORKDIR /data

# Default volume mount points
VOLUME ["/data"]

# Default command - show help
CMD ["atalanta"]
