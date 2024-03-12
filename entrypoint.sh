#!/bin/sh

set -e

echo "Running generate-nginx-configs.sh script..."

if [ -f /app/scripts/generate-nginx-configs.sh ]; then
    sh /app/scripts/generate-nginx-configs.sh
else
    echo "Error: generate-nginx-configs.sh script not found!"
    exit 1
fi

echo "Starting Nginx..."

nginx -g "daemon off;"
