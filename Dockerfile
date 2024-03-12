FROM nginx:stable-alpine

LABEL maintainer="Ilia Tivin <ilia@selfhosted.club>"

ARG EMAIL

RUN apk add --no-cache certbot certbot-nginx bind-tools

# Install the Certbot DNS plugin for RFC-2136
RUN apk add --no-cache py3-pip \
    && pip3 install certbot-dns-rfc2136

# Create necessary directories
RUN mkdir -p /etc/letsencrypt \
    && mkdir -p /var/www/certbot \
    && mkdir -p /app/config \
    && mkdir -p /app/scripts \
    && mkdir -p /app/sites

# Copy the Certbot configuration file
COPY config/certbot.ini /app/config/
RUN chmod 600 /app/config/certbot.ini

# Copy the static site files
COPY sites/ /app/sites/

# Copy the scripts
COPY scripts/generate-nginx-configs.sh scripts/renew-hook.sh /app/scripts/
COPY entrypoint.sh /app/

# Make the scripts executable
RUN chmod +x /app/scripts/*.sh /app/entrypoint.sh

# Set up automatic renewal of SSL certificates
RUN echo "0 0 1 * * /usr/bin/certbot renew --quiet --deploy-hook \"/app/scripts/renew-hook.sh\"" > /etc/crontabs/root

# Expose port 80 and 443
EXPOSE 80 443

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
