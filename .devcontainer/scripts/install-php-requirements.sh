#!/usr/bin/env bash
set -euo pipefail

# Simple install script for devcontainer to ensure PHP >=8.1, composer, and common PHP extensions
# This script is intended for Debian/Ubuntu based container images (adjust for other distros).

echo "[devcontainer] Starting install-php-requirements.sh"

# Helper: compare PHP major.minor version
php_version_ok=false
if command -v php >/dev/null 2>&1; then
  php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
  echo "[devcontainer] Found PHP $php_version"
  # Require at least 8.1
  if [ "$(printf '%s\n' "$php_version" "8.1" | sort -V | head -n1)" != "8.1" ]; then
    # php_version >= 8.1
    php_version_ok=true
  fi
fi

# If PHP not ok, try apt-get install (works for Debian/Ubuntu based images)
if [ "$php_version_ok" = false ]; then
  echo "[devcontainer] PHP 8.1+ not detected. Attempting to install PHP and common extensions (apt-get)."
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends \
      php8.2 php8.2-cli php8.2-common php8.2-xml php8.2-mbstring php8.2-json php8.2-zip php8.2-curl php8.2-dev \
      php-xdebug || true
    # re-evaluate php version presence
    if command -v php >/dev/null 2>&1; then
      php_version_ok=true
    fi
      # Try to install docker client as a fallback if the devcontainer feature isn't available
      if ! command -v docker >/dev/null 2>&1; then
        echo "[devcontainer] Docker CLI not found inside container; attempting to install docker.io via apt"
        apt-get install -y --no-install-recommends docker.io || true
      fi
  else
    echo "[devcontainer] apt-get not available; cannot auto-install PHP. Please ensure PHP >= 8.1 is installed in the image."
  fi
fi

# Composer
if ! command -v composer >/dev/null 2>&1; then
  echo "[devcontainer] Composer not found — installing composer"
  EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo 'ERROR: Invalid composer installer signature' >&2
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer || true
  else
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
  fi
else
  echo "[devcontainer] Composer found: $(composer --version)"
fi

# Ensure common PHP extensions are enabled (best-effort)
if php -m >/dev/null 2>&1; then
  for ext in mbstring json pcre; do
    if ! php -m | grep -q "^$ext$"; then
      echo "[devcontainer] Warning: PHP extension '$ext' not enabled"
    fi
  done
fi

# Install composer dependencies if composer.json exists in the workspace
if [ -f /workspaces/php-mcp-server/composer.json ] || [ -f /workspace/composer.json ]; then
  echo "[devcontainer] composer.json detected, running 'composer install'"
  # Use workspace path that the devcontainer mounts; common mount points are /workspaces/<name> or /workspace
  if [ -f /workspaces/php-mcp-server/composer.json ]; then
    cd /workspaces/php-mcp-server
  elif [ -f /workspace/composer.json ]; then
    cd /workspace
  fi
  composer install --no-interaction --no-ansi || true
fi

if command -v docker >/dev/null 2>&1; then
  echo "[devcontainer] docker CLI available inside container: $(docker --version || true)"
  if [ -e /var/run/docker.sock ]; then
    echo "[devcontainer] Docker socket mounted at /var/run/docker.sock"
  else
    echo "[devcontainer] Docker socket not mounted inside container; if you need docker-from-container, mount /var/run/docker.sock in devcontainer.json runArgs"
  fi
else
  echo "[devcontainer] docker CLI not available in the container"
fi

echo "[devcontainer] install-php-requirements.sh finished"
