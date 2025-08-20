# Developer container Dockerfile for php-mcp-server
# Based on the universal base image from Microsoft devcontainers
FROM mcr.microsoft.com/devcontainers/universal:2

# Install PHP 8.2, common extensions, composer, xdebug and docker client
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    apt-transport-https \
    gnupg2 \
    lsb-release \
    wget \
    curl \
    unzip \
    git \
    nano \
    php8.2 php8.2-cli php8.2-common php8.2-xml php8.2-mbstring php8.2-json php8.2-zip php8.2-curl php8.2-dev \
    php-xdebug \
    docker.io \
    || true \
    && rm -rf /var/lib/apt/lists/*

# Install Composer globally if not already present
RUN if ! command -v composer >/dev/null 2>&1; then \
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)" && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")" && \
    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer || true; \
    else \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
    rm composer-setup.php; \
    fi; \
    fi

# Ensure php is on PATH and default php validate path matches devcontainer setting
ENV PATH="/usr/local/bin:${PATH}"

# Create a non-root vscode user if not present (some base images already provide this)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} ${USERNAME} || true && \
    id -u ${USERNAME} 2>/dev/null || useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} || true

# Set workspace folder
WORKDIR /workspace

# Default to bash
CMD ["/bin/bash"]
