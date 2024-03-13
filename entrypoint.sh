#!/bin/bash

set -e

# Generate .env file from environment variables
env | grep '^Domain' | awk -F '=' '{print $1 "=\"" substr($0, length($1)+2) "\""}' > /app/.env

echo "Generated .env file:"
cat /app/.env

echo "Running generate-nginx-configs.sh script..."

if [ -f /app/scripts/generate-nginx-configs.sh ]; then
    bash /app/scripts/generate-nginx-configs.sh
else
    echo "Error: generate-nginx-configs.sh script not found!"
    exit 1
fi

echo "Starting Nginx..."

nginx -g "daemon off;"
