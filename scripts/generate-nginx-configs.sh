#!/bin/bash

# Remove default Nginx configuration
rm -f /etc/nginx/conf.d/default.conf

# Create a directory for self-signed certificates
mkdir -p /etc/nginx/ssl

# Iterate over directories in /app/sites/
for domain_dir in /app/sites/*/; do
    domain=$(basename "$domain_dir")

    # Perform a dry run to check if the certificate can be obtained
    if certbot certonly --dry-run --non-interactive --agree-tos --email "${EMAIL}" --dns-rfc2136 --dns-rfc2136-credentials /app/config/certbot.ini -d ${domain} -d www.${domain}; then
        echo "Dry run succeeded for ${domain}. Proceeding with certificate issuance."

        # Obtain SSL certificate using Certbot with RFC-2136
        certbot certonly --non-interactive --agree-tos --email "${EMAIL}" --dns-rfc2136 --dns-rfc2136-credentials /app/config/certbot.ini --deploy-hook "/app/scripts/renew-hook.sh" -d ${domain} -d www.${domain}

        # Generate Nginx configuration file for the domain with Let's Encrypt certificates
        cat > "/etc/nginx/conf.d/${domain}.conf" <<EOL
server {
    listen 80;
    server_name ${domain} www.${domain};

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${domain} www.${domain};

    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;

    location / {
        root /app/sites/${domain};
        index index.html;
    }
}
EOL
    else
        echo "Dry run failed for ${domain}. Creating self-signed certificate."

        # Create a self-signed certificate for the domain
        openssl req -x509 -nodes -newkey rsa:2048 -days 365 -keyout /etc/nginx/ssl/${domain}.key -out /etc/nginx/ssl/${domain}.crt -subj "/CN=${domain}"

        # Generate Nginx configuration file for the domain with self-signed certificates
        cat > "/etc/nginx/conf.d/${domain}.conf" <<EOL
server {
    listen 80;
    server_name ${domain} www.${domain};

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${domain} www.${domain};

    ssl_certificate /etc/nginx/ssl/${domain}.crt;
    ssl_certificate_key /etc/nginx/ssl/${domain}.key;

    location / {
        root /app/sites/${domain};
        index index.html;
    }
}
EOL
    fi
done
